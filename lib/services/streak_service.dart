import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/streak.dart';
import 'prefs_service.dart';

/// Gestiona la racha (streak) de dias orando, con una regla etica de
/// "reparacion de racha": 1 dia perdido por semana no rompe la racha,
/// a diferencia de las rachas puramente punitivas de otras apps.
///
/// Ademas, los usuarios de Ora Ahora Plus reciben un cupo mensual de
/// "fichas de congelación" (`freezeTokens`, ver [freeTokensPerMonth]) que
/// se consumen automáticamente cuando se pierde un día y ya no queda día
/// libre semanal disponible, en vez de reiniciar la racha a 1. Es una
/// extensión del mismo espíritu de "retención ética" del día libre
/// gratuito: nunca castiga con dureza, solo da un margen extra a quienes
/// apoyan la app.
///
/// v11: ademas de `cumulativeMinutes` (total historico, alimenta el arbol
/// de fe), se lleva `minutesToday` (minutos orados SOLO hoy) para el
/// anillo de minutos del dia en la pradera del Salmo 23 del inicio.
class StreakService extends ChangeNotifier {
  final PrefsService _prefs;
  late StreakState _state;

  StreakService(this._prefs) {
    _state = _load();
  }

  /// Fichas de congelación otorgadas cada mes nuevo a los usuarios Plus.
  static const int freeTokensPerMonth = 2;

  /// Tope maximo de fichas acumulables (evita que se acumulen
  /// indefinidamente si el usuario no las usa durante muchos meses).
  static const int maxFreezeTokens = 4;

  /// Hitos de racha (en dias) que disparan una celebracion breve en el
  /// inicio (ver `HomeScreen`/`_MilestoneCelebrationOverlay`). Elegidos
  /// para sentirse alcanzables al principio (3, 7) y cada vez mas
  /// espaciados despues, sin exigir nada artificial.
  static const List<int> milestones = [3, 7, 14, 30, 60, 100, 200, 365];

  /// Hito pendiente de celebrar (recien alcanzado por `markPrayedToday`),
  /// o `null` si no hay ninguno esperando a mostrarse. Es deliberadamente
  /// un campo en memoria (no persistido) distinto de
  /// `StreakState.lastCelebratedMilestone`: este ultimo si se persiste,
  /// para no volver a celebrar el mismo hito en aperturas futuras de la
  /// app aunque la animacion no llegara a mostrarse (p. ej. la app se
  /// cerro justo despues de orar).
  int? _pendingMilestone;
  int? get pendingMilestone => _pendingMilestone;

  /// Se llama desde la UI (`HomeScreen`) justo despues de mostrar la
  /// celebracion, para no volver a dispararla.
  void acknowledgeMilestoneShown() {
    _pendingMilestone = null;
  }

  /// Mensaje breve en español para mostrar junto a la celebracion de
  /// [milestone] dias de racha.
  static String milestoneMessage(int milestone) {
    switch (milestone) {
      case 3:
        return '¡3 días orando seguidos! Un buen comienzo.';
      case 7:
        return '¡7 días orando seguidos! Dios ve tu constancia.';
      case 14:
        return '¡14 días seguidos! Estás formando un hábito hermoso.';
      case 30:
        return '¡30 días orando seguidos! Un mes entero buscando a Dios.';
      case 60:
        return '¡60 días seguidos! Tu fidelidad es un testimonio.';
      case 100:
        return '¡100 días orando seguidos! Una racha extraordinaria.';
      case 200:
        return '¡200 días seguidos! Dios ha estado contigo cada uno de ellos.';
      case 365:
        return '¡Un año entero orando cada día! Qué fidelidad.';
      default:
        return '¡$milestone días orando seguidos!';
    }
  }

  StreakState get state => _state;

  int get currentStreak => _state.currentStreak;
  int get longestStreak => _state.longestStreak;
  int get freezeTokens => _state.freezeTokens;
  int get cumulativeMinutes => _state.cumulativeMinutes;
  bool get hasGraceAvailableThisWeek => _state.missesUsedThisWeek < 1;

  /// Minutos orados HOY (para el anillo de minutos del dia de la pradera).
  /// Si el conteo guardado pertenece a otro dia, vale 0 sin necesidad de
  /// escribir nada (el proximo minuto orado ya se guarda con la fecha de
  /// hoy, ver [_minutesTodayPlus]).
  int get minutesToday {
    if (_state.minutesTodayDayKey != _dayKeyOf(DateTime.now())) return 0;
    return _state.minutesToday;
  }

