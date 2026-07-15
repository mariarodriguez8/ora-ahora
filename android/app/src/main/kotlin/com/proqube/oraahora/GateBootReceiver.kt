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
