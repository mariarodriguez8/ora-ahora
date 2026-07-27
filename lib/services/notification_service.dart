import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../app_globals.dart';
import '../screens/momento/momento_oracion_screen.dart';

/// v29: al TOCAR un recordatorio de la hora, la app abre directo la
/// pantalla de "momento de oracion" (oracion corta + "Amen, ya ore").
/// Se maneja aqui, a nivel top-level, para poder navegar con la
/// `navigatorKey` global sin necesitar un BuildContext.
void _handleNotificationTap(NotificationResponse response) {
  if (response.payload == kMomentoPayload) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const MomentoOracionScreen()),
    );
  }
}

/// Programa recordatorios diarios de oracion usando notificaciones locales.
///
/// Diseno pensado para no ser "robotico": en lugar de una unica notificacion
/// diaria repetida con el mismo texto (lo que ofrece el flag
/// `matchDateTimeComponents` de forma nativa), se programan notificaciones
/// individuales para los proximos [_daysAhead] dias, cada una con un texto
/// distinto tomado de una lista rotativa. `refreshSchedule` debe llamarse
/// cada vez que la app se abre (y cada vez que cambian los horarios) para
/// mantener la "cola" de notificaciones futuras llena.
///
/// v25: se usa `AndroidScheduleMode.exactAllowWhileIdle` (alarmas EXACTAS).
/// Antes se usaban alarmas inexactas para evitar el permiso especial, pero
/// en fabricantes con gestion agresiva de bateria (Xiaomi/MIUI, Samsung,
/// Huawei...) las alarmas inexactas se retrasan horas o NO llegan. El
/// permiso `SCHEDULE_EXACT_ALARM` ya esta en el manifiesto y se solicita
/// en `requestPermission`.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _daysAhead = 14;
  static const String _channelId = 'ora_ahora_recordatorios';
  static const String _channelName = 'Recordatorios de oración';
  static const String _channelDescription =
      'Avisos suaves para hacer una pausa y orar durante el día.';

  /// Base de IDs reservada para el "Recordatorio inteligente" (ver
  /// [scheduleSmartReminder]). Los recordatorios fijos usan
  /// `slot * 1000 + dayOffset` con `slot` en 0..2 y `dayOffset` en
  /// 0.._daysAhead-1 (maximo 2013), asi que este rango no choca con ellos.
  static const int _smartReminderBaseId = 9000;

  static const String _smartReminderMessage =
      'en un ratito vas a agarrar el celu sin pensar. ¿y si primero '
      'hablas con Dios?';

  // v27: recordatorios en la voz del ICP (culpa + nostalgia de Su presencia,
  // referencia al celular/scroll), no lenguaje de app de meditación. Con
  // gracia, nunca condenando.
  static const List<String> _mensajes = [
    '¿ya abriste el celu mil veces y a Dios ni un "hola"? ven, es un ratito.',
    'tu oveja tiene sed 🌱 dale 2 minutos a Dios antes del scroll.',
    'sé que el día se te va en la pantalla. este es tu momento con Él.',
    'antes de Instagram, antes de todo… háblale a Dios un minuto.',
    'no te alejes otra vez sin darte cuenta. ven a orar tantito.',
    'Dios te extraña más que cualquier notificación. ven 🙏',
    '¿hace cuánto no le hablas? aquí te espera, sin reproches.',
    'un minuto con Dios ahorita vale más que mil videos. tú sabes.',
  ];

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      // Si no se puede detectar la zona horaria del dispositivo, se usa UTC
      // como respaldo seguro (las notificaciones seguiran funcionando,
      // aunque la hora podria no coincidir exactamente con la local).
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.defaultImportance,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  /// Solicita el permiso de notificaciones en tiempo de ejecucion
  /// (obligatorio desde Android 13 / API 33, `POST_NOTIFICATIONS`).
  /// Devuelve `true` si el permiso quedo concedido.
  Future<bool> requestPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return false;
    final granted = await androidImpl.requestNotificationsPermission();
    // v25: ademas del permiso de notificaciones, pedimos el de "alarmas y
    // recordatorios exactos" (Android 12+). Sin el, las alarmas exactas se
    // degradan a inexactas y en Xiaomi/MIUI dejan de llegar a tiempo. No
    // bloquea nada si el usuario lo niega: las notificaciones seguiran, solo
    // que menos puntuales.
    try {
      await androidImpl.requestExactAlarmsPermission();
    } catch (_) {
      // En Android < 12 o si el fabricante no lo expone, se ignora.
    }
    return granted ?? false;
  }

  Future<bool> areNotificationsEnabled() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final enabled = await androidImpl?.areNotificationsEnabled();
    return enabled ?? false;
  }

  /// v29: `true` si la app se abrió (desde cero) por tocar un recordatorio
  /// de la hora. `main.dart` lo usa para llevar directo a la pantalla de
  /// "momento de oración".
  Future<bool> wasLaunchedByNotification() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp != true) return false;
      return details?.notificationResponse?.payload == kMomentoPayload;
    } catch (_) {
      return false;
    }
  }

  /// Cancela todo lo programado y vuelve a programar [_daysAhead] dias
  /// hacia adelante para cada horario en [times] (formato "HH:mm").
  Future<void> refreshSchedule(List<String> times) async {
    await init();
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);

    for (var slot = 0; slot < times.length; slot++) {
      final parts = times[slot].split(':');
      final hour = int.tryParse(parts[0]) ?? 7;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

      for (var dayOffset = 0; dayOffset < _daysAhead; dayOffset++) {
        var scheduled = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + dayOffset,
          hour,
          minute,
        );
        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }

        final variantIndex = (dayOffset + slot) % _mensajes.length;
        final id = slot * 1000 + dayOffset;

        await _plugin.zonedSchedule(
          id,
          'Ora Ahora',
          _mensajes[variantIndex],
          scheduled,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
          ),
         payload: kMomentoPayload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  /// Cancela todos los recordatorios programados (fijos y el "Recordatorio
  /// inteligente"). Se usa cuando la persona apaga el interruptor general
  /// de notificaciones en [RemindersScreen].
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Programa (o reprograma) el "Recordatorio inteligente" (ver
  /// `RemindersScreen`/`UsagePatternService`) para la proxima vez que
  /// llegue [hour] (hoy si aun no paso esa hora, o mañana si ya paso).
  /// Usa un ID fijo reservado ([_smartReminderBaseId]) que no choca con
  /// los recordatorios fijos de [refreshSchedule] (ver comentario junto a
  /// su declaracion), asi que reprogramar simplemente reemplaza el aviso
  /// inteligente anterior.
  Future<void> scheduleSmartReminder(int hour) async {
    await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _smartReminderBaseId,
      'Ora Ahora',
      _smartReminderMessage,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      payload: kMomentoPayload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancela unicamente el "Recordatorio inteligente" (sin afectar los
  /// recordatorios fijos), usado cuando la persona apaga ese interruptor
  /// especifico en `RemindersScreen` sin desactivar las notificaciones en
  /// general.
  Future<void> cancelSmartReminder() async {
    await _plugin.cancel(_smartReminderBaseId);
  }
}
