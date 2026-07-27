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

  // v30: la notificación es EXPANDIBLE. Colapsada muestra una invitación
  // corta (_nudges); al desplegarla, una oración corta (_oracionesNotif)
  // que se puede leer/orar en la pantalla de bloqueo. Ambas rotan. Voz del
  // ICP, lenguaje NEUTRO (no asume género), con gracia (nunca condena).
  static const List<String> _nudges = [
    'es tu momento con Dios 🙏',
    '¿un minuto con Dios antes del scroll? 🙏',
    'Él te espera, sin reproches 🙏',
    'para esto sí hay tiempo 🙏',
    '¿ya le hablaste a Dios hoy?',
    'un ratito con Él cambia el día 🌱',
    'antes del celu, un momento con Dios 🙏',
    'Dios te extraña. ven un momento 🤍',
    'tu cita de hoy con Dios te espera',
    'para un minuto y háblale a Dios',
    'hoy no lo dejes para el final 🙏',
    'vuelve a lo que de verdad importa',
    'es tu momento, no lo dejes pasar 🙏',
    'Dios está, aunque no lo sientas',
    'un minuto con Él vale más que mil videos',
    '"aquí estoy, ven a hablar conmigo" — Dios',
  ];

  static const List<String> _oracionesNotif = [
    'Señor, aquí estoy. antes que nada y antes que nadie, quiero buscarte a ti. gracias por esperarme. Amén.',
    'Dios, este ratito es tuyo. calma lo que traigo por dentro y recuérdame que estás cerca. Amén.',
    'Padre, gracias por hoy. ayúdame a no dejarte para el final del día. quiero volver a ti. Amén.',
    'Jesús, sé que me distraigo fácil. hoy elijo parar un momento y hablarte. gracias por escucharme. Amén.',
    'Señor, no traigo palabras bonitas, solo mi corazón. quédate conmigo en lo que venga hoy. Amén.',
    'Dios, gracias porque no te cansas de mí. dame paz y guíame en lo de hoy. Amén.',
    'Padre, aquí me tienes otra vez. gracias por recibirme sin reproches. te necesito. Amén.',
    'Señor, ordena mi día y mi mente. que lo primero seas tú, no la pantalla. Amén.',
    'Señor, gracias por este día. quiero dártelo a ti antes que a nada. Amén.',
    'Dios, cuando quiera huir a la pantalla, recuérdame que tú me llenas. Amén.',
    'Padre, calma mi cabeza. hoy quiero caminar contigo. Amén.',
    'Jesús, perdona que te dejo para el final. hoy empiezo por ti. Amén.',
    'Señor, aquí traigo mi cansancio. dame del descanso bueno. Amén.',
    'Dios, gracias por no soltarme aunque yo te suelte. Amén.',
    'Padre, quiero volver a sentirte cerca. ábreme el corazón. Amén.',
    'Señor, que hoy busque tu voz más que las notificaciones. Amén.',
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

        final vi = dayOffset + slot;
        final nudge = _nudges[vi % _nudges.length];
        final oracion = _oracionesNotif[vi % _oracionesNotif.length];
        final id = slot * 1000 + dayOffset;

        await _plugin.zonedSchedule(
          id,
          nudge,
          'toca para orar tu momento de hoy 🌱',
          scheduled,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              styleInformation: BigTextStyleInformation(
                oracion,
                contentTitle: nudge,
                summaryText: 'Ora Ahora',
              ),
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
