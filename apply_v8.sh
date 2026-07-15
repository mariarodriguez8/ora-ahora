#!/usr/bin/env bash
# =====================================================================
# apply_v8.sh — ORA AHORA v8: migración de "Pausa y Ora" para Play Store
# Accesibilidad → "Acceso de uso" (UsageStatsManager) + overlay
# (SYSTEM_ALERT_WINDOW). Autocontenido e idempotente: escribe archivos
# COMPLETOS; se puede correr varias veces sin problema.
# Uso: bash apply_v8.sh   (desde la raíz del repo ora-ahora)
# =====================================================================
set -euo pipefail

test -f pubspec.yaml || { echo "ERROR: corre este script desde la raíz del repo (donde está pubspec.yaml)"; exit 1; }

echo "== v8: eliminando el servicio de Accesibilidad =="
rm -f android/app/src/main/kotlin/com/proqube/oraahora/PrayerGateAccessibilityService.kt
rm -f android/app/src/main/res/xml/accessibility_service_config.xml
rmdir android/app/src/main/res/xml 2>/dev/null || true

echo "== v8: escribiendo archivos =="

mkdir -p "$(dirname 'android/app/src/main/AndroidManifest.xml')"
cat > 'android/app/src/main/AndroidManifest.xml' <<'EOF_ORA_V8_0'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Notificaciones locales (recordatorios de oración). -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <!-- Deteccion opcional (opt-in, apagada por defecto) de fin de oracion
         por voz en PrayerDetailScreen (ver VoicePrayerService, paquete
         speech_to_text). El microfono SOLO se activa mientras esa pantalla
         esta abierta y la persona toca "Escuchar mi oración"; el
         reconocimiento se pide siempre con onDevice=true (100% local, ver
         PLAY_STORE_LISTING.md), nunca se envia audio a un servidor. -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />

    <!-- Permite reprogramar recordatorios ya guardados tras un reinicio,
         usado internamente por flutter_local_notifications. -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"
        tools:node="remove" />

    <!-- "Pausa y Ora" (v8, apto para Play Store): en lugar del servicio de
         Accesibilidad (que Google rechaza para este caso de uso), se usa la
         pareja estandar de las apps de bienestar digital:
         - "Acceso de uso" (PACKAGE_USAGE_STATS): permiso especial que la
           persona concede manualmente en Ajustes; permite saber QUE app
           acaba de pasar a primer plano (solo el nombre del paquete).
         - "Mostrar sobre otras apps" (SYSTEM_ALERT_WINDOW): permite mostrar
           la pausa de oración encima de la app que se esta abriendo.
         Ver PrayerGateForegroundService.kt. -->
    <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
        tools:ignore="ProtectedPermissions" />
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />

    <!-- Foreground service detector de "Pausa y Ora"
         (PrayerGateForegroundService.kt). "specialUse" es la categoria
         generica introducida en Android 14 (API 34) para casos de uso que
         no encajan en las categorias especificas existentes. -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />

    <!-- Permite pedirle al usuario que excluya a Ora Ahora de la
         optimizacion de bateria de Android, para que "Pausa y Ora" no sea
         silenciada por el sistema (ver Ajustes > Optimización de batería,
         BatteryOptimizationScreen.dart). -->
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />

    <!-- Necesario en Android 11+ (API 30+) para que device_apps pueda listar
         apps instaladas con icono de lanzador, SIN pedir el permiso amplio
         QUERY_ALL_PACKAGES (que Play Store escrutina mucho más). -->
    <queries>
        <intent>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent>
    </queries>

    <application
        android:label="@string/app_name"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher"
        android:allowBackup="true"
        android:supportsRtl="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- Pantalla nativa (100% Kotlin + XML) de la pausa de oración.
             Ver PrayerGateActivity.kt para la justificacion de por que se
             eligio una Activity nativa en vez de un segundo FlutterEngine. -->
        <activity
            android:name=".PrayerGateActivity"
            android:exported="false"
            android:theme="@style/PrayerGateTheme"
            android:launchMode="singleTask"
            android:excludeFromRecents="true"
            android:taskAffinity=""
            android:configChanges="orientation|screenSize|keyboardHidden" />

        <!-- Servicio detector de "Pausa y Ora" (v8): consulta
             UsageStatsManager mientras la pantalla esta encendida y lanza
             PrayerGateActivity cuando se abre una app elegida. -->
        <service
            android:name=".PrayerGateForegroundService"
            android:exported="false"
            android:foregroundServiceType="specialUse">
            <property
                android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                android:value="Detectar la apertura de apps elegidas por la persona para proponer una pausa de oración (bienestar digital)" />
        </service>

        <!-- Rearranca el servicio detector tras reinicio o actualizacion
             (solo si "Pausa y Ora" estaba encendida y con permisos). -->
        <receiver
            android:name=".GateBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
            </intent-filter>
        </receiver>

        <!-- Requerido por flutter_local_notifications para volver a
             programar los recordatorios pendientes despues de un reinicio
             del telefono. -->
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.actions.NotificationActionReceiver" />

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>

</manifest>
EOF_ORA_V8_0

mkdir -p "$(dirname 'android/app/src/main/res/values/strings.xml')"
cat > 'android/app/src/main/res/values/strings.xml' <<'EOF_ORA_V8_1'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Ora Ahora</string>

    <string name="notification_channel_name">Recordatorios de oración</string>
</resources>
EOF_ORA_V8_1

mkdir -p "$(dirname 'android/app/src/main/kotlin/com/proqube/oraahora/MainActivity.kt')"
cat > 'android/app/src/main/kotlin/com/proqube/oraahora/MainActivity.kt' <<'EOF_ORA_V8_2'
package com.proqube.oraahora

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Activity principal de Flutter. Ademas de arrancar el motor de Flutter,
 * expone un MethodChannel ("com.proqube.oraahora/gate") con operaciones
 * puntuales que si requieren codigo nativo:
 * - abrir las pantallas de Ajustes de Android para los dos permisos de
 *   "Pausa y Ora": "Acceso de uso" y "Mostrar sobre otras apps".
 * - comprobar si esos permisos estan concedidos.
 * - arrancar/detener/sincronizar el servicio detector
 *   (PrayerGateForegroundService).
 * - pedir (o comprobar) la exclusion de Ora Ahora de la optimizacion de
 *   bateria de Android.
 *
 * El resto del estado de "Pausa y Ora" (apps bloqueadas, interruptor
 * general, minutos de gracia) se comparte con el servicio detector a
 * traves de SharedPreferences (ver PrefsService.dart y
 * PrayerGateForegroundService.kt), sin necesidad de MethodChannel.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.proqube.oraahora/gate"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openUsageAccessSettings" -> {
                        try {
                            openUsageAccessSettings()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OPEN_SETTINGS_FAILED", e.message, null)
                        }
                    }
                    "openOverlaySettings" -> {
                        try {
                            openOverlaySettings()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OPEN_SETTINGS_FAILED", e.message, null)
                        }
                    }
                    "hasUsageAccess" -> {
                        result.success(
                            PrayerGateForegroundService.hasUsageAccess(applicationContext)
                        )
                    }
                    "hasOverlayPermission" -> {
                        result.success(
                            PrayerGateForegroundService.hasOverlayPermission(applicationContext)
                        )
                    }
                    "syncGateService" -> {
                        try {
                            PrayerGateForegroundService.sync(applicationContext)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SYNC_GATE_FAILED", e.message, null)
                        }
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        try {
                            result.success(isIgnoringBatteryOptimizations())
                        } catch (e: Exception) {
                            result.error("BATTERY_OPT_CHECK_FAILED", e.message, null)
                        }
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        try {
                            if (!isIgnoringBatteryOptimizations()) {
                                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                                intent.data = Uri.parse("package:$packageName")
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                            }
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("BATTERY_OPT_REQUEST_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        // Cada vez que la persona vuelve a la app, se reconcilia el estado
        // del servicio detector con el interruptor y los permisos actuales
        // (p. ej. si acaba de conceder los permisos en Ajustes, el servicio
        // arranca aqui sin esperar a que Flutter lo pida).
        try {
            PrayerGateForegroundService.sync(applicationContext)
        } catch (e: Exception) {
            // Nunca debe impedir volver a la app.
        }
    }

    /**
     * Abre Ajustes > Acceso de uso. Se intenta primero la variante que
     * llega directo a la pantalla de Ora Ahora (soportada en Android 10+
     * de stock y varios OEM); si el dispositivo no la soporta, se abre la
     * lista general.
     */
    private fun openUsageAccessSettings() {
        val direct = Intent(
            Settings.ACTION_USAGE_ACCESS_SETTINGS,
            Uri.parse("package:$packageName"),
        )
        direct.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            startActivity(direct)
        } catch (e: Exception) {
            val general = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            general.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(general)
        }
    }

    /** Abre Ajustes > Mostrar sobre otras apps para Ora Ahora. */
    private fun openOverlaySettings() {
        val direct = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:$packageName"),
        )
        direct.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            startActivity(direct)
        } catch (e: Exception) {
            val general = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
            general.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(general)
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }
}
EOF_ORA_V8_2

mkdir -p "$(dirname 'android/app/src/main/kotlin/com/proqube/oraahora/PrayerGateForegroundService.kt')"
cat > 'android/app/src/main/kotlin/com/proqube/oraahora/PrayerGateForegroundService.kt' <<'EOF_ORA_V8_3'
package com.proqube.oraahora

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
            "com.proqube.oraahora",
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
            NotificationManager.IMPORTANCE_MIN,
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
EOF_ORA_V8_3

