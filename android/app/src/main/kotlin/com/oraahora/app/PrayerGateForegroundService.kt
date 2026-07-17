package com.oraahora.app

import android.app.AppOpsManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import android.util.Log
import org.json.JSONArray
import java.util.Calendar

/**
 * Servicio en primer plano que detecta cuando el usuario abre una de las
 * apps marcadas para "Pausa y Ora" y, si corresponde, lanza
 * [PrayerGateActivity] encima.
 *
 * MIGRACION v8 (para Play Store): antes esta deteccion la hacia un
 * AccessibilityService (PrayerGateAccessibilityService.kt, ya eliminado).
 * Google Play rechaza el uso de la API de Accesibilidad para este caso de
 * uso, asi que ahora se usa la pareja de permisos estandar de las apps de
 * bienestar digital:
 *  - "Acceso de uso" (PACKAGE_USAGE_STATS): permite consultar
 *    UsageStatsManager para saber QUE app acaba de pasar a primer plano
 *    (solo el nombre del paquete; nunca el contenido de la pantalla).
 *  - "Mostrar sobre otras apps" (SYSTEM_ALERT_WINDOW): permite lanzar
 *    PrayerGateActivity encima de la app que se esta abriendo. Android
 *    exime de las restricciones de "inicio de actividades en segundo
 *    plano" a las apps con este permiso concedido por el usuario.
 *
 * El servicio consulta UsageStatsManager.queryEvents(...) cada
 * [POLL_INTERVAL_MILLIS] SOLO mientras la pantalla esta encendida (un
 * BroadcastReceiver de SCREEN_ON/SCREEN_OFF pausa el sondeo con la
 * pantalla apagada, para no gastar bateria).
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
 */
class PrayerGateForegroundService : Service() {

