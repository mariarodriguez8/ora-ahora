package com.proqube.oraahora

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder

/**
 * Servicio en primer plano (foreground service) cuya unica funcion es
 * darle al sistema operativo una señal adicional de "esta app sigue
 * activa", para que [PrayerGateAccessibilityService] tenga menos
 * probabilidad de ser detenido en segundo plano por la gestion agresiva
 * de bateria de algunos fabricantes (Xiaomi, Samsung, Huawei, etc.), que
 * a veces matan servicios de Accesibilidad silenciosamente.
 *
 * Muestra una notificacion PERSISTENTE, silenciosa y de baja prioridad
 * (`IMPORTANCE_MIN`, sin sonido ni vibracion) que le explica al usuario,
 * en español, por que sigue viendo el icono de Ora Ahora en la barra de
 * estado: "Ora Ahora está activo para interceptar aperturas de apps". El
 * usuario puede detener este servicio en cualquier momento desactivando
 * "Pausa y Ora" desde Ajustes (ver `GateService.setGateEnabled`) o
 * revocando el permiso de Accesibilidad.
 *
 * Este servicio NO hace ningun trabajo de deteccion por si mismo:
 * [PrayerGateAccessibilityService] sigue siendo el unico responsable de
 * detectar aperturas de apps y lanzar la pausa de oracion. Este servicio
 * solo mantiene la señal de "primer plano" ante Android.
 */
class PrayerGateForegroundService : Service() {

    companion object {
        private const val CHANNEL_ID = "ora_ahora_gate_active"
        private const val NOTIFICATION_ID = 4201

        /** Inicia el servicio (llamado desde PrayerGateAccessibilityService). */
        fun start(context: Context) {
            val intent = Intent(context, PrayerGateForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        /** Detiene el servicio (llamado cuando se desactiva Accesibilidad). */
        fun stop(context: Context) {
            context.stopService(Intent(context, PrayerGateForegroundService::class.java))
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createChannelIfNeeded()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, buildNotification())
        return START_STICKY
    }

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
            .setContentText("Ora Ahora está activo para interceptar aperturas de apps")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_SERVICE)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            builder.priority = Notification.PRIORITY_MIN
        }

        if (contentIntent != null) {
            builder.setContentIntent(contentIntent)
        }

        return builder.build()
    }
}