mkdir -p "$(dirname 'android/app/src/main/kotlin/com/proqube/oraahora/GateBootReceiver.kt')"
cat > 'android/app/src/main/kotlin/com/proqube/oraahora/GateBootReceiver.kt' <<'EOF_ORA_V8_4'
package com.proqube.oraahora

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Reinicia el servicio de "Pausa y Ora" tras un reinicio del telefono o
 * una actualizacion de la app, si el interruptor estaba encendido y los
 * dos permisos (Acceso de uso + Mostrar sobre otras apps) siguen
 * concedidos. Iniciar un foreground service desde BOOT_COMPLETED /
 * MY_PACKAGE_REPLACED esta dentro de las exenciones oficiales de Android.
 */
class GateBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        if (PrayerGateForegroundService.shouldRun(context)) {
            PrayerGateForegroundService.start(context)
        }
    }
}
EOF_ORA_V8_4

mkdir -p "$(dirname 'android/app/src/main/kotlin/com/proqube/oraahora/PrayerGateActivity.kt')"
cat > 'android/app/src/main/kotlin/com/proqube/oraahora/PrayerGateActivity.kt' <<'EOF_ORA_V8_5'
package com.proqube.oraahora

import android.animation.ObjectAnimator
import android.animation.PropertyValuesHolder
import android.animation.ValueAnimator
import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.CountDownTimer
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import org.json.JSONArray
import org.json.JSONObject
import kotlin.random.Random

/**
 * Pantalla nativa (100% Kotlin + layout XML, sin un segundo motor de
 * Flutter) que se muestra encima de una app "gateada" cuando el usuario
 * intenta abrirla.
 *
 * DECISION DE DISEÑO / TRADEOFF (ver tambien el informe final):
 * Se eligio una Activity puramente nativa en lugar de hospedar un
 * `FlutterFragment`/segundo `FlutterEngine` porque:
 *  - Arrancar un motor de Flutter adicional añade latencia perceptible
 *    justo en el momento en que el usuario espera abrir otra app (mala
 *    experiencia para una interrupcion que debe sentirse instantanea).
 *  - Evita la complejidad y el consumo de memoria de mantener un
 *    `FlutterEngineCache` vivo en segundo plano solo para esta pantalla.
 *  - Al no poder compilar/probar en este entorno, una Activity nativa
 *    simple es mas facil de verificar por lectura cuidadosa que la
 *    integracion de un segundo engine de Flutter.
 * La desventaja es duplicar un poco de UI (esta pantalla no comparte
 * widgets con el resto de la app Flutter), pero se mantiene el mismo
 * catalogo de datos: este archivo lee el mismo
 * `assets/data/prayers_es.json` que usa Flutter, directamente desde los
 * assets empaquetados de Flutter dentro del APK
 * ("flutter_assets/assets/data/prayers_es.json").
 *
 * CHECK-IN DE ANIMO (mood check-in): antes de mostrar la oracion, esta
 * pantalla ahora pregunta brevemente como se siente la persona (6 opciones
 * en espanol) y elige una oracion de la categoria mas relevante para ese
 * animo. Es una personalizacion real (no una mecanica de manipulacion): si
 * no se elige nada en unos segundos, o si se toca "Solo muéstrame algo", se
 * usa el mismo comportamiento por defecto que existia antes (una oracion
 * aleatoria de la categoria "tentacion_enfoque", ya que esta pantalla se
 * muestra para apps que distraen).
 */
class PrayerGateActivity : Activity() {

    companion object {
        private const val TAG = "PrayerGateActivity"
        const val EXTRA_TARGET_PACKAGE = "extra_target_package"

        private const val MIN_DWELL_MILLIS = 10_000L
        private const val TICK_MILLIS = 1_000L
        private const val CATEGORY_TENTACION_ENFOQUE = "tentacion_enfoque"
        private const val FLUTTER_ASSET_PATH = "flutter_assets/assets/data/prayers_es.json"

        /** Categorias por defecto (sin animo elegido): igual que antes. */
        private val DEFAULT_CATEGORIES = listOf(CATEGORY_TENTACION_ENFOQUE)

        /** Cuanto se espera antes de usar el comportamiento por defecto si
         * la persona no elige ningun animo. Corto a propósito: la pausa ya
         * es una interrupcion, no se le debe sumar una espera larga solo
         * para decidir si participa del check-in. */
        private const val MOOD_AUTO_SKIP_MILLIS = 6_000L

        // Respaldo por si el asset no se puede leer (no deberia ocurrir en
        // una build normal, pero evita dejar la pantalla vacia).
        private val FALLBACK_PRAYERS = listOf(
            Triple(
                "Antes de abrir esta app",
                "Señor, antes de perder minutos sin darme cuenta, ayúdame a " +
                    "decidir con libertad si de verdad quiero entrar ahora. " +
                    "Dame dominio propio para usar mi tiempo de forma que " +
                    "después no me arrepienta. Amén.",
                "cf. Gálatas 5:22-23"
            ),
            Triple(
                "Recupera tu atención",
                "Dios, mi atención es valiosa. Ayúdame a decidir cuándo y " +
                    "cómo uso esta app, en lugar de que ella decida por mí. " +
                    "Guía este momento. Amén.",
                "cf. Romanos 12:2"
            ),
        )
    }

    private lateinit var moodContainer: View
    private lateinit var prayerContentContainer: View
    private lateinit var textPrayerTitle: TextView
    private lateinit var textPrayerBody: TextView
    private lateinit var textPrayerRef: TextView
    private lateinit var buttonContinue: Button
    private lateinit var textBreathingCue: TextView
    private lateinit var breathingCircle: View
    private var targetPackage: String? = null
    private var dwellFinished = false
    private var moodResolved = false
    private var breathingAnimator: ValueAnimator? = null
    private val handler = Handler(Looper.getMainLooper())
    private var breathingToggleRunnable: Runnable? = null
    private var moodAutoSkipRunnable: Runnable? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_prayer_gate)

        targetPackage = intent.getStringExtra(EXTRA_TARGET_PACKAGE)

        val textTargetApp = findViewById<TextView>(R.id.textTargetApp)
        moodContainer = findViewById(R.id.moodContainer)
        prayerContentContainer = findViewById(R.id.prayerContentContainer)
        textPrayerTitle = findViewById(R.id.textPrayerTitle)
        textPrayerBody = findViewById(R.id.textPrayerBody)
        textPrayerRef = findViewById(R.id.textPrayerRef)
        val buttonSnooze = findViewById<TextView>(R.id.buttonSnooze)
        val buttonMoodSkip = findViewById<TextView>(R.id.buttonMoodSkip)
        buttonContinue = findViewById(R.id.buttonContinue)
        textBreathingCue = findViewById(R.id.textBreathingCue)
        breathingCircle = findViewById(R.id.breathingCircle)

        textTargetApp.text = "Pausa antes de abrir " + appLabelFor(targetPackage)

        setupMoodButton(R.id.buttonMoodAnsioso, listOf("ansiedad"))
        setupMoodButton(R.id.buttonMoodAgradecido, listOf("gratitud"))
        setupMoodButton(R.id.buttonMoodCansado, listOf("sanidad"))
        setupMoodButton(R.id.buttonMoodTriste, listOf("duelo", "perdon"))
        setupMoodButton(R.id.buttonMoodDistraido, listOf(CATEGORY_TENTACION_ENFOQUE))
        setupMoodButton(R.id.buttonMoodPaz, listOf("gratitud"))

        buttonMoodSkip.setOnClickListener { resolveMood(DEFAULT_CATEGORIES) }

        val autoSkip = Runnable { resolveMood(DEFAULT_CATEGORIES) }
        moodAutoSkipRunnable = autoSkip
        handler.postDelayed(autoSkip, MOOD_AUTO_SKIP_MILLIS)

        buttonContinue.setOnClickListener {
            if (!dwellFinished) return@setOnClickListener
            targetPackage?.let { PrayerGateForegroundService.markUnlockedNow(this, it) }
            continueToTargetApp()
        }

        buttonSnooze.setOnClickListener {
            targetPackage?.let { PrayerGateForegroundService.markSnoozedForToday(this, it) }
            continueToTargetApp()
        }
    }

    private fun setupMoodButton(viewId: Int, categories: List<String>) {
        findViewById<Button>(viewId).setOnClickListener { resolveMood(categories) }
    }

    /** Se llama una sola vez: por un toque de animo, el boton de saltar, o
     * el temporizador de auto-salto. Cualquier via posterior se ignora. */
    private fun resolveMood(categories: List<String>) {
        if (moodResolved) return
        moodResolved = true

        moodAutoSkipRunnable?.let { handler.removeCallbacks(it) }
        moodAutoSkipRunnable = null

        moodContainer.visibility = View.GONE
        prayerContentContainer.visibility = View.VISIBLE

        val (titulo, texto, referencia) = loadRandomPrayer(categories)
        textPrayerTitle.text = titulo
        textPrayerBody.text = texto
        textPrayerRef.text = referencia

        startBreathingAnimation()
        startDwellTimer()
    }

    private fun appLabelFor(packageName: String?): String {
        if (packageName == null) return "esta app"
        return try {
            val info = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(info).toString()
        } catch (e: Exception) {
            packageName
        }
    }

    /**
     * Elige una oracion al azar de la primera categoria en [categories] que
     * tenga al menos una coincidencia en el catalogo (asi "Triste" puede
     * intentar primero "duelo" y usar "perdon" como respaldo, por ejemplo).
     * Si ninguna categoria tiene coincidencias, o el asset no se puede leer,
     * usa [FALLBACK_PRAYERS].
     */
    private fun loadRandomPrayer(categories: List<String>): Triple<String, String, String> {
        try {
            assets.open(FLUTTER_ASSET_PATH).use { input ->
                val json = input.bufferedReader(Charsets.UTF_8).readText()
                val array = JSONArray(json)
                val byCategory = mutableMapOf<String, MutableList<JSONObject>>()
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    val categoria = obj.optString("categoria")
                    byCategory.getOrPut(categoria) { mutableListOf() }.add(obj)
                }
                for (categoria in categories) {
                    val matches = byCategory[categoria]
                    if (!matches.isNullOrEmpty()) {
                        val chosen = matches[Random.nextInt(matches.size)]
                        return Triple(
                            chosen.getString("titulo"),
                            chosen.getString("texto"),
                            chosen.getString("referencia_biblica"),
                        )
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "No se pudo leer prayers_es.json, usando respaldo local: ${e.message}")
        }
        val fallback = FALLBACK_PRAYERS[Random.nextInt(FALLBACK_PRAYERS.size)]
        return fallback
    }

    private fun startBreathingAnimation() {
        val scaleUp = PropertyValuesHolder.ofFloat(View.SCALE_X, 1f, 1.3f)
        val scaleUpY = PropertyValuesHolder.ofFloat(View.SCALE_Y, 1f, 1.3f)
        val animator = ObjectAnimator.ofPropertyValuesHolder(breathingCircle, scaleUp, scaleUpY)
        animator.duration = 4000
        animator.repeatMode = ValueAnimator.REVERSE
        animator.repeatCount = ValueAnimator.INFINITE
        animator.start()
        breathingAnimator = animator

        var inhaling = true
        textBreathingCue.text = "Inhala..."
        val toggle = object : Runnable {
            override fun run() {
                inhaling = !inhaling
                textBreathingCue.text = if (inhaling) "Inhala..." else "Exhala..."
                handler.postDelayed(this, 4000)
            }
        }
        breathingToggleRunnable = toggle
        handler.postDelayed(toggle, 4000)
    }

    private fun startDwellTimer() {
        buttonContinue.isEnabled = false
        object : CountDownTimer(MIN_DWELL_MILLIS, TICK_MILLIS) {
            override fun onTick(millisUntilFinished: Long) {
                val seconds = (millisUntilFinished / 1000L) + 1
                buttonContinue.text = "Espera ${seconds}s..."
            }

            override fun onFinish() {
                dwellFinished = true
                buttonContinue.isEnabled = true
                buttonContinue.text = "Continuar a la app"
            }
        }.start()
    }

    private fun continueToTargetApp() {
        val pkg = targetPackage
        if (pkg == null) {
            finish()
            return
        }
        val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launchIntent)
        } else {
            Toast.makeText(this, "No se pudo abrir la app", Toast.LENGTH_SHORT).show()
        }
        finish()
    }

    override fun onBackPressed() {
        if (!moodResolved) {
            // Todavia en el check-in de animo: tratar "atras" como la
            // opcion de saltar, en vez de bloquear (aqui no hay una espera
            // minima que proteger todavia).
            resolveMood(DEFAULT_CATEGORIES)
            return
        }
        if (!dwellFinished) {
            Toast.makeText(this, "Espera unos segundos antes de continuar", Toast.LENGTH_SHORT).show()
            return
        }
        super.onBackPressed()
    }

    override fun onDestroy() {
        super.onDestroy()
        breathingAnimator?.cancel()
        breathingToggleRunnable?.let { handler.removeCallbacks(it) }
        moodAutoSkipRunnable?.let { handler.removeCallbacks(it) }
    }
}
EOF_ORA_V8_5

