/// Estado de la racha (streak) de oracion del usuario.
///
/// Regla etica de "reparacion de racha": el usuario tiene 1 dia libre por
/// semana que no rompe la racha (a diferencia de rachas puramente punitivas).
/// La semana se calcula desde `weekStartIso` (lunes) hasta 6 dias despues.
///
/// Ademas del dia libre semanal (gratis para todos), los usuarios de
/// Ora Ahora Plus tienen un inventario de "fichas de congelacion"
/// (`freezeTokens`): un cupo mensual (ver `StreakService.freeTokensPerMonth`)
/// que se consume automaticamente cuando se pierde un dia Y ya no queda
/// dia libre semanal, evitando que se reinicie la racha. `cumulativeMinutes`
/// acumula los minutos estimados de todas las oraciones marcadas como
/// oradas a lo largo del tiempo (independientemente de si la racha se
/// reinicio o no), y alimenta el widget visual "Semilla/Arbol de fe".
///
/// v11: `minutesToday` + `minutesTodayDayKey` guardan los minutos orados
/// SOLO hoy (alimentan el "anillo de minutos del dia" de la pradera del
/// Salmo 23 en el inicio). `minutesTodayDayKey` es la fecha local
/// "yyyy-MM-dd" a la que pertenece el conteo: si al leer no coincide con
/// hoy, el conteo efectivo es 0 (ver `StreakService.minutesToday`). Ambos
/// campos son opcionales en el JSON, asi el estado guardado por versiones
/// anteriores sigue cargando sin migracion.
class StreakState {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastPrayedDate;
  final DateTime weekStart;
  final int missesUsedThisWeek;
  final int freezeTokens;
  final String? freezeTokensGrantMonthKey;
  final int cumulativeMinutes;

  /// Minutos orados en el dia indicado por [minutesTodayDayKey].
  final int minutesToday;

  /// Fecha local "yyyy-MM-dd" a la que pertenece [minutesToday], o `null`
  /// si nunca se registro un minuto diario (instalaciones previas a v11).
  final String? minutesTodayDayKey;

  /// Ultimo hito de racha (ver `StreakService.milestones`) que ya se
  /// celebro con la animacion del inicio, para que la celebracion se
  /// dispare una sola vez por hito alcanzado y no en cada apertura de la
  /// app (ver `StreakService.markPrayedToday`).
  final int lastCelebratedMilestone;

  const StreakState({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastPrayedDate,
    required this.weekStart,
    required this.missesUsedThisWeek,
    this.freezeTokens = 0,
    this.freezeTokensGrantMonthKey,
    this.cumulativeMinutes = 0,
    this.minutesToday = 0,
    this.minutesTodayDayKey,
    this.lastCelebratedMilestone = 0,
  });

  factory StreakState.initial() {
    return StreakState(
      currentStreak: 0,
      longestStreak: 0,
      lastPrayedDate: null,
      weekStart: _mondayOf(DateTime.now()),
      missesUsedThisWeek: 0,
      freezeTokens: 0,
      freezeTokensGrantMonthKey: null,
      cumulativeMinutes: 0,
      minutesToday: 0,
      minutesTodayDayKey: null,
      lastCelebratedMilestone: 0,
    );
  }

  static DateTime _mondayOf(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    return date.subtract(Duration(days: date.weekday - 1));
  }

  StreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastPrayedDate,
    DateTime? weekStart,
    int? missesUsedThisWeek,
    int? freezeTokens,
    String? freezeTokensGrantMonthKey,
    int? cumulativeMinutes,
    int? minutesToday,
    String? minutesTodayDayKey,
    int? lastCelebratedMilestone,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPrayedDate: lastPrayedDate ?? this.lastPrayedDate,
      weekStart: weekStart ?? this.weekStart,
      missesUsedThisWeek: missesUsedThisWeek ?? this.missesUsedThisWeek,
      freezeTokens: freezeTokens ?? this.freezeTokens,
      freezeTokensGrantMonthKey:
          freezeTokensGrantMonthKey ?? this.freezeTokensGrantMonthKey,
      cumulativeMinutes: cumulativeMinutes ?? this.cumulativeMinutes,
      minutesToday: minutesToday ?? this.minutesToday,
      minutesTodayDayKey: minutesTodayDayKey ?? this.minutesTodayDayKey,
      lastCelebratedMilestone:
          lastCelebratedMilestone ?? this.lastCelebratedMilestone,
    );
  }

  factory StreakState.fromJson(Map<String, dynamic> json) {
    return StreakState(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastPrayedDate: json['lastPrayedDate'] != null
          ? DateTime.parse(json['lastPrayedDate'] as String)
          : null,
      weekStart: json['weekStart'] != null
          ? DateTime.parse(json['weekStart'] as String)
          : _mondayOf(DateTime.now()),
      missesUsedThisWeek: json['missesUsedThisWeek'] as int? ?? 0,
      freezeTokens: json['freezeTokens'] as int? ?? 0,
      freezeTokensGrantMonthKey: json['freezeTokensGrantMonthKey'] as String?,
      cumulativeMinutes: json['cumulativeMinutes'] as int? ?? 0,
      minutesToday: json['minutesToday'] as int? ?? 0,
      minutesTodayDayKey: json['minutesTodayDayKey'] as String?,
      lastCelebratedMilestone: json['lastCelebratedMilestone'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastPrayedDate': lastPrayedDate?.toIso8601String(),
      'weekStart': weekStart.toIso8601String(),
      'missesUsedThisWeek': missesUsedThisWeek,
      'freezeTokens': freezeTokens,
      'freezeTokensGrantMonthKey': freezeTokensGrantMonthKey,
      'cumulativeMinutes': cumulativeMinutes,
      'minutesToday': minutesToday,
      'minutesTodayDayKey': minutesTodayDayKey,
      'lastCelebratedMilestone': lastCelebratedMilestone,
    };
  }
}
