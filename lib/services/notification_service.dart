import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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
      'En unos minutos sueles abrir el teléfono para distraerte. '
      '¿Oramos primero?';

  static const List<String> _mensajes = [
    'Un minuto para respirar y poner tu día en manos de Dios.',
    '¿Y si haces una pausa ahora mismo para orar?',
    'Este es un buen momento para agradecer algo pequeño.',
    'Tu oración de hoy te está esperando en Ora Ahora.',
    'Una pausa breve, una oración sincera. Vamos.',
    'Antes de seguir con el día, respira y ora un momento.',
    'No tienes que decir mucho. Solo abre tu corazón un momento.',
    'Hoy también puedes elegir la calma antes que la prisa.',
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
    await _plugin.initialize(initSettings);

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