mkdir -p "$(dirname 'lib/services/gate_service.dart')"
cat > 'lib/services/gate_service.dart' <<'EOF_ORA_V8_6'
import 'package:device_apps/device_apps.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'prefs_service.dart';

/// Puente entre Flutter y el lado nativo Android para la funcion
/// "Pausa y Ora".
///
/// v8 (apto para Play Store): la deteccion de apps ya NO usa el servicio de
/// Accesibilidad (Google lo rechaza para este caso de uso) sino la pareja
/// estandar de las apps de bienestar digital:
///  - "Acceso de uso" (PACKAGE_USAGE_STATS): saber que app pasa a primer
///    plano (solo el nombre del paquete).
///  - "Mostrar sobre otras apps" (SYSTEM_ALERT_WINDOW): poner la pausa de
///    oracion encima de la app que se esta abriendo.
/// Ambos permisos se conceden manualmente en Ajustes de Android; este
/// servicio abre las pantallas correctas y comprueba su estado.
///
/// La lista de apps bloqueadas y las preferencias del gate se guardan con
/// `PrefsService` (SharedPreferences), que es el mismo archivo que lee
/// `PrayerGateForegroundService.kt` de forma nativa. El `MethodChannel`
/// solo se usa para operaciones que si requieren codigo nativo puntual
/// (abrir Ajustes, comprobar permisos, sincronizar el servicio detector).
class GateService extends ChangeNotifier {
  static const _channel = MethodChannel('com.proqube.oraahora/gate');

  final PrefsService _prefs;

  GateService(this._prefs);

  List<String> get gatedApps => _prefs.gatedApps;

  bool get gateEnabled => _prefs.gateEnabled;

  int get graceMinutes => _prefs.gateGraceMinutes;

  Future<void> setGateEnabled(bool value) async {
    await _prefs.setGateEnabled(value);
    // Arranca o detiene el servicio detector nativo segun el nuevo estado
    // (y los permisos actuales). Nunca debe bloquear el interruptor.
    await syncNativeService();
    notifyListeners();
  }

  Future<void> setGraceMinutes(int minutes) async {
    await _prefs.setGateGraceMinutes(minutes);
    notifyListeners();
  }

  bool isGated(String packageName) => gatedApps.contains(packageName);

  Future<void> addGatedApp(String packageName) async {
    final current = List<String>.from(gatedApps);
    if (!current.contains(packageName)) {
      current.add(packageName);
      await _prefs.setGatedApps(current);
      notifyListeners();
    }
  }

  Future<void> removeGatedApp(String packageName) async {
    final current = List<String>.from(gatedApps);
    current.remove(packageName);
    await _prefs.setGatedApps(current);
    notifyListeners();
  }

  Future<void> toggleGatedApp(String packageName, {required int maxApps}) async {
    if (isGated(packageName)) {
      await removeGatedApp(packageName);
      return;
    }
    if (gatedApps.length >= maxApps) {
      return; // el limite se comunica en la UI antes de llegar aqui
    }
    await addGatedApp(packageName);
  }

  /// Lista las apps instaladas con icono de lanzamiento (excluye apps de
  /// sistema sin interfaz), ordenadas alfabeticamente. Usa el paquete
  /// `device_apps`.
  Future<List<Application>> installedLaunchableApps() async {
    final apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );
    apps.sort((a, b) =>
        a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
    return apps;
  }

