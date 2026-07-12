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
 *  - abrir la pantalla de Ajustes > Accesibilidad de Android.
 *  - comprobar si PrayerGateAccessibilityService esta activo.
 *  - pedir (o comprobar) la exclusion de Ora Ahora de la optimizacion de
 *    bateria de Android, para que "Pausa y Ora" no sea silenciada por el
 *    sistema en fabricantes con gestion agresiva de bateria.
 *
 * El resto del estado de "Pausa y Ora" (apps bloqueadas, interruptor
 * general, minutos de gracia) se comparte con el servicio de accesibilidad
 * a traves de SharedPreferences (ver PrefsService.dart y
 * PrayerGateAccessibilityService.kt), sin necesidad de MethodChannel.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.proqube.oraahora/gate"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openAccessibilitySettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OPEN_SETTINGS_FAILED", e.message, null)
                        }
                    }
                    "isAccessibilityServiceEnabled" -> {
                        result.success(PrayerGateAccessibilityService.isEnabled(applicationContext))
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

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }
}
