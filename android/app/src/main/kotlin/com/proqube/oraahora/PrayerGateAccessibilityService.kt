package com.proqube.oraahora

import android.accessibilityservice.AccessibilityService
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import org.json.JSONArray
import java.util.Calendar

/**
 * Servicio de Accesibilidad que detecta cuando el usuario abre una de las
 * apps marcadas para "Pausa y Ora" y, si corresponde, lanza
 * [PrayerGateActivity] encima.
 *
 * Contrato de SharedPreferences con el lado Flutter (ver PrefsService.dart):
 * el archivo "FlutterSharedPreferences" es el mismo que usa el plugin
 * `shared_preferences` en Android, con el prefijo "flutter." delante de
 * cada clave. Aqui SOLO leemos claves que Flutter escribe como String
 * (via `setString`), para no depender de la codificacion especial que ese
 * plugin usa para `List<String>` y `double`.
 *
 * Las claves "native_unlock_<pkg>" y "native_snooze_<pkg>" son de uso
 * exclusivo nativo (no las toca Flutter), por lo que aqui si se guardan
 * como Long usando la API estandar de Android SharedPreferences.
 *
 * "flutter.usage_pattern_log" sigue el mismo patron que "flutter.gated_apps"
 * pero en la direccion contraria: aqui es el lado NATIVO el que escribe (un
 * JSON array de timestamps epoch-millis, como String plano) y Flutter el
 * que lee (ver `UsagePatternService`/`PrefsService.usagePatternLogRaw`).
 * Al usar el mismo prefijo "flutter." y el mismo tipo (String, sin la
 * codificacion especial de List/double del plugin `shared_preferences`),
 * Flutter puede leerlo con `SharedPreferences.getString(...)` sin ningun
 * cambio adicional, exactamente como se explica en el comentario de
 * `PrefsService.dart`.
 */
class PrayerGateAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "PrayerGateA11yService"
        private const val PREFS_NAME = "FlutterSharedPreferences"

        private const val KEY_GATE_ENABLED = "flutter.gate_enabled_flag"
        private const val KEY_GATED_APPS = "flutter.gated_apps"
        private const val KEY_GRACE_MINUTES = "flutter.gate_grace_minutes"
        private const val KEY_USAGE_PATTERN_LOG = "flutter.usage_pattern_log"
        private const val UNLOCK_KEY_PREFIX = "native_unlock_"
        private const val SNOOZE_KEY_PREFIX = "native_snooze_"

        private const val DEFAULT_GRACE_MINUTES = 20

        /** Tope de eventos guardados en el registro de patrones de uso: se
         * recorta el mas antiguo al superar este limite (ver
         * [appendUsageTimestamp]), para no dejar crecer indefinidamente un
         * archivo de preferencias que se lee en cada evento de ventana. */
        private const val MAX_USAGE_LOG_ENTRIES = 50

        // Paquetes que nunca deben disparar el gate (la propia app y UI
        // del sistema que también genera eventos de ventana).
        private val IGNORED_PACKAGES = setOf(
            "com.proqube.oraahora",
            "com.android.systemui",
            "android",
            "com.android.launcher3",
        )

        /** Comprueba si este servicio esta activo segun Ajustes de Android. */
        fun isEnabled(context: Context): Boolean {
            val expected = ComponentName(context, PrayerGateAccessibilityService::class.java)
            val enabledServicesSetting = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false

            val splitter = TextUtils.SimpleStringSplitter(':')
            splitter.setString(enabledServicesSetting)
            while (splitter.hasNext()) {
                val componentName = ComponentName.unflattenFromString(splitter.next())
                if (componentName != null && componentName == expected) {
                    return true
                }
            }
            return false
        }

        /** Marca que [packageName] fue desbloqueado ahora (llamado desde PrayerGateActivity). */
        fun markUnlockedNow(context: Context, packageName: String) {
            prefs(context).edit()
                .putLong(UNLOCK_KEY_PREFIX + packageName, System.currentTimeMillis())
                .apply()
        }

        /** Marca "no volver a mostrar hoy" para [packageName]. */
        fun markSnoozedForToday(context: Context, packageName: String) {
            prefs(context).edit()
                .putLong(SNOOZE_KEY_PREFIX + packageName, endOfTodayMillis())
                .apply()
        }

        private fun prefs(context: Context): SharedPreferences =
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        private fun endOfTodayMillis(): Long {
            val cal = Calendar.getInstance()
            cal.set(Calendar.HOUR_OF_DAY, 23)
            cal.set(Calendar.MINUTE, 59)
            cal.set(Calendar.SECOND, 59)
            cal.set(Calendar.MILLISECOND, 999)
            return cal.timeInMillis
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.i(TAG, "PrayerGateAccessibilityService conectado")
        // Arranca el foreground service companero (ver
        // PrayerGateForegroundService.kt) para reducir el riesgo de que
        // fabricantes con gestion agresiva de bateria maten este servicio
        // de Accesibilidad en segundo plano.
        PrayerGateForegroundService.start(applicationContext)
    }

    override fun onUnbind(intent: Intent?): Boolean {
        // El sistema llama a onUnbind cuando el usuario desactiva este
        // servicio desde Ajustes > Accesibilidad: ya no tiene sentido
        // mantener la notificacion/foreground service activos.
        PrayerGateForegroundService.stop(applicationContext)
        return super.onUnbind(intent)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return
        if (IGNORED_PACKAGES.contains(packageName)) return

        val sharedPrefs = prefs(applicationContext)

        val gateEnabled = (sharedPrefs.getString(KEY_GATE_ENABLED, "false") ?: "false") == "true"
        if (!gateEnabled) return

        val gatedApps = readGatedApps(sharedPrefs)
        if (!gatedApps.contains(packageName)) return

        // Se registra el momento en que se detecta la apertura de una app
        // "gateada", independientemente de si la pausa de oracion termina
        // mostrandose (puede estar en el periodo de gracia o "snoozed" por
        // hoy): lo que interesa aqui es CUANDO la persona suele intentar
        // abrir estas apps, para "Recordatorio inteligente" (ver
        // UsagePatternService en el lado Flutter).
        appendUsageTimestamp(sharedPrefs)

        val snoozeUntil = sharedPrefs.getLong(SNOOZE_KEY_PREFIX + packageName, 0L)
        if (snoozeUntil > System.currentTimeMillis()) return

        val graceMinutes = readGraceMinutes(sharedPrefs)
        val lastUnlockAt = sharedPrefs.getLong(UNLOCK_KEY_PREFIX + packageName, 0L)
        val graceMillis = graceMinutes * 60_000L
        if (System.currentTimeMillis() - lastUnlockAt < graceMillis) return

        launchPrayerGate(packageName)
    }

    override fun onInterrupt() {
        // No hay recursos especiales que liberar aqui.
    }

    private fun launchPrayerGate(targetPackage: String) {
        try {
            val intent = Intent(this, PrayerGateActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                putExtra(PrayerGateActivity.EXTRA_TARGET_PACKAGE, targetPackage)
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "No se pudo abrir PrayerGateActivity para $targetPackage", e)
        }
    }

    private fun readGatedApps(sharedPrefs: SharedPreferences): Set<String> {
        val raw = sharedPrefs.getString(KEY_GATED_APPS, null) ?: return emptySet()
        return try {
            val array = JSONArray(raw)
            val result = mutableSetOf<String>()
            for (i in 0 until array.length()) {
                result.add(array.getString(i))
            }
            result
        } catch (e: Exception) {
            Log.w(TAG, "No se pudo leer gated_apps: ${e.message}")
            emptySet()
        }
    }

    private fun readGraceMinutes(sharedPrefs: SharedPreferences): Int {
        val raw = sharedPrefs.getString(KEY_GRACE_MINUTES, null) ?: return DEFAULT_GRACE_MINUTES
        return raw.toIntOrNull() ?: DEFAULT_GRACE_MINUTES
    }

    /**
     * Agrega el instante actual (epoch millis) al registro rotativo de
     * aperturas de apps "gateadas", recortando las entradas mas antiguas
     * por encima de [MAX_USAGE_LOG_ENTRIES]. Se guarda como JSON array de
     * numeros bajo [KEY_USAGE_PATTERN_LOG] (mismo archivo y prefijo
     * "flutter." que el resto de las claves compartidas con Flutter).
     */
    private fun appendUsageTimestamp(sharedPrefs: SharedPreferences) {
        try {
            val raw = sharedPrefs.getString(KEY_USAGE_PATTERN_LOG, null)
            val existing = mutableListOf<Long>()
            if (raw != null) {
                val array = JSONArray(raw)
                for (i in 0 until array.length()) {
                    existing.add(array.getLong(i))
                }
            }
            existing.add(System.currentTimeMillis())

            val trimmed = if (existing.size > MAX_USAGE_LOG_ENTRIES) {
                existing.subList(existing.size - MAX_USAGE_LOG_ENTRIES, existing.size)
            } else {
                existing
            }

            val newArray = JSONArray()
            for (timestamp in trimmed) {
                newArray.put(timestamp)
            }
            sharedPrefs.edit().putString(KEY_USAGE_PATTERN_LOG, newArray.toString()).apply()
        } catch (e: Exception) {
            Log.w(TAG, "No se pudo actualizar el registro de patrones de uso: ${e.message}")
        }
    }
}