  /// Abre Ajustes > Acceso de uso de Android (en muchos telefonos llega
  /// directo a la fila de Ora Ahora).
  Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } on PlatformException {
      // Si falla (dispositivo no estandar), no bloqueamos el flujo de la
      // app; el usuario puede navegar manualmente.
    }
  }

  /// Abre Ajustes > Mostrar sobre otras apps para Ora Ahora.
  Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } on PlatformException {
      // Igual que arriba: nunca bloquear el flujo.
    }
  }

  /// Comprueba el permiso especial "Acceso de uso" (AppOpsManager,
  /// OPSTR_GET_USAGE_STATS).
  Future<bool> hasUsageAccess() async {
    try {
      final granted = await _channel.invokeMethod<bool>('hasUsageAccess');
      return granted ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Comprueba el permiso "Mostrar sobre otras apps"
  /// (Settings.canDrawOverlays).
  Future<bool> hasOverlayPermission() async {
    try {
      final granted =
          await _channel.invokeMethod<bool>('hasOverlayPermission');
      return granted ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// true solo si AMBOS permisos de "Pausa y Ora" estan concedidos.
  Future<bool> hasAllGatePermissions() async {
    final usage = await hasUsageAccess();
    if (!usage) return false;
    return hasOverlayPermission();
  }

  /// Pide al lado nativo arrancar o detener el servicio detector segun el
  /// interruptor y los permisos actuales. Idempotente.
  Future<void> syncNativeService() async {
    try {
      await _channel.invokeMethod('syncGateService');
    } on PlatformException {
      // El servicio tambien se reconcilia solo en MainActivity.onResume.
    }
  }

  /// Comprueba si Android ya excluyo a Ora Ahora de la optimizacion de
  /// bateria (`PowerManager.isIgnoringBatteryOptimizations`). Si es
  /// `false`, "Pausa y Ora" corre el riesgo de ser silenciada por el
  /// sistema en fabricantes con gestion agresiva de bateria.
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final ignoring =
          await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return ignoring ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Abre el dialogo nativo de Android para pedirle al usuario que excluya
  /// a Ora Ahora de la optimizacion de bateria
  /// (`Intent.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`). No hace nada
  /// si ya esta excluida.
  Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } on PlatformException {
      // Si falla, el usuario puede hacerlo manualmente desde los ajustes
      // de bateria de su telefono; no bloqueamos el flujo de la app.
    }
  }
}
EOF_ORA_V8_6

mkdir -p "$(dirname 'lib/services/prefs_service.dart')"
cat > 'lib/services/prefs_service.dart' <<'EOF_ORA_V8_7'
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Punto unico de acceso a `SharedPreferences` y catalogo central de claves.
///
/// IMPORTANTE (contrato con el codigo nativo Kotlin):
/// El plugin `shared_preferences` en Android guarda todas las claves en el
/// archivo `FlutterSharedPreferences` con el prefijo `flutter.` delante de
/// cada clave (p. ej. la clave Dart `gated_apps` se guarda como
/// `flutter.gated_apps`). `PrayerGateForegroundService.kt` y
/// `PrayerGateActivity.kt` leen ese mismo archivo directamente para saber
/// que apps debe bloquear.
///
/// Para evitar la codificacion especial que usa el plugin para `List<String>`
/// y `double` (usa un prefijo mágico en Base64 para esos dos tipos), aqui
/// SOLO usamos `setString` (texto plano UTF-8, sin transformar) para los
/// valores que el lado nativo necesita leer, y `setBool` para banderas
/// (los booleanos SI se guardan de forma nativa con `putBoolean`, por lo
/// que son seguros de leer con `getBoolean` desde Kotlin). Los enteros que
/// necesita leer Kotlin se guardan tambien como `String` para evitar
/// depender de si el plugin los serializa como Int o como Long.
class PrefsKeys {
  // --- Onboarding / perfil ---
  static const onboardingComplete = 'onboarding_complete';
  static const preferredCategories = 'preferred_categories'; // String JSON
  static const morningTime = 'morning_time'; // "HH:mm"
  static const nightTime = 'night_time'; // "HH:mm"

  // --- Racha ---
  static const streakState = 'streak_state'; // String JSON

  // --- Recordatorios ---
  static const reminderTimes = 'reminder_times'; // String JSON List<"HH:mm">
  static const notificationsEnabled = 'notifications_enabled';

  // --- Compras / Plus ---
  static const isPlusUser = 'is_plus_user';

  // --- Paywall ---
  /// Se pone en `true` la primera vez que se muestra el paywall justo
  /// despues de terminar el onboarding (el momento "aha" del usuario), asi
  /// no se vuelve a mostrar automaticamente en cada apertura de la app.
  static const paywallShownAfterOnboarding = 'paywall_shown_after_onboarding';

  // --- Apariencia (paletas de color y accesibilidad) ---
  /// Id (nombre del enum `AppPaletteId`) de la paleta elegida a mano por
  /// el usuario en Ajustes > Apariencia. Si es `null`/vacio, se usa el
  /// mapeo por defecto segun el modo claro/oscuro del sistema (ver
  /// `AppearanceService.resolveForBrightness`).
  static const selectedPaletteId = 'selected_palette_id';

  /// "Modo Simple": aumenta el tamaño de fuente y el tamaño de los botones
  /// principales (~65dp) para usuarios mayores o con baja vision.
  static const simpleModeEnabled = 'simple_mode_enabled';

  // --- Pausa y Ora (leido tambien por Kotlin) ---
  /// String con JSON array de package names, ej: ["com.instagram.android"]
  static const gatedApps = 'gated_apps';

  /// "true"/"false" como String (no bool) para lectura nativa sin ambiguedad.
  static const gateEnabledFlag = 'gate_enabled_flag';

  /// Minutos de gracia antes de volver a mostrar la pausa para la misma app,
  /// guardado como String (ej. "20") para que Kotlin haga Integer.parseInt.
  static const gateGraceMinutes = 'gate_grace_minutes';

  /// (v8) La clave conserva su nombre historico ("accessibility_...") para
  /// no perder el estado de usuarios que ya vieron el explainer, pero desde
  /// v8 marca haber visto la pantalla de los DOS permisos de Pausa y Ora
  /// (Acceso de uso + Mostrar sobre otras apps).
  static const accessibilityExplainerSeen = 'accessibility_explainer_seen';

  // --- Patrones de uso / Recordatorio inteligente ---
  /// String con JSON array de timestamps (epoch millis), escrito por
  /// `PrayerGateForegroundService.kt` (lado nativo) cada vez que detecta
  /// la apertura de una app "gateada". Flutter SOLO lee esta clave (ver
  /// `UsagePatternService`); nunca la escribe.
  static const usagePatternLog = 'usage_pattern_log';

  /// Interruptor (opt-in, apagado por defecto) del recordatorio adicional
  /// basado en el horario habitual de apertura de apps "gateadas".
  static const smartReminderEnabled = 'smart_reminder_enabled';

  // --- Deteccion de oracion por voz (on-device, opt-in) ---
  /// Interruptor (apagado por defecto) de la deteccion automatica de fin
  /// de oracion usando el microfono y reconocimiento de voz 100% en el
  /// dispositivo (paquete `speech_to_text`). Ver `VoicePrayerService` y
  /// `PrayerDetailScreen`. Nunca se usa para nada mas que decidir si se
  /// muestra el boton "Escuchar mi oración".
  static const voiceDetectionEnabled = 'voice_detection_enabled';
  static const userName = 'user_name';
  static const micPrimingDone = 'mic_priming_done_v2';

  /// `true` una vez que la persona vio la pantalla de aviso previo
  /// (`VoiceExplainerScreen`) y concedio el permiso de microfono, para no
  /// volver a mostrar esa pantalla cada vez que reactive el interruptor.
  static const voiceDisclosureSeen = 'voice_disclosure_seen';
}

class PrefsService {
  final SharedPreferences _prefs;

  PrefsService(this._prefs);

  static Future<PrefsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefsService(prefs);
  }

  // --- Onboarding ---
  bool get onboardingComplete =>
      _prefs.getBool(PrefsKeys.onboardingComplete) ?? false;

  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool(PrefsKeys.onboardingComplete, value);

  List<String> get preferredCategories {
    final raw = _prefs.getString(PrefsKeys.preferredCategories);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  Future<void> setPreferredCategories(List<String> categories) {
    return _prefs.setString(
      PrefsKeys.preferredCategories,
      jsonEncode(categories),
    );
  }

  String get morningTime => _prefs.getString(PrefsKeys.morningTime) ?? '07:00';

  Future<void> setMorningTime(String hhmm) =>
      _prefs.setString(PrefsKeys.morningTime, hhmm);

  String get nightTime => _prefs.getString(PrefsKeys.nightTime) ?? '21:30';

  Future<void> setNightTime(String hhmm) =>
      _prefs.setString(PrefsKeys.nightTime, hhmm);

  // --- Racha ---
  String? get streakStateJson => _prefs.getString(PrefsKeys.streakState);

  Future<void> setStreakStateJson(String json) =>
      _prefs.setString(PrefsKeys.streakState, json);

  // --- Recordatorios ---
  List<String> get reminderTimes {
    final raw = _prefs.getString(PrefsKeys.reminderTimes);
    if (raw == null || raw.isEmpty) return ['07:00'];
    return (jsonDecode(raw) as List).cast<String>();
  }

  Future<void> setReminderTimes(List<String> times) {
    return _prefs.setString(PrefsKeys.reminderTimes, jsonEncode(times));
  }

  bool get notificationsEnabled =>
      _prefs.getBool(PrefsKeys.notificationsEnabled) ?? false;

  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(PrefsKeys.notificationsEnabled, value);

  // --- Plus ---
  bool get isPlusUser => _prefs.getBool(PrefsKeys.isPlusUser) ?? false;

  Future<void> setIsPlusUser(bool value) =>
      _prefs.setBool(PrefsKeys.isPlusUser, value);

  // --- Paywall ---
  bool get paywallShownAfterOnboarding =>
      _prefs.getBool(PrefsKeys.paywallShownAfterOnboarding) ?? false;

  Future<void> setPaywallShownAfterOnboarding(bool value) =>
      _prefs.setBool(PrefsKeys.paywallShownAfterOnboarding, value);

  // --- Apariencia ---
  /// `null` significa "sin preferencia explicita" (seguir el sistema).
  String? get selectedPaletteId => _prefs.getString(PrefsKeys.selectedPaletteId);

  Future<void> setSelectedPaletteId(String? id) async {
    if (id == null) {
      await _prefs.remove(PrefsKeys.selectedPaletteId);
      return;
    }
    await _prefs.setString(PrefsKeys.selectedPaletteId, id);
  }

  bool get simpleModeEnabled =>
      _prefs.getBool(PrefsKeys.simpleModeEnabled) ?? false;

  Future<void> setSimpleModeEnabled(bool value) =>
      _prefs.setBool(PrefsKeys.simpleModeEnabled, value);

  // --- Pausa y Ora ---
  List<String> get gatedApps {
    final raw = _prefs.getString(PrefsKeys.gatedApps);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  Future<void> setGatedApps(List<String> packageNames) {
    return _prefs.setString(PrefsKeys.gatedApps, jsonEncode(packageNames));
  }

  bool get gateEnabled =>
      (_prefs.getString(PrefsKeys.gateEnabledFlag) ?? 'false') == 'true';

  Future<void> setGateEnabled(bool value) =>
      _prefs.setString(PrefsKeys.gateEnabledFlag, value ? 'true' : 'false');

  int get gateGraceMinutes {
    final raw = _prefs.getString(PrefsKeys.gateGraceMinutes);
    return int.tryParse(raw ?? '') ?? 20;
  }

  Future<void> setGateGraceMinutes(int minutes) {
    return _prefs.setString(PrefsKeys.gateGraceMinutes, minutes.toString());
  }

  bool get accessibilityExplainerSeen =>
      _prefs.getBool(PrefsKeys.accessibilityExplainerSeen) ?? false;

  Future<void> setAccessibilityExplainerSeen(bool value) =>
      _prefs.setBool(PrefsKeys.accessibilityExplainerSeen, value);

  // --- Patrones de uso / Recordatorio inteligente ---
  /// JSON crudo (String) del registro de timestamps escrito nativamente
  /// por `PrayerGateForegroundService.kt`, o `null` si aun no hay
  /// ningun evento registrado. Ver `UsagePatternService` para el analisis.
  String? get usagePatternLogRaw => _prefs.getString(PrefsKeys.usagePatternLog);

  bool get smartReminderEnabled =>
      _prefs.getBool(PrefsKeys.smartReminderEnabled) ?? false;

  Future<void> setSmartReminderEnabled(bool value) =>
      _prefs.setBool(PrefsKeys.smartReminderEnabled, value);

  // --- Deteccion de oracion por voz ---
  bool get voiceDetectionEnabled =>
      _prefs.getBool(PrefsKeys.voiceDetectionEnabled) ?? false;

  Future<void> setVoiceDetectionEnabled(bool value) =>
      _prefs.setBool(PrefsKeys.voiceDetectionEnabled, value);

  /// Nombre de pila opcional (para saludos y notificaciones personales).
  String get userName => _prefs.getString(PrefsKeys.userName) ?? '';

  Future<void> setUserName(String value) =>
      _prefs.setString(PrefsKeys.userName, value.trim());

  /// `true` cuando ya se mostro (en esta instalacion) la explicacion
  /// amable del microfono antes de escuchar la primera oracion en voz alta.
  bool get micPrimingDone => _prefs.getBool(PrefsKeys.micPrimingDone) ?? false;

  Future<void> setMicPrimingDone(bool value) =>
      _prefs.setBool(PrefsKeys.micPrimingDone, value);

  bool get voiceDisclosureSeen =>
      _prefs.getBool(PrefsKeys.voiceDisclosureSeen) ?? false;

  Future<void> setVoiceDisclosureSeen(bool value) =>
      _prefs.setBool(PrefsKeys.voiceDisclosureSeen, value);
}
EOF_ORA_V8_7

mkdir -p "$(dirname 'lib/services/usage_pattern_service.dart')"
cat > 'lib/services/usage_pattern_service.dart' <<'EOF_ORA_V8_8'
import 'dart:convert';

import 'prefs_service.dart';

/// Analiza el registro de aperturas de apps "gateadas" para sugerir un
/// horario adicional de recordatorio basado en el habito real de la
/// persona, en vez de solo horarios fijos elegidos a mano.
///
/// El registro (`PrefsKeys.usagePatternLog`) lo escribe de forma nativa
/// `PrayerGateForegroundService.kt` cada vez que detecta la apertura de
/// una app marcada para "Pausa y Ora", usando la misma clave/prefijo
/// "flutter." que el resto de las preferencias compartidas entre Kotlin y
/// Flutter (ver el comentario de `PrefsService.dart`). Este servicio SOLO
/// lee esa clave; nunca la escribe desde el lado Flutter.
///
/// Es una personalizacion real (aprender de un patron de uso genuino),
/// distinta de una notificacion generica: si no hay datos suficientes
/// todavia, no se inventa nada y se debe mostrar un mensaje honesto de
/// "aun estoy aprendiendo tus horarios" en su lugar (ver
/// `RemindersScreen`).
class UsagePatternService {
  final PrefsService _prefs;

  UsagePatternService(this._prefs);

  /// Minimo de eventos registrados antes de sugerir un horario. Por debajo
  /// de este umbral no hay suficiente señal para que la sugerencia sea
  /// confiable.
  static const int minEventsRequired = 5;

  List<int> _readTimestamps() {
    final raw = _prefs.usagePatternLogRaw;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<num>()
          .map((e) => e.toInt())
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Cuantos eventos de apertura hay registrados hasta ahora.
  int get eventCount => _readTimestamps().length;

  /// `true` si ya hay suficientes datos para sugerir un horario.
  bool get hasEnoughData => eventCount >= minEventsRequired;

  /// Hora del dia (0-23) en la que la persona abre con mas frecuencia una
  /// app "gateada", o `null` si todavia no hay suficientes datos
  /// ([minEventsRequired]).
  int? mostCommonHour() {
    final timestamps = _readTimestamps();
    if (timestamps.length < minEventsRequired) return null;

    final counts = List<int>.filled(24, 0);
    for (final ts in timestamps) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      counts[dt.hour] += 1;
    }

    var bestHour = 0;
    var bestCount = -1;
    for (var hour = 0; hour < 24; hour++) {
      if (counts[hour] > bestCount) {
        bestCount = counts[hour];
        bestHour = hour;
      }
    }
    return bestHour;
  }
}
EOF_ORA_V8_8

mkdir -p "$(dirname 'lib/screens/gate_explainer/gate_explainer_screen.dart')"
cat > 'lib/screens/gate_explainer/gate_explainer_screen.dart' <<'EOF_ORA_V8_9'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/gate_service.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Pantalla explicativa, obligatoria antes de pedir los permisos de
/// "Pausa y Ora", tal como exige la politica de Google Play: se debe
/// explicar con claridad, ANTES de solicitarlos, para que se usa cada
/// permiso.
///
/// v8: ya no se usa el permiso de Accesibilidad. Ahora son DOS permisos
/// estandar de bienestar digital, cada uno con su tarjeta, su estado en
/// vivo (activado / pendiente) y su boton que abre la pantalla exacta de
/// Ajustes:
///  1. "Acceso de uso": para saber que app abres (solo el nombre).
///  2. "Mostrar sobre otras apps": para poner la pausa de oracion encima.
class GateExplainerScreen extends StatefulWidget {
  const GateExplainerScreen({super.key});

  @override
  State<GateExplainerScreen> createState() => _GateExplainerScreenState();
}

class _GateExplainerScreenState extends State<GateExplainerScreen>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool? _usageGranted;
  bool? _overlayGranted;
  bool _celebrated = false;

  bool get _allGranted => (_usageGranted ?? false) && (_overlayGranted ?? false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus().then((_) {
        if (mounted && _allGranted && !_celebrated) {
          _celebrated = true;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('¡Permisos activados! Pausa y Ora ya funciona ✅🙏'),
          ));
        }
      });
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _checking = true);
    final gate = context.read<GateService>();
    final usage = await gate.hasUsageAccess();
    final overlay = await gate.hasOverlayPermission();
    if (!mounted) return;
    setState(() {
      _usageGranted = usage;
      _overlayGranted = overlay;
      _checking = false;
    });
    if (usage && overlay) {
      // Si el interruptor ya estaba encendido, arranca el detector ya.
      await gate.syncNativeService();
    }
  }

  Future<void> _markSeenAnd(Future<void> Function() abrir) async {
    final prefs = context.read<PrefsService>();
    await prefs.setAccessibilityExplainerSeen(true);
    await abrir();
  }

  @override
  Widget build(BuildContext context) {
    final gate = context.read<GateService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Permisos de Pausa y Ora')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.pause_circle_outline,
                        size: 48, color: AppColors.tealDeep),
                    const SizedBox(height: 20),
                    Text('Dos permisos, una sola misión 🙏',
                        style: AppTypography.headline),
                    const SizedBox(height: 12),
                    Text(
                      'Para detenerte con una oración justo antes de que se '
                      'abra una app que te distrae, tu teléfono nos pide '
                      'activar dos permisos. Los dos se encienden en un '
                      'minuto y aquí te llevamos directo al lugar exacto.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Con ellos, Ora Ahora solo conoce el NOMBRE de la app '
                      'que abres (por ejemplo "Instagram"), nunca lo que ves '
                      'o escribes dentro. No leemos mensajes, contraseñas ni '
                      'fotos, y nada sale de tu teléfono.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 20),
                    _PermisoCard(
                      numero: '1',
                      titulo: 'Acceso de uso',
                      descripcion:
                          'Le dice a Ora Ahora qué app acabas de abrir, '
                          'para saber cuándo proponerte la pausa.',
                      granted: _usageGranted,
                      botonTexto: 'Activar Acceso de uso',
                      instruccion:
                          'En la pantalla que se abre, busca "Ora Ahora", '
                          'tócala y enciende "Permitir acceso de uso".',
                      onPressed: () =>
                          _markSeenAnd(gate.openUsageAccessSettings),
                    ),
                    const SizedBox(height: 14),
                    _PermisoCard(
                      numero: '2',
                      titulo: 'Mostrar sobre otras apps',
                      descripcion:
                          'Permite que la pausa de oración aparezca encima '
                          'de la app que ibas a abrir.',
                      granted: _overlayGranted,
                      botonTexto: 'Permitir mostrar encima',
                      instruccion:
                          'En la pantalla que se abre, enciende el '
                          'interruptor de "Ora Ahora".',
                      onPressed: () => _markSeenAnd(gate.openOverlaySettings),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Puedes apagar estos permisos cuando quieras desde el '
                      'mismo lugar, y "Pausa y Ora" se detendrá de inmediato. '
                      'Si te pierdes, vuelve aquí y empieza de nuevo: no pasa '
                      'nada 😊.',
                      style:
                          AppTypography.body.copyWith(color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  if (_allGranted)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle, color: AppColors.success),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                                'Los dos permisos están activos. ¡Gracias!'),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _checking
                            ? null
                            : () async {
                                await _refreshStatus();
                                if (!context.mounted) return;
                                if (_allGranted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text(
                                        '¡Permisos detectados! Pausa y Ora está activa ✅🙏'),
                                  ));
                                  Navigator.of(context).pop(true);
                                } else {
                                  final falta = (_usageGranted ?? false)
                                      ? 'el permiso 2: "Mostrar sobre otras apps"'
                                      : ((_overlayGranted ?? false)
                                          ? 'el permiso 1: "Acceso de uso"'
                                          : 'los dos permisos');
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        'Aún falta $falta 🤔 Usa el botón de '
                                        'esa tarjeta y enciende el interruptor '
                                        'de Ora Ahora.'),
                                  ));
                                }
                              },
                        child: Text(_checking
                            ? 'Comprobando...'
                            : 'Ya activé los permisos'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_allGranted),
                    child: Text(_allGranted ? 'Continuar' : 'Volver'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermisoCard extends StatelessWidget {
  final String numero;
  final String titulo;
  final String descripcion;
  final String instruccion;
  final String botonTexto;
  final bool? granted;
  final VoidCallback onPressed;

  const _PermisoCard({
    required this.numero,
    required this.titulo,
    required this.descripcion,
    required this.instruccion,
    required this.botonTexto,
    required this.granted,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final activo = granted ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: activo ? AppColors.success : AppColors.tealLight,
          width: activo ? 1.6 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: activo ? AppColors.success : AppColors.tealDeep,
                  shape: BoxShape.circle,
                ),
                child: activo
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(numero,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        )),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(titulo, style: AppTypography.title)),
              if (activo)
                Text('Activado ✅',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 8),
          Text(descripcion, style: AppTypography.body),
          if (!activo) ...[
            const SizedBox(height: 8),
            Text(instruccion,
                style: AppTypography.body
                    .copyWith(fontSize: 13.5, color: AppColors.inkSoft)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(botonTexto),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
EOF_ORA_V8_9

mkdir -p "$(dirname 'lib/screens/settings/gated_apps_screen.dart')"
cat > 'lib/screens/settings/gated_apps_screen.dart' <<'EOF_ORA_V8_10'
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/gate_service.dart';
import '../../services/purchase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../gate_explainer/gate_explainer_screen.dart';

/// Pantalla para elegir que apps instaladas requeriran una "Pausa y Ora"
/// antes de abrirse. La version gratuita permite 1 app; Ora Ahora Plus
/// permite apps ilimitadas.
class GatedAppsScreen extends StatefulWidget {
  const GatedAppsScreen({super.key});

  @override
  State<GatedAppsScreen> createState() => _GatedAppsScreenState();
}

class _GatedAppsScreenState extends State<GatedAppsScreen> {
  static const _freeLimit = 1;

  late Future<List<Application>> _appsFuture;
  bool? _permissionsOk;

  @override
  void initState() {
    super.initState();
    _appsFuture = context.read<GateService>().installedLaunchableApps();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await context.read<GateService>().hasAllGatePermissions();
    if (mounted) setState(() => _permissionsOk = granted);
  }

  int get _maxApps =>
      context.read<PurchaseService>().isPlusUser ? 999999 : _freeLimit;

  Future<void> _onMasterSwitch(bool value) async {
    final gate = context.read<GateService>();
    if (value && _permissionsOk != true) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const GateExplainerScreen()),
      );
      await _checkPermissions();
      if (result != true && _permissionsOk != true) {
        return; // el usuario no activo los permisos; no encendemos el switch
      }
    }
    await gate.setGateEnabled(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gate = context.watch<GateService>();
    final isPlus = context.watch<PurchaseService>().isPlusUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Pausa y Ora')),
      body: SafeArea(
        child: Column(
          children: [
            SwitchListTile(
              value: gate.gateEnabled,
              onChanged: _onMasterSwitch,
              title: const Text('Activar Pausa y Ora'),
              subtitle: const Text('Requiere dos permisos sencillos (te guiamos)'),
            ),
            if (!isPlus)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amberLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Plan gratuito: puedes elegir 1 app. Con Ora Ahora Plus '
                    'puedes bloquear todas las que quieras.',
                    style: AppTypography.caption,
                  ),
                ),
              ),
            const Divider(height: 24),
            Expanded(
              child: FutureBuilder<List<Application>>(
                future: _appsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final apps = snapshot.data!;
                  if (apps.isEmpty) {
                    // Caso extremo (casi nunca ocurre en un telefono real):
                    // sin apps instaladas que se puedan abrir. Estado vacio
                    // minimo (icono + texto centrado) en vez de una lista en
                    // blanco sin explicacion.
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.apps_outlined,
                              size: 48,
                              color: AppColors.inkSoft,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No encontramos apps instaladas para elegir.',
                              textAlign: TextAlign.center,
                              style: AppTypography.body.copyWith(color: AppColors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      final isGated = gate.isGated(app.packageName);
                      return ListTile(
                        leading: app is ApplicationWithIcon
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(app.icon,
                                    width: 36, height: 36),
                              )
                            : const Icon(Icons.apps),
                        title: Text(app.appName),
                        trailing: Switch(
                          value: isGated,
                          onChanged: (value) async {
                            if (value && !isGated && gate.gatedApps.length >= _maxApps) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Con el plan gratuito solo puedes elegir '
                                    '$_freeLimit app. Obtén Ora Ahora Plus '
                                    'para apps ilimitadas.',
                                  ),
                                ),
                              );
                              return;
                            }
                            await gate.toggleGatedApp(
                              app.packageName,
                              maxApps: _maxApps,
                            );
                            setState(() {});
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
EOF_ORA_V8_10

mkdir -p "$(dirname 'lib/screens/settings/battery_optimization_screen.dart')"
cat > 'lib/screens/settings/battery_optimization_screen.dart' <<'EOF_ORA_V8_11'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/gate_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Pantalla que explica, en español sencillo, por qué conviene excluir a
/// Ora Ahora de la optimización de batería de Android, y da acceso directo
/// al diálogo nativo para hacerlo
/// (`Intent.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`).
///
/// Esto complementa (no reemplaza) al foreground service nativo
/// (`PrayerGateForegroundService.kt`): ambos existen para reducir el
/// riesgo de que Android silencie `PrayerGateForegroundService` en
/// segundo plano, especialmente en fabricantes con gestión agresiva de
/// batería (Xiaomi, Samsung, Huawei, etc.).
class BatteryOptimizationScreen extends StatefulWidget {
  const BatteryOptimizationScreen({super.key});

  @override
  State<BatteryOptimizationScreen> createState() => _BatteryOptimizationScreenState();
}

class _BatteryOptimizationScreenState extends State<BatteryOptimizationScreen>
    with WidgetsBindingObserver {
  bool? _ignoring;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    final gate = context.read<GateService>();
    final ignoring = await gate.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() => _ignoring = ignoring);
  }

  @override
  Widget build(BuildContext context) {
    final ignoring = _ignoring ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Optimización de batería')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.battery_saver_outlined, size: 48, color: AppColors.tealDeep),
            const SizedBox(height: 20),
            Text('¿Por qué importa esto?', style: AppTypography.headline),
            const SizedBox(height: 12),
            Text(
              'Algunos fabricantes de teléfonos (Xiaomi, Samsung, Huawei y '
              'otros) aplican una gestión de batería muy agresiva que puede '
              'apagar en silencio el servicio que detecta cuándo abres una '
              'app marcada para "Pausa y Ora", sin avisarte. Si eso pasa, '
              'dejarías de ver la pausa de oración sin darte cuenta.',
              style: AppTypography.body,
            ),
            const SizedBox(height: 14),
            Text(
              'Al excluir a Ora Ahora de la optimización de batería, le pides '
              'a Android que no apague esta función en segundo plano. Esto '
              'no consume batería adicional de forma relevante: Ora Ahora no '
              'hace ningún trabajo salvo cuando abres una app marcada.',
              style: AppTypography.body.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 28),
            if (ignoring)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ora Ahora ya está excluida de la optimización de batería. ¡Gracias!',
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final gate = context.read<GateService>();
                    await gate.requestIgnoreBatteryOptimizations();
                    await _refreshStatus();
                  },
                  child: const Text('Permitir que Ora Ahora se ejecute sin restricciones'),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _refreshStatus,
                child: const Text('Comprobar de nuevo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
EOF_ORA_V8_11

mkdir -p "$(dirname 'lib/screens/onboarding/onboarding_gate_screen.dart')"
cat > 'lib/screens/onboarding/onboarding_gate_screen.dart' <<'EOF_ORA_V8_12'
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../gate_explainer/gate_explainer_screen.dart';
import 'onboarding_done_screen.dart';
import 'onboarding_progress_dots.dart';

/// Presenta "Pausa y Ora" (lo que hace unica a la app) DURANTE el
/// onboarding, con lenguaje humano y sencillo. Los permisos tecnicos
/// (Acceso de uso + Mostrar sobre otras apps) se piden despues, en
/// GateExplainerScreen, como exige Google Play.
class OnboardingGateScreen extends StatelessWidget {
  const OnboardingGateScreen({super.key});

  void _next(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingDoneScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const OnboardingTopBar(step: 9),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Y esto es lo que nos\nhace diferentes ✨',
                  style: AppTypography.display.copyWith(fontSize: 28)),
              const SizedBox(height: 12),
              Text(
                '¿Te pasa que abres el celular "un minutito" y de repente '
                'se fue media hora? A todos nos pasa.',
                style:
                    AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 16),
              _Paso(
                emoji: '📱',
                texto: 'Tú eliges las apps que más te distraen '
                    '(por ejemplo, Instagram o TikTok).',
              ),
              _Paso(
                emoji: '✋',
                texto: 'Cuando vayas a abrirlas, Ora Ahora te detiene '
                    'unos segundos primero.',
              ),
              _Paso(
                emoji: '🙏',
                texto: 'Respiras, haces una oración cortita… y tú decides '
                    'si sigues o mejor no.',
              ),
              const SizedBox(height: 16),
              Text(
                'Para lograrlo, tu teléfono nos pedirá dos permisos sencillos. '
                'En la siguiente pantalla te explicamos cuáles son y cómo '
                'activarlos, paso a paso y sin apuro.',
                style: AppTypography.body.copyWith(color: AppColors.inkSoft),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const GateExplainerScreen()),
                    );
                    if (!context.mounted) return;
                    _next(context);
                  },
                  child: const Text('Quiero activarlo ✋🙏'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => _next(context),
                  child: Text('Lo activo después desde Ajustes',
                      style: AppTypography.body
                          .copyWith(color: AppColors.inkSoft)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  final String emoji;
  final String texto;
  const _Paso({required this.emoji, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto,
                style: AppTypography.body.copyWith(fontSize: 15.5)),
          ),
        ],
      ),
    );
  }
}
EOF_ORA_V8_12

mkdir -p "$(dirname 'PLAY_STORE_LISTING.md')"
cat > 'PLAY_STORE_LISTING.md' <<'EOF_ORA_V8_13'
# Ficha de Google Play — Ora Ahora

Este documento reúne el texto de la ficha de Play Store (ASO) y un
checklist de assets gráficos requeridos. Los límites de caracteres de cada
campo se respetan según las reglas de Google Play Console (verificados con
un conteo de caracteres real, ver nota al final del documento).

## Título de la app (máximo 30 caracteres)

```
Ora Ahora
```

Longitud real: 9 caracteres. Decisión del cliente: el título es solo
"Ora Ahora", sin subtítulo/descriptor adicional. Como el nombre por sí
solo no comunica la mecánica de "pausa antes de abrir redes sociales", la
descripción breve y la descripción completa se escribieron para dejarla
clara desde la primera línea.

## Descripción breve (máximo 80 caracteres)

```
Pausa y ora antes de abrir redes sociales. Devocional diario en español.
```

Longitud real: 72 caracteres.

## Descripción completa (máximo 4000 caracteres)

```
Ora Ahora es tu compañero diario de oración cristiana interdenominacional,
pensado para ayudarte a construir un hábito saludable de fe y a recuperar
el control de tu tiempo frente a la pantalla.

¿QUÉ ES ORA AHORA?

Antes de abrir Instagram, TikTok u otras apps que te distraen, Ora Ahora
te invita a una breve pausa de oración. Además, incluye un devocional
diario en español con oraciones breves para cada momento de tu día:
mañana, noche, ansiedad, gratitud, familia, trabajo, sanidad, perdón y
duelo. Cada oración incluye una referencia bíblica y toma solo unos
minutos, para que puedas volver a Dios sin importar cuán ocupado esté tu
día.

PAUSA Y ORA: BLOQUEAR REDES SOCIALES DE FORMA CRISTIANA

La función que nos hace diferentes: en vez de solo bloquear redes
sociales, Ora Ahora te invita a una breve pausa de oración justo antes de
abrir las apps que más te distraen (Instagram, TikTok, juegos y más). Es
una forma de bloquear redes sociales cristianos con propósito: no se
trata solo de prohibir, sino de elegir con libertad y calma qué haces con
tu tiempo y tu atención. Ideal si buscas una app de enfoque cristiano que
te ayude a soltar el scroll infinito sin sentirte culpable.

UN RASTREADOR DE HÁBITOS DE FE, NO UNA RACHA QUE CASTIGA

Lleva tu racha de días orando con un sistema justo: si un día se te pasa,
tienes un día libre a la semana que no rompe tu racha (a diferencia de
otras apps que castigan con dureza el primer descuido). Mira también tu
"Semilla" crecer hasta convertirse en un Árbol de fe a medida que
acumulas minutos de oración: un rastreador de hábitos de fe visual,
sencillo y alentador, no punitivo.

ORACIÓN ANTES DE DORMIR Y EN CUALQUIER MOMENTO DEL DÍA

Elige entre 4 estilos visuales, incluida una paleta oscura pensada
especialmente para tu oración antes de dormir, y otras 3 paletas claras
para el resto del día. Incluye "Modo Simple": texto y botones más
grandes, ideal para adultos mayores o cualquier persona que prefiera una
interfaz más cómoda de usar.

DIARIO DE ORACIÓN PERSONAL

Escribe tus intenciones y peticiones, márcalas como respondidas cuando
Dios actúe, y vuelve a leerlas cuando necesites recordar Su fidelidad.

RECORDATORIOS SUAVES, NO INVASIVOS

Programa hasta 3 recordatorios diarios con mensajes rotativos que te
invitan a hacer una pausa y orar, sin sentirse repetitivos ni
mecánicos.

CONFIRMACIÓN POR VOZ, 100% EN TU TELÉFONO (OPCIONAL)

A diferencia de otras apps de oración, que solo confían en un toque de
botón, Ora Ahora puede confirmar con tu propia voz que terminaste de
orar. Es opcional (apagada por defecto): el micrófono solo se activa si
tocas "Escuchar mi oración", funciona 100% en tu teléfono, nunca graba ni
envía audio a un servidor, y solo detecta si dijiste "amén" o si hablaste
de forma continua un buen rato. Siempre puedes usar el botón manual en su
lugar.

PRIVACIDAD PRIMERO

Todo tu diario, tu racha y tus preferencias se guardan localmente en tu
teléfono. Ora Ahora no lee el contenido de tus otras apps: el permiso de
"Acceso de uso" usado por "Pausa y Ora" solo detecta qué app está al
frente (únicamente su nombre), para saber cuándo mostrarte la pausa, y
nunca se envía a ningún servidor. Lo mismo aplica a la confirmación por voz: 100% local, nunca se
sube a un servidor.

PARA TODAS LAS DENOMINACIONES

Ora Ahora es interdenominacional: no pertenece a ninguna iglesia o
denominación en particular, para que cualquier cristiano de habla
hispana se sienta como en casa.

Ora Ahora Plus (opcional) desbloquea apps ilimitadas en "Pausa y Ora",
fichas de congelación de racha adicionales y paquetes de oración
exclusivos — pero el plan gratuito de Ora Ahora siempre incluye acceso
completo al devocional diario, 1 app bloqueada en "Pausa y Ora" y tu
racha básica, sin fecha de vencimiento.

Descarga Ora Ahora hoy y convierte cada pausa del día en un momento de
oración.
```

Longitud real: 3840 caracteres.

## Checklist de assets gráficos requeridos (Play Console)

Ninguna imagen fue generada en este documento; esto es solo la lista de
lo que falta producir y subir antes de publicar.

- [ ] Ícono de la app: 512 x 512 px, PNG de 32 bits (con canal alfa),
      máximo 1024 KB. Reemplaza el ícono placeholder actual en
      `android/app/src/main/res/mipmap-*/ic_launcher.png`.
- [ ] Gráfico de funciones ("feature graphic"): 1024 x 500 px, JPG o PNG
      de 24 bits (sin transparencia).
- [ ] Capturas de pantalla del teléfono: mínimo 2, máximo 8. Formato JPG
      o PNG de 24 bits, lado mínimo 320 px, lado máximo 3840 px, relación
      de aspecto entre 16:9 y 9:16. Se recomienda incluir:
      1. Inicio con la oración del día y el widget Semilla/Árbol de fe.
      2. Pantalla de "Pausa y Ora" (PrayerGateActivity) en acción.
      3. Diario de oración.
      4. Selector de paletas de color (Ajustes > Apariencia).
      5. Pantalla de paywall / Ora Ahora Plus.
- [ ] (Opcional pero recomendado) Video promocional corto de YouTube
      (enlace, no archivo subido directamente).
- [ ] Categoría de la app en Play Console: Estilo de vida o Salud y
      bienestar (evaluar cuál rinde mejor en pruebas A/B posteriores).
- [ ] Clasificación de contenido (content rating questionnaire).
- [ ] Formulario de Seguridad de Datos (Data Safety), documentando el uso
      de "Acceso de uso" (PACKAGE_USAGE_STATS) y "Mostrar sobre otras
      apps" para la función de bienestar digital "Pausa y Ora", y que
      todo el almacenamiento es local. (v8: ya NO se usa la API de
      Accesibilidad, así que no hace falta la declaración especial de
      Accesibilidad que Google revisa manualmente.)
- [ ] Declarar honestamente el uso de RECORD_AUDIO/micrófono (función
      opcional de confirmación por voz): explicar que el audio se procesa
      100% en el dispositivo (reconocimiento on-device de Android), que
      nunca se sube ni comparte con terceros, y que no se graba ni se
      guarda ningún archivo de audio.

## Nota sobre keywords usadas

Se incluyeron de forma natural (sin relleno/keyword stuffing) las
siguientes frases de cola larga relevantes para búsqueda en Play Store:
"bloquear redes sociales cristianos", "devocional diario", "rastreador de
hábitos de fe", "oración antes de dormir" y "enfoque cristiano". Todas
aparecen en frases completas y naturales en español latinoamericano
neutro, no como una lista de palabras sueltas.

Como el título ya no incluye un descriptor (decisión final del cliente:
solo "Ora Ahora"), la descripción breve y el primer párrafo de la
descripción completa se reforzaron para comunicar la mecánica de "pausa
antes de abrir redes sociales" desde el primer vistazo en la ficha de
Play Store.
EOF_ORA_V8_13

mkdir -p "$(dirname 'PROYECTO_ORA_AHORA.md')"
cat > 'PROYECTO_ORA_AHORA.md' <<'EOF_ORA_V8_14'
# ORA AHORA — Documento maestro del proyecto
*(Para retomar este proyecto en cualquier conversación nueva con Claude: lee este documento completo ANTES de tocar nada.)*

## 1. Qué es
App Android en **Flutter** de oración **cristiana (NO católica: sin santos, sin María, sin rosario)** en español, de Maria (mariarodriguez8). Objetivo: publicarla en Play Store y que sea la mejor app cristiana — "obsesiva" (uso diario), con interfaz "hiper grabable" para UGC/TikTok.

Funciones: oración del día · 152 oraciones locales en 14 categorías · racha + árbol de fe que crece con minutos acumulados · diario · orar en voz alta con verificación real (compara lo dicho contra el texto) · **"Pausa y Ora"** (única en el mercado: intercepta apps distractoras vía servicio de Accesibilidad nativo Kotlin y propone orar antes de abrirlas) · paywall suave "Plus".

## 2. Dónde vive todo
- **Repo:** `github.com/mariarodriguez8/ora-ahora` (a veces público temporalmente; debe volver a privado).
- **Compilación:** GitHub Codespace "expert dollop" del repo (Flutter 3.44 ya configurado y parchado). Maria NO programa: todo se hace por ella.
- **Estado actual: v8 — migración Play Store** ("Pausa y Ora" ya NO usa Accesibilidad: ahora usa Acceso de uso + overlay, ver sección 6). v7 fue probada y aprobada por Maria. Los scripts `apply_*.sh` en la raíz son históricos; el código fuente en `lib/` ya los tiene todo aplicado. Logo nuevo YA aplicado en mipmaps + store icon.

### Estructura del código
```
lib/
  main.dart                    # MultiProvider + MaterialApp (locale es, delegates)
  models/prayer.dart           # Prayer + PrayerCategories (14 claves ASCII)
  services/                    # prefs, streak (racha+minutos), prayer_repository,
                               # notification, gate (MethodChannel permisos v8),
                               # voice_prayer (speech_to_text on-device), purchase (stub)
  screens/onboarding/          # 11 pantallas: welcome→name→categories→times→plan→
                               # social→first_prayer→commitment→reminders→gate→done
  screens/home/                # saludo con nombre + mini-semilla + oración del día +
                               # feed "Para ti" (2 gratis, resto candado 🔒→paywall)
  screens/prayer_detail/       # página devocional serif + orar en voz alta
  screens/{journal,settings,paywall,gate_explainer,voice_explainer}/
  widgets/                     # prayer_card, faith_tree, streak_badge,
                               # time_wheel_picker, amen_celebration (overlay dorado)
  theme/                       # app_colors, app_typography, app_theme, app_palettes
assets/data/prayers_es.json    # 152 oraciones (ids categoria_NN)
assets/fonts/                  # Fraunces (serif títulos/oraciones) + Figtree (UI), OFL
android/.../oraahora/          # MainActivity + PrayerGate{AccessibilityService,
                               # Activity,ForegroundService}.kt (nativo)
store_assets/icon_512.png      # ícono tienda
```

### Diseño "Santuario"
Papel marfil `#F7F3EA` · verde abeto `#16342B` · dorado `#8A5F27/#D9B37C` · serif Fraunces + sans Figtree · 4 paletas en Ajustes (Bosque y Lino default, Amanecer, Oliva y Salvia, Vigilia oscura), contrastes WCAG AA verificados. Copy humano, cálido, apto para personas mayores, con emojis moderados. **Cuidado doctrinal:** nada litúrgico-católico (se eliminó "la paz sea contigo"); cruz VACÍA sí es símbolo evangélico.

## 3. Cómo compilar y entregar (flujo probado)
1. Cambios → commit/push al repo (o script `apply_vN.sh` subido por github.com/upload).
2. En el Codespace: `git pull && flutter analyze && flutter build apk --debug`
   (solo son aceptables avisos *info*; hoy ~66).
3. `cp build/app/outputs/flutter-apk/app-debug.apk .../ora-ahora.apk.zip`
4. Descarga: el download de VS Code web falla con archivos grandes → levantar
   `python3 -m http.server 9200` en la carpeta del APK y bajar desde
   `https://<codespace>-9200.app.github.dev/` en el navegador de Maria.
5. El Codespace se duerme por inactividad cada pocos minutos: reiniciar y reintentar.

### Parches de entorno YA aplicados (no repetir, pero saber que existen)
Gradle wrapper 8.9 · AGP 8.7.3 · coreLibraryDesugaring 2.1.4 · gradle.properties con -Xmx2G y workers.max=2 (la máquina tiene 7.8GB y el daemon moría) · Kotlin `setPriority(...)` en ForegroundService · `intl: ^0.20.2` · **device_apps 2.2.0 necesita namespace inyectado en el pub-cache tras cada `flutter pub get` limpio:**
`sed -i "s/android {/android {\n    namespace 'fr.g123k.deviceapps'/" /root/.pub-cache/hosted/pub.dev/device_apps-2.2.0/android/build.gradle`

## 4. Instalación en el teléfono de Maria (tester)
APK renombrado a `.zip` para descargar → renombrar a `.apk` en el teléfono → instalar. Desde v8 ya no se usa Accesibilidad, así que la "Configuración restringida" de Android 13+ NO debería aparecer (aplicaba a Accesibilidad). "Acceso de uso" y "Mostrar sobre otras apps" se activan normal en Ajustes, la app te lleva directo.

## 5. HECHO EN v6/v7 (feedback de Maria ya resuelto) + PENDIENTES

### Resuelto y compilado (no rehacer):
✅ Logo "halo+cruz+amanecer" aplicado (mipmaps + store icon) · ✅ Bienvenida WOW con degradado índigo→esmeralda y halo/cruz de luz animados · ✅ Onboarding de 11 pantallas con quiz, "preparando tu plan", testimonio, primera oración, pantalla de micrófono con contexto, pacto, recordatorios, Pausa y Ora · ✅ Coherencia oración↔tema (oración del día y primera oración salen del PRIMER tema elegido; feed ordenado por temas) · ✅ Overlay "Amén" dorado a pantalla completa que avanza solo · ✅ Campo de nombre vibra/sacude si está vacío · ✅ Botón "ya activé el permiso" responde siempre (celebra y cierra, o explica qué falta) + fallback nativo por packageName + guía de "Configuración restringida" · ✅ Micrófono: permiso basado en estado REAL del sistema, una sola pregunta, motor siempre inicializado antes de escuchar (bug "no lee" corregido) · ✅ UI de escucha: mic dorado gigante con ondas y degradado, oración compactada · ✅ 2 oraciones gratis + candados → paywall personalizado con el tema del quiz · ✅ Orar varias veces al día suma minutos al árbol · ✅ Mini-semilla con progreso junto a la racha.

### Pendientes reales:
1. Maria debe PROBAR v7 en su teléfono y reportar (especialmente: voz leyendo la oración, botón de permiso, coherencia de temas).
2. ✅ HECHO EN v8: migración a "Acceso de uso" + overlay (PrayerGateForegroundService.kt ahora sondea UsageStatsManager con la pantalla encendida; PrayerGateAccessibilityService.kt eliminado; GateBootReceiver rearranca tras reinicio; MainActivity/GateService con métodos nuevos: openUsageAccessSettings, openOverlaySettings, hasUsageAccess, hasOverlayPermission, syncGateService; GateExplainerScreen rediseñada con 2 tarjetas de permiso). Maria debe PROBARLA en su teléfono.
3. Ideas de retención aún no implementadas: widget de pantalla de inicio, retos "Ora40", compañeros de oración, anti-churn, notificaciones con nombre.
4. Splash/launch screen aún es marfil plano — armonizarlo con el degradado del logo.

## 6. Backlog estratégico (decidido con investigación)
- **Play Store**: ✅ migración "Pausa y Ora" Accesibilidad → "Acceso de uso" + overlay HECHA en v8. Quedan: build release firmado · política de privacidad URL · formularios Play Console · cuenta developer $25.
- **Logo: DECIDIDO** — "Halo + cruz + amanecer" estilo 2026 (aro de luz dorado con cruz luminosa pequeña y resplandor de amanecer, sobre degradado índigo→esmeralda). **YA APLICADO en v6** (mipmaps + icon_512 en el código). Solo falta armonizar el splash/launch con el degradado nuevo.
- Investigación completa (Cal AI 33 pantallas, paywall tras quiz 5x, Coconote UGC, Hallow) ya hecha: onboarding largo ✓ (11 pantallas), falta: widget de pantalla de inicio, retos ("Ora40"), compañeros de oración, anti-churn 7 días extra, notificaciones emocionales con nombre.
- Backend futuro (cuentas/nube/comunidad): hoy TODO es local/offline (racha se pierde al desinstalar).
- Paywall se mantiene SUAVE por decisión de Maria; 2 oraciones gratis en feed + resto candado.

## 7. Cómo retomar en conversación nueva
1. Lee este documento y `PLAY_STORE_LISTING.md` del repo.
2. Clona el repo (pedir a Maria hacerlo público 2 min, o leerlo vía su Chrome logueado).
3. Trabaja los pendientes de la sección 5 en orden; empaqueta como `apply_vN.sh` (heredocs de archivos completos + binarios en base64, autocontenido e idempotente, probado contra copia limpia).
4. Sube el script por github.com/upload (file_upload del navegador), córrelo en el Codespace, compila, sirve la descarga con http.server, y commit+push al final.
5. Estilo de trabajo con Maria: español, directa, no técnica, aprecia listas claras y que se le pregunte poco pero decisiones de negocio son SUYAS (paywall, logo, precios). Verificación estática siempre antes de compilar (balance de llaves, imports, frases católicas prohibidas).
EOF_ORA_V8_14

echo "== v8: verificación rápida =="
grep -rl "PrayerGateAccessibilityService" lib android/app/src/main --include='*.dart' --include='*.kt' --include='*.xml' 2>/dev/null | grep -v PrayerGateForegroundService.kt && { echo "ERROR: quedaron referencias al servicio viejo"; exit 1; }
echo "OK: sin referencias al servicio de Accesibilidad."
echo ""
echo "v8 aplicada. Siguiente paso en el Codespace:"
echo "  flutter pub get"
echo "  sed -i \"s/android {/android {\\n    namespace 'fr.g123k.deviceapps'/\" /root/.pub-cache/hosted/pub.dev/device_apps-2.2.0/android/build.gradle  # solo si hiciste pub get limpio"
echo "  flutter analyze && flutter build apk --debug"
