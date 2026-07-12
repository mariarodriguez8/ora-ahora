import 'dart:convert';

import 'prefs_service.dart';

/// Analiza el registro de aperturas de apps "gateadas" para sugerir un
/// horario adicional de recordatorio basado en el habito real de la
/// persona, en vez de solo horarios fijos elegidos a mano.
///
/// El registro (`PrefsKeys.usagePatternLog`) lo escribe de forma nativa
/// `PrayerGateAccessibilityService.kt` cada vez que detecta la apertura de
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