    companion object {
        private const val TAG = "PrayerGateService"
        private const val CHANNEL_ID = "ora_ahora_gate_active"
        private const val NOTIFICATION_ID = 4201

        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_GATE_ENABLED = "flutter.gate_enabled_flag"
        private const val KEY_GATED_APPS = "flutter.gated_apps"
        private const val KEY_GRACE_MINUTES = "flutter.gate_grace_minutes"
        private const val KEY_USAGE_PATTERN_LOG = "flutter.usage_pattern_log"
        private const val UNLOCK_KEY_PREFIX = "native_unlock_"
        private const val SNOOZE_KEY_PREFIX = "native_snooze_"

        private const val DEFAULT_GRACE_MINUTES = 20

        /** Tope de eventos guardados en el registro de patrones de uso. */
        private const val MAX_USAGE_LOG_ENTRIES = 50

        /** Cada cuanto se consulta UsageStatsManager (pantalla encendida). */
        private const val POLL_INTERVAL_MILLIS = 1_000L

        /** Ventana de eventos consultada en cada tick. Solapada a proposito
         * (mas grande que el intervalo de sondeo): [lastEventTimestamp]
         * evita procesar dos veces el mismo evento. */
        private const val QUERY_WINDOW_MILLIS = 10_000L

        // Paquetes que nunca deben disparar el gate (la propia app y UI
        // del sistema que tambien genera eventos de primer plano).
        private val IGNORED_PACKAGES = setOf(
            "com.oraahora.app",
            "com.android.systemui",
            "android",
            "com.android.launcher3",
            "com.google.android.apps.nexuslauncher",
            "com.android.settings",
        )

        /** Inicia el servicio (desde MainActivity o GateBootReceiver). */
        fun start(context: Context) {
            val intent = Intent(context, PrayerGateForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        /** Detiene el servicio (cuando se apaga "Pausa y Ora"). */
        fun stop(context: Context) {
            context.stopService(Intent(context, PrayerGateForegroundService::class.java))
        }

        /** Arranca o detiene el servicio segun el estado guardado y los
         * permisos actuales. Idempotente: se puede llamar siempre. */
        fun sync(context: Context) {
            if (shouldRun(context)) start(context) else stop(context)
        }

        /** true si "Pausa y Ora" esta encendida y ambos permisos concedidos. */
        fun shouldRun(context: Context): Boolean {
            val enabled =
                (prefs(context).getString(KEY_GATE_ENABLED, "false") ?: "false") == "true"
            return enabled && hasUsageAccess(context) && hasOverlayPermission(context)
        }

        /** Comprueba el permiso especial "Acceso de uso" (AppOpsManager). */
        fun hasUsageAccess(context: Context): Boolean {
            return try {
                val appOps =
                    context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    appOps.unsafeCheckOpNoThrow(
                        AppOpsManager.OPSTR_GET_USAGE_STATS,
                        Process.myUid(),
                        context.packageName,
                    )
                } else {
                    @Suppress("DEPRECATION")
                    appOps.checkOpNoThrow(
                        AppOpsManager.OPSTR_GET_USAGE_STATS,
                        Process.myUid(),
                        context.packageName,
                    )
                }
                if (mode == AppOpsManager.MODE_DEFAULT) {
                    // Algunos OEM devuelven MODE_DEFAULT: decide el permiso
                    // declarado en el manifest.
                    context.checkCallingOrSelfPermission(
                        android.Manifest.permission.PACKAGE_USAGE_STATS
                    ) == PackageManager.PERMISSION_GRANTED
                } else {
                    mode == AppOpsManager.MODE_ALLOWED
                }
            } catch (e: Exception) {
                Log.w(TAG, "No se pudo comprobar el Acceso de uso: ${e.message}")
                false
            }
        }

        /** Comprueba el permiso "Mostrar sobre otras apps". */
        fun hasOverlayPermission(context: Context): Boolean =
            Settings.canDrawOverlays(context)

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

    private val handler = Handler(Looper.getMainLooper())
    private var polling = false
    private var lastForegroundPackage: String? = null
    private var lastEventTimestamp = 0L
    private var screenReceiver: BroadcastReceiver? = null

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (!polling) return
            try {
                pollForegroundApp()
            } catch (e: Exception) {
                Log.w(TAG, "Error consultando eventos de uso: ${e.message}")
            }
            handler.postDelayed(this, POLL_INTERVAL_MILLIS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createChannelIfNeeded()
        registerScreenReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, buildNotification())
        // Evita procesar eventos viejos acumulados de antes de arrancar.
        lastEventTimestamp = System.currentTimeMillis()
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (powerManager.isInteractive) startPolling()
        return START_STICKY
    }

    override fun onDestroy() {
        stopPolling()
        screenReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                Log.w(TAG, "No se pudo desregistrar el receiver de pantalla: ${e.message}")
            }
        }
        screenReceiver = null
        super.onDestroy()
    }

    // ---------------------------------------------------------------------
    // Sondeo de UsageStatsManager
    // ---------------------------------------------------------------------

    private fun startPolling() {
        if (polling) return
        polling = true
        handler.post(pollRunnable)
    }

    private fun stopPolling() {
        polling = false
        handler.removeCallbacks(pollRunnable)
    }

    private fun registerScreenReceiver() {
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_SCREEN_ON -> {
                        // Ignora lo ocurrido con la pantalla apagada.
                        lastEventTimestamp = System.currentTimeMillis()
                        lastForegroundPackage = null
                        startPolling()
                    }
                    Intent.ACTION_SCREEN_OFF -> stopPolling()
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(receiver, filter)
        }
        screenReceiver = receiver
    }

    private fun pollForegroundApp() {
        val sharedPrefs = prefs(applicationContext)
        val gateEnabled =
            (sharedPrefs.getString(KEY_GATE_ENABLED, "false") ?: "false") == "true"
        if (!gateEnabled) {
            // El interruptor se apago desde Flutter: este servicio ya no
            // tiene razon de ser (ademas de stopGateService por el
            // MethodChannel, esto cubre cualquier camino que se lo salte).
            stopSelf()
            return
        }

        val usageStatsManager =
            getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val events = usageStatsManager.queryEvents(now - QUERY_WINDOW_MILLIS, now)
        val event = UsageEvents.Event()
        var newestPackage: String? = null
        var newestTime = lastEventTimestamp
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            // MOVE_TO_FOREGROUND esta deprecado desde API 29 en favor de
            // ACTIVITY_RESUMED, pero ambos comparten el mismo valor y los
            // sistemas nuevos lo siguen emitiendo; usar la constante vieja
            // mantiene compatibilidad con minSdk < 29.
            @Suppress("DEPRECATION")
            val isForeground = event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND
            if (isForeground && event.timeStamp > newestTime) {
                newestTime = event.timeStamp
                newestPackage = event.packageName
            }
        }
        if (newestPackage == null) return
        lastEventTimestamp = newestTime
        if (newestPackage == lastForegroundPackage) return
        lastForegroundPackage = newestPackage
        maybeShowGate(sharedPrefs, newestPackage)
    }

    private fun maybeShowGate(sharedPrefs: SharedPreferences, packageName: String) {
        if (IGNORED_PACKAGES.contains(packageName)) return

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

        if (!hasOverlayPermission(applicationContext)) {
            // Sin "Mostrar sobre otras apps", Android bloquearia el inicio
            // de la actividad desde este servicio en segundo plano.
            Log.w(TAG, "Falta el permiso de superposicion; no se muestra la pausa")
            return
        }

        launchPrayerGate(packageName)
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
     * por encima de [MAX_USAGE_LOG_ENTRIES].
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

    // ---------------------------------------------------------------------
    // Notificacion persistente (requisito de todo foreground service)
    // ---------------------------------------------------------------------

    private fun createChannelIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Pausa y Ora activa",
            NotificationManager.IMPORTANCE_LOW,
        )
        channel.description =
            "Notificación silenciosa que indica que la Pausa y Ora antes de abrir apps está activa."
        channel.setShowBadge(false)
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentIntent = if (openAppIntent != null) {
            PendingIntent.getActivity(
                this,
                0,
                openAppIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        } else {
            null
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        builder
            .setContentTitle("Ora Ahora")
            .setContentText("Pausa y Ora está activa, cuidando tu atención 🙏")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_SERVICE)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            builder.setPriority(Notification.PRIORITY_MIN)
        }

        if (contentIntent != null) {
            builder.setContentIntent(contentIntent)
        }

        return builder.build()
    }
}