  bool get prayedToday {
    final last = _state.lastPrayedDate;
    if (last == null) return false;
    return _isSameDay(last, DateTime.now());
  }

  StreakState _load() {
    final raw = _prefs.streakStateJson;
    if (raw == null) return StreakState.initial();
    try {
      return StreakState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return StreakState.initial();
    }
  }

  Future<void> _save() async {
    await _prefs.setStreakStateJson(jsonEncode(_state.toJson()));
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _isSameDay(DateTime a, DateTime b) {
    final da = _dateOnly(a);
    final db = _dateOnly(b);
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }

  static DateTime _mondayOf(DateTime d) {
    final date = _dateOnly(d);
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static String _monthKeyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  /// Fecha local "yyyy-MM-dd" (clave del conteo de minutos diarios).
  static String _dayKeyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int _minInt(int a, int b) => a < b ? a : b;

  /// Conteo de minutos de hoy despues de sumar [minutes] en el instante
  /// [now]: continua el conteo si el guardado es de hoy, o arranca de
  /// cero si es de otro dia.
  int _minutesTodayPlus(int minutes, DateTime now) {
    final key = _dayKeyOf(now);
    return _state.minutesTodayDayKey == key
        ? _state.minutesToday + minutes
        : minutes;
  }

  /// Si comenzo un mes calendario nuevo desde el ultimo otorgamiento,
  /// suma [freeTokensPerMonth] fichas (solo si [isPlusUser]), respetando
  /// el tope [maxFreezeTokens]. No hace nada si ya se otorgo este mes.
  void _rolloverFreezeTokensIfNeeded(DateTime now, {required bool isPlusUser}) {
    final monthKey = _monthKeyOf(now);
    if (_state.freezeTokensGrantMonthKey == monthKey) return;

    final grantedTokens = isPlusUser
        ? _minInt(_state.freezeTokens + freeTokensPerMonth, maxFreezeTokens)
        : _state.freezeTokens;

    _state = _state.copyWith(
      freezeTokens: grantedTokens,
      freezeTokensGrantMonthKey: monthKey,
    );
  }

  /// Comprueba si corresponde otorgar el cupo mensual de fichas de
  /// congelación (sin necesidad de que el usuario ore hoy), para que la
  /// insignia de racha muestre el conteo correcto apenas se abre la app.
  Future<void> refreshFreezeTokens({required bool isPlusUser}) async {
    final before = _state.freezeTokens;
    final beforeKey = _state.freezeTokensGrantMonthKey;
    _rolloverFreezeTokensIfNeeded(DateTime.now(), isPlusUser: isPlusUser);
    if (_state.freezeTokens == before &&
        _state.freezeTokensGrantMonthKey == beforeKey) {
      return;
    }
    await _save();
    notifyListeners();
  }

  /// Marca el dia de hoy como orado y recalcula la racha.
  ///
  /// Reglas:
  /// - Si ya se marco hoy, no hace nada (evita doble conteo).
  /// - Si el ultimo dia orado fue ayer, la racha sube en 1.
  /// - Si el ultimo dia orado fue hace 2 dias (se salto exactamente 1 dia):
  ///   1. Si todavia queda el "dia libre" semanal (gratis, todos los
  ///      usuarios), la racha se mantiene y se consume ese dia libre.
  ///   2. Si no, y el usuario es Plus y tiene fichas de congelación
  ///      disponibles, la racha tambien se mantiene y se consume 1 ficha.
  /// - En cualquier otro caso (mas de 1 dia salteado, o sin dia libre ni
  ///   fichas), la racha se reinicia a 1.
  /// - `cumulativeMinutes` suma [minutes] cada vez que se marca un dia
  ///   nuevo como orado (sin importar si la racha continuo o se reinicio),
  ///   y alimenta el widget "Semilla/Arbol de fe". `minutesToday` suma
  ///   los mismos minutos al conteo del dia (anillo de la pradera, v11).
  Future<void> markPrayedToday({
    required bool isPlusUser,
    required int minutes,
  }) async {
    if (prayedToday) return;

    final now = DateTime.now();
    final today = _dateOnly(now);

    _rolloverFreezeTokensIfNeeded(now, isPlusUser: isPlusUser);

    var weekStart = _state.weekStart;
    var missesUsedThisWeek = _state.missesUsedThisWeek;
    if (now.isAfter(weekStart.add(const Duration(days: 7)))) {
      weekStart = _mondayOf(now);
      missesUsedThisWeek = 0;
    }

    final last = _state.lastPrayedDate;
    var freezeTokens = _state.freezeTokens;
    int newStreak;

    if (last == null) {
      newStreak = 1;
    } else {
      final daysSince = today.difference(_dateOnly(last)).inDays;
      if (daysSince == 1) {
        newStreak = _state.currentStreak + 1;
      } else if (daysSince == 2 && missesUsedThisWeek < 1) {
        // Dia libre semanal gratuito: la racha se mantiene.
        missesUsedThisWeek += 1;
        newStreak = _state.currentStreak + 1;
      } else if (daysSince == 2 && isPlusUser && freezeTokens > 0) {
        // Sin dia libre disponible, pero el usuario Plus tiene una ficha
        // de congelacion: se consume 1 y la racha se mantiene.
        freezeTokens -= 1;
        newStreak = _state.currentStreak + 1;
      } else {
        // Se saltaron mas de 1 dia, o no queda dia libre ni ficha: la
        // racha se reinicia (nunca por debajo de 1, ya que hoy se oro).
        newStreak = 1;
      }
    }

    final newLongest =
        newStreak > _state.longestStreak ? newStreak : _state.longestStreak;
    final newCumulativeMinutes = _state.cumulativeMinutes + minutes;

    // Si se acaba de alcanzar un nuevo hito (ver [milestones]) que todavia
    // no se habia celebrado, se deja pendiente para que la UI del inicio
    // dispare la animacion (ver `pendingMilestone`/`acknowledgeMilestoneShown`).
    var newLastCelebratedMilestone = _state.lastCelebratedMilestone;
    for (final milestone in milestones) {
      if (newStreak >= milestone && _state.lastCelebratedMilestone < milestone) {
        _pendingMilestone = milestone;
        newLastCelebratedMilestone = milestone;
      }
    }

    _state = _state.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastPrayedDate: today,
      weekStart: weekStart,
      missesUsedThisWeek: missesUsedThisWeek,
      freezeTokens: freezeTokens,
      cumulativeMinutes: newCumulativeMinutes,
      minutesToday: _minutesTodayPlus(minutes, now),
      minutesTodayDayKey: _dayKeyOf(now),
      lastCelebratedMilestone: newLastCelebratedMilestone,
    );

    await _save();
    notifyListeners();
  }

  /// Suma minutos de oraciones ADICIONALES del mismo dia (la racha no
  /// cambia, pero el arbol de fe sigue creciendo — orar mas veces al dia
  /// siempre suma). Tambien alimenta el anillo de minutos del dia (v11).
  Future<void> addExtraMinutes(int minutes) async {
    if (minutes <= 0) return;
    final now = DateTime.now();
    _state = _state.copyWith(
      cumulativeMinutes: _state.cumulativeMinutes + minutes,
      minutesToday: _minutesTodayPlus(minutes, now),
      minutesTodayDayKey: _dayKeyOf(now),
    );
    await _save();
    notifyListeners();
  }

  /// `true` si la racha corre riesgo de perderse si la persona no ora hoy
  /// (ya paso al menos un dia completo desde la ultima vez que oro). Se usa
  /// para resaltar visualmente la pradera del inicio.
  bool get streakAtRisk {
    if (currentStreak == 0 || prayedToday) return false;
    final last = _state.lastPrayedDate;
    if (last == null) return false;
    final daysSince =
        _dateOnly(DateTime.now()).difference(_dateOnly(last)).inDays;
    return daysSince >= 1;
  }

  /// Dias completos desde la ultima oracion (0 = oro hoy), o `null` si
  /// nunca ha orado. 2+ dias = momento "oveja perdida" (Lucas 15): la
  /// pradera y las notificaciones reciben a la persona con gracia,
  /// nunca con culpa.
  int? get daysSinceLastPrayed {
    final last = _state.lastPrayedDate;
    if (last == null) return null;
    return _dateOnly(DateTime.now()).difference(_dateOnly(last)).inDays;
  }
}
