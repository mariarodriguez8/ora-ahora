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
class StreakState {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastPrayedDate;
  final DateTime weekStart;
  final int missesUsedThisWeek;
  final int freezeTokens;
  final String? freezeTokensGrantMonthKey;
  final int cumulativeMinutes;

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
      'lastCelebratedMilestone': lastCelebratedMilestone,
    };
  }
}