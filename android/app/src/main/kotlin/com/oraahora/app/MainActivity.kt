package com.oraahora.app

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
 * expone un MethodChannel ("com.oraahora.app/gate") con operaciones
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
    private val channelName = "com.oraahora.app/gate"

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
