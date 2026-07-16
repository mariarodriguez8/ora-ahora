#!/usr/bin/env bash
# apply_v11b.sh — ORA AHORA v11b: expresiones de la ovejita integradas.
#  - Descarga las 4 expresiones oficiales (celebrando, esperando,
#    escuchando -solo cabeza-, perdida) a assets/mascot/ y las recorta.
#  - Pradera: la ovejita cambia de expresion segun el momento del dia.
#  - Hito de racha: la ovejita celebra contigo (reemplaza icono generico).
#  - Pantalla de voz: la cabeza de la ovejita asoma abajo, escuchando.
#  - pubspec: assets/mascot/ como carpeta.
# Autocontenido e idempotente.
set -euo pipefail
cd "$(dirname "$0")"
if [ ! -f pubspec.yaml ]; then
  echo "ERROR: ejecuta este script desde la raiz del repo" >&2
  exit 1
fi

mkdir -p assets/mascot
dl() { if [ ! -s "$2" ]; then wget -q "$1" -O "$2"; echo "descargado: $2"; else echo "ya existe: $2"; fi; }
dl "https://d8j0ntlcm91z4.cloudfront.net/user_357fcxDIqY9TMqfewNOAYaGunxR/hf_20260716_044850_8e8fd637-fdc5-44fa-90bc-89740a5801e0.png" "assets/mascot/ovejita_celebrando.png"
dl "https://d8j0ntlcm91z4.cloudfront.net/user_357fcxDIqY9TMqfewNOAYaGunxR/hf_20260716_044854_b49a19aa-67f8-4b04-80e9-8be5cc77a08e.png" "assets/mascot/ovejita_esperando.png"
dl "https://d8j0ntlcm91z4.cloudfront.net/user_357fcxDIqY9TMqfewNOAYaGunxR/hf_20260716_044902_b77584ca-5f57-409c-ada9-c5284951be6c.png" "assets/mascot/ovejita_escuchando.png"
dl "https://d8j0ntlcm91z4.cloudfront.net/user_357fcxDIqY9TMqfewNOAYaGunxR/hf_20260716_044906_026e987e-86d9-4873-a013-3b54bb6fee5f.png" "assets/mascot/ovejita_perdida.png"

# Recorte al contenido + reescalado a 512px (mejor tamano de APK). Si no
# hay Pillow y no se puede instalar, se quedan las imagenes originales
# (funcionan igual, solo pesan mas).
python3 -c "import PIL" 2>/dev/null || pip3 install pillow --quiet 2>/dev/null || true
python3 - <<'EOF_IMG' || echo "AVISO: no se pudo recortar (Pillow ausente); se usan las imagenes tal cual"
from PIL import Image
import os
for name in ['ovejita_celebrando','ovejita_esperando','ovejita_escuchando','ovejita_perdida']:
    p = f'assets/mascot/{name}.png'
    im = Image.open(p).convert('RGBA')
    if im.width <= 512:
        continue
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
    im.thumbnail((512, 512), Image.LANCZOS)
    im.save(p, optimize=True)
    print('recortada:', p, im.size, os.path.getsize(p)//1024, 'KB')
EOF_IMG

mkdir -p "$(dirname pubspec.yaml)"
cat > pubspec.yaml <<'EOF_PUBSPEC_YAML'
name: ora_ahora
description: "Ora Ahora - pausa, ora y enfoca. App de oracion cristiana interdenominacional en espanol con pausa de oracion antes de abrir apps que distraen."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2
  shared_preferences: ^2.2.3
  flutter_local_notifications: ^17.2.2
  timezone: ^0.9.4
  flutter_timezone: ^5.1.0
  path_provider: ^2.1.4
  intl: ^0.20.2
  device_apps: ^2.2.0
  uuid: ^4.4.0
  speech_to_text: ^7.0.0
  flutter_svg: ^2.0.10+1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/data/prayers_es.json
    # v11b: carpeta completa de la mascota (ovejita.png + expresiones
    # celebrando / esperando / escuchando / perdida, derivadas del
    # personaje oficial).
    - assets/mascot/
    - assets/illustrations/onboarding_hero.svg
    - assets/illustrations/tree_semilla.svg
    - assets/illustrations/tree_brote.svg
    - assets/illustrations/tree_planta_joven.svg
    - assets/illustrations/tree_arbol.svg
    - assets/illustrations/journal_empty.svg
    - assets/illustrations/paywall_hero.svg

  fonts:
    - family: Fraunces
      fonts:
        - asset: assets/fonts/Fraunces9pt-Regular.ttf
          weight: 400
        - asset: assets/fonts/Fraunces9pt-Italic.ttf
          weight: 400
          style: italic
        - asset: assets/fonts/Fraunces72ptSoft-SemiBold.ttf
          weight: 600
    - family: Figtree
      fonts:
        - asset: assets/fonts/Figtree-Regular.ttf
          weight: 400
        - asset: assets/fonts/Figtree-Medium.ttf
          weight: 500
        - asset: assets/fonts/Figtree-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Figtree-Bold.ttf
          weight: 700
        - asset: assets/fonts/Figtree-ExtraBold.ttf
          weight: 800
EOF_PUBSPEC_YAML

mkdir -p "$(dirname lib/models/streak.dart)"
cat > lib/models/streak.dart <<'EOF_LIB_MODELS_STREAK_DART'
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
EOF_LIB_MODELS_STREAK_DART

mkdir -p "$(dirname lib/services/streak_service.dart)"
cat > lib/services/streak_service.dart <<'EOF_LIB_SERVICES_STREAK_SERVICE_DART'
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
EOF_LIB_SERVICES_STREAK_SERVICE_DART

mkdir -p "$(dirname lib/widgets/meadow_hero.dart)"
cat > lib/widgets/meadow_hero.dart <<'EOF_LIB_WIDGETS_MEADOW_HERO_DART'
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_typography.dart';
import 'faith_tree_widget.dart';

/// v11 — "Tu caminar con el Pastor".
///
/// Hero del inicio: la pradera del Salmo 23 pintada a mano (cielo de
/// amanecer, colinas, arroyo y flores que van floreciendo con los minutos
/// orados), con el numero GIGANTE de racha como protagonista y el anillo
/// de minutos del dia. El arbol de fe vive dentro de la pradera (misma
/// logica de etapas de siempre, ver `FaithTreeStages`) y la ovejita — que
/// eres tu (Juan 10:27), siempre feliz — camina junto al arroyo.
///
/// Estilo "Santuario energizado": TODOS los colores derivan del
/// `ColorScheme` activo, asi la pradera se ve coherente en las 4 paletas
/// (incluida "Vigilia" oscura, donde el amanecer es mas tenue). No se
/// agrega ningun asset nuevo: la escena es un `CustomPainter` + los SVG
/// del arbol y el PNG de la mascota que ya existen.
class MeadowHero extends StatelessWidget {
  final int streak;
  final bool atRisk;
  final bool prayedToday;
  final int minutesToday;
  final int cumulativeMinutes;

  /// `true` cuando pasaron 2+ dias sin orar (la "oveja perdida" de
  /// Lucas 15): la pradera recibe con gracia, nunca con culpa.
  final bool sheepLost;

  /// Fichas de congelacion visibles (solo usuarios Plus con fichas > 0),
  /// o `null` para no mostrar nada.
  final int? freezeTokens;

  const MeadowHero({
    super.key,
    required this.streak,
    required this.atRisk,
    required this.prayedToday,
    required this.minutesToday,
    required this.cumulativeMinutes,
    this.sheepLost = false,
    this.freezeTokens,
  });

  /// Meta suave de minutos diarios para el anillo. No es un castigo: al
  /// llegar, el anillo simplemente se completa; nunca se muestra en rojo
  /// ni genera culpa (racha rota = oveja perdida que se celebra al volver,
  /// nunca se regana).
  static const int dailyGoalMinutes = 10;

  String get _statusMessage {
    if (prayedToday) return 'Hoy ya caminaste con Él ✨';
    if (sheepLost) return 'Él deja las 99 y viene por ti 💛';
    if (atRisk && streak > 0) return 'El Pastor te espera hoy 🌿';
    return '«En verdes pastos me hace descansar»';
  }

  /// Expresion de la ovejita segun el momento: celebrando si ya oro,
  /// "oveja perdida" (mirando hacia atras, esperanzada) si pasaron 2+
  /// dias, esperando si la racha esta en riesgo, y caminando feliz el
  /// resto del tiempo. Todas derivan del personaje oficial.
  String get _mascotAsset {
    if (prayedToday) return 'assets/mascot/ovejita_celebrando.png';
    if (sheepLost) return 'assets/mascot/ovejita_perdida.png';
    if (atRisk && streak > 0) return 'assets/mascot/ovejita_esperando.png';
    return 'assets/mascot/ovejita.png';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stage = FaithTreeStages.stageFor(cumulativeMinutes);
    final double treeSize;
    switch (stage) {
      case FaithTreeStage.semilla:
        treeSize = 34;
        break;
      case FaithTreeStage.brote:
        treeSize = 46;
        break;
      case FaithTreeStage.plantaJoven:
        treeSize = 62;
        break;
      case FaithTreeStage.arbol:
        treeSize = 82;
        break;
    }

    return Semantics(
      label: 'Racha: $streak dias caminando con el Pastor. '
          '$minutesToday minutos orados hoy.',
      child: Container(
        height: 330,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _MeadowPainter(
                scheme: scheme,
                cumulativeMinutes: cumulativeMinutes,
              ),
            ),
            // Arbol de fe sobre la colina derecha: crece con los minutos
            // acumulados, igual que siempre, pero ahora vive en la pradera.
            Positioned(
              right: 26,
              bottom: 96,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 520),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: SvgPicture.asset(
                  FaithTreeStages.illustrationFor(stage),
                  key: ValueKey(stage),
                  width: treeSize,
                  height: treeSize,
                ),
              ),
            ),
            // La ovejita (eres tu, siempre feliz) junto al arroyo, con
            // la expresion del momento (celebrando / esperando / perdida
            // que vuelve / caminando). El cambio se anima suave.
            Positioned(
              left: 20,
              bottom: 12,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Image.asset(
                  _mascotAsset,
                  key: ValueKey(_mascotAsset),
                  height: 66,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Contenido principal: overline + numero gigante + etiqueta +
            // mensaje de estado (sin culpa, siempre invitacion).
            Positioned(
              top: 18,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Text(
                    'TU CAMINAR CON EL PASTOR',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: scheme.secondary,
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Text(
                      '$streak',
                      style: AppTypography.display.copyWith(
                        fontSize: 96,
                        height: 1.05,
                        color: scheme.primary,
                        shadows: [
                          Shadow(
                            color: scheme.surface.withValues(alpha: 0.65),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    streak == 0
                        ? 'Hoy puede ser tu primer paso'
                        : streak == 1
                            ? 'día caminando con el Pastor'
                            : 'días caminando con el Pastor',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: AppTypography.quote.copyWith(
                        fontSize: 13.5,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Anillo de minutos del dia (abajo a la derecha, sobre la
            // pradera, sin competir con el numero gigante).
            Positioned(
              right: 18,
              bottom: 14,
              child: _MinutesRing(
                minutes: minutesToday,
                goal: dailyGoalMinutes,
              ),
            ),
            if (freezeTokens != null)
              Positioned(
                right: 14,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.ac_unit, size: 14, color: scheme.primary),
                      const SizedBox(width: 3),
                      Text(
                        '$freezeTokens',
                        style: AppTypography.caption.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Anillo de minutos orados hoy: progreso dorado sobre una pastilla
/// circular semitransparente, con el numero al centro.
class _MinutesRing extends StatelessWidget {
  final int minutes;
  final int goal;

  const _MinutesRing({required this.minutes, required this.goal});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = goal <= 0 ? 0.0 : (minutes / goal).clamp(0.0, 1.0);
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          trackColor: scheme.primary.withValues(alpha: 0.14),
          progressColor: scheme.secondary,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$minutes',
                style: AppTypography.title.copyWith(
                  fontSize: 21,
                  height: 1.0,
                  color: scheme.primary,
                ),
              ),
              Text(
                'min hoy',
                style: AppTypography.caption.copyWith(
                  fontSize: 8.5,
                  letterSpacing: 0.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);
    if (progress > 0) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = progressColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}

/// Pinta la escena de la pradera del Salmo 23: cielo de amanecer, sol
/// suave, colinas, arroyo ("junto a aguas de reposo") y flores/pasto que
/// florecen de forma determinista con los minutos acumulados de oracion.
class _MeadowPainter extends CustomPainter {
  final ColorScheme scheme;
  final int cumulativeMinutes;

  _MeadowPainter({required this.scheme, required this.cumulativeMinutes});

  bool get _isDark => scheme.brightness == Brightness.dark;

  /// Pseudoaleatorio determinista (misma pradera en cada frame, sin
  /// necesidad de estado): fraccion de un seno escalado, patron clasico.
  double _rand(int i, int salt) {
    final v = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  /// X aproximada del centro del arroyo a una altura dada (para no pintar
  /// flores ni pasto encima del agua).
  double _streamXAt(double y, double w, double h, double horizonY) {
    final t = ((y - horizonY) / (h - horizonY)).clamp(0.0, 1.0);
    return w * (0.60 - 0.46 * t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizonY = h * 0.46;

    // 1. Cielo de amanecer (en "Vigilia" oscura, un alba tenue).
    final skyTop = _isDark
        ? scheme.surface
        : Color.lerp(scheme.surface, scheme.primaryContainer, 0.30)!;
    final skyHorizon = _isDark
        ? Color.lerp(scheme.surface, scheme.secondaryContainer, 0.45)!
        : Color.lerp(scheme.surface, scheme.tertiaryContainer, 0.75)!;
    final skyRect = Rect.fromLTWH(0, 0, w, horizonY + h * 0.08);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyHorizon],
        ).createShader(skyRect),
    );

    // 2. Sol de amanecer con halo dorado suave.
    final sunCenter = Offset(w * 0.78, horizonY * 0.60);
    canvas.drawCircle(
      sunCenter,
      w * 0.22,
      Paint()
        ..shader = RadialGradient(
          colors: [
            scheme.secondary.withValues(alpha: _isDark ? 0.32 : 0.42),
            scheme.secondary.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: w * 0.22)),
    );
    canvas.drawCircle(
      sunCenter,
      w * 0.05,
      Paint()
        ..color = Color.lerp(
          scheme.secondary,
          scheme.surface,
          _isDark ? 0.15 : 0.55,
        )!,
    );

    // 3. Colina lejana.
    final farHill = Path()
      ..moveTo(0, horizonY + h * 0.02)
      ..quadraticBezierTo(w * 0.30, horizonY - h * 0.075, w * 0.62, horizonY)
      ..quadraticBezierTo(w * 0.85, horizonY + h * 0.04, w, horizonY + h * 0.01)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      farHill,
      Paint()
        ..color = Color.lerp(
          scheme.primaryContainer,
          scheme.tertiary,
          _isDark ? 0.35 : 0.30,
        )!
            .withValues(alpha: 0.85),
    );

    // 4. Pradera principal.
    final meadowColor = _isDark
        ? Color.lerp(scheme.primaryContainer, scheme.surface, 0.25)!
        : Color.lerp(scheme.primaryContainer, scheme.tertiary, 0.45)!;
    final meadow = Path()
      ..moveTo(0, horizonY + h * 0.10)
      ..quadraticBezierTo(
        w * 0.42,
        horizonY + h * 0.015,
        w,
        horizonY + h * 0.085,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(meadow, Paint()..color = meadowColor);

    // 5. Arroyo: "junto a aguas de reposo me pastoreara".
    final streamBase = Color.lerp(
      scheme.primaryContainer,
      _isDark ? scheme.surface : Colors.white,
      _isDark ? 0.10 : 0.45,
    )!;
    final streamColor = Color.alphaBlend(const Color(0x3D2E6F86), streamBase);
    final streamPath = Path()
      ..moveTo(w * 0.60, horizonY + h * 0.055)
      ..cubicTo(w * 0.50, h * 0.66, w * 0.44, h * 0.72, w * 0.30, h * 0.82)
      ..cubicTo(w * 0.22, h * 0.88, w * 0.16, h * 0.93, w * 0.12, h);
    canvas.drawPath(
      streamPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.085
        ..strokeCap = StrokeCap.round
        ..color = streamColor,
    );
    canvas.drawPath(
      streamPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.028
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: _isDark ? 0.18 : 0.50),
    );

    // 6. Flores: la pradera FLORECE con los minutos orados (cada ~12 min
    // acumulados brota una flor nueva, hasta un maximo sereno).
    final flowerCount = (3 + cumulativeMinutes ~/ 12).clamp(3, 44);
    final petalGold = scheme.secondary;
    final petalLight = _isDark
        ? scheme.onSurface.withValues(alpha: 0.85)
        : Colors.white;
    for (var i = 0; i < flowerCount; i++) {
      final fx = _rand(i, 1) * w;
      final fy = h * (0.62 + _rand(i, 2) * 0.34);
      if ((fx - _streamXAt(fy, w, h, horizonY)).abs() < w * 0.07) continue;
      final r = 1.6 + _rand(i, 3) * 1.8;
      final color = i.isEven ? petalGold : petalLight;
      final center = Offset(fx, fy);
      for (var p = 0; p < 5; p++) {
        final ang = p * 2 * math.pi / 5;
        canvas.drawCircle(
          center + Offset(math.cos(ang), math.sin(ang)) * r,
          r * 0.62,
          Paint()..color = color.withValues(alpha: 0.9),
        );
      }
      canvas.drawCircle(
        center,
        r * 0.55,
        Paint()..color = i.isEven ? petalLight : petalGold,
      );
    }

    // 7. Matitas de pasto para dar textura a la pradera.
    final grassPaint = Paint()
      ..color = Color.lerp(meadowColor, scheme.primary, 0.35)!
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 26; i++) {
      final gx = _rand(i, 7) * w;
      final gy = h * (0.60 + _rand(i, 8) * 0.36);
      if ((gx - _streamXAt(gy, w, h, horizonY)).abs() < w * 0.06) continue;
      final blade = 4.0 + _rand(i, 9) * 5.0;
      canvas.drawLine(
        Offset(gx, gy),
        Offset(gx - blade * 0.35, gy - blade),
        grassPaint,
      );
      canvas.drawLine(
        Offset(gx, gy),
        Offset(gx + blade * 0.40, gy - blade * 0.8),
        grassPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MeadowPainter oldDelegate) =>
      oldDelegate.scheme != scheme ||
      oldDelegate.cumulativeMinutes != cumulativeMinutes;
}
EOF_LIB_WIDGETS_MEADOW_HERO_DART

mkdir -p "$(dirname lib/screens/home/home_screen.dart)"
cat > lib/screens/home/home_screen.dart <<'EOF_LIB_SCREENS_HOME_HOME_SCREEN_DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../services/community_stats_service.dart';
import '../../services/prayer_repository.dart';
import '../../services/prefs_service.dart';
import '../../services/purchase_service.dart';
import '../../services/route_observer.dart';
import '../../services/streak_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/meadow_hero.dart';
import '../../widgets/prayer_card.dart';
import '../journal/journal_screen.dart';
import '../paywall/paywall_screen.dart';
import '../prayer_detail/prayer_detail_screen.dart';
import '../settings/settings_screen.dart';

/// Contenedor principal de la app despues del onboarding: pestañas de
/// Inicio, Diario y Ajustes con una barra de navegacion inferior.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // El paywall se muestra UNA sola vez, justo despues de terminar el
    // onboarding (el momento "aha" del usuario): ver
    // `PrefsService.paywallShownAfterOnboarding`. Es un paywall "suave":
    // se puede cerrar libremente (boton atras del AppBar) y no vuelve a
    // aparecer automaticamente ni bloquea ninguna funcion gratuita.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboardingPaywall());
  }

  Future<void> _maybeShowOnboardingPaywall() async {
    final prefs = context.read<PrefsService>();
    if (prefs.paywallShownAfterOnboarding) return;
    await prefs.setPaywallShownAfterOnboarding(true);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      _HomeFeedTab(),
      JournalScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Diario',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

class _HomeFeedTab extends StatefulWidget {
  const _HomeFeedTab();

  @override
  State<_HomeFeedTab> createState() => _HomeFeedTabState();
}

/// `SingleTickerProviderStateMixin` se agrega unicamente para poder animar
/// la entrada escalonada ("staggered") de las secciones del inicio la
/// primera vez que se construyen (ver `_entranceController`/
/// `_staggeredSection`), con una curva organica en vez del aparecer seco
/// de antes.
class _HomeFeedTabState extends State<_HomeFeedTab>
    with RouteAware, SingleTickerProviderStateMixin {
  late Future<_FeedData> _future;
  PageRoute<dynamic>? _subscribedRoute;
  int? _celebratingMilestone;

  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entranceController.forward();
    // Se aprovecha para refrescar el cupo mensual de fichas de
    // congelación (solo aplica si el usuario es Plus), asi la pradera
    // muestra el conteo correcto sin que el usuario tenga que orar
    // primero.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isPlus = context.read<PurchaseService>().isPlusUser;
      context.read<StreakService>().refreshFreezeTokens(isPlusUser: isPlus);
      // Cubre el caso (poco comun) de que ya hubiera un hito pendiente de
      // celebrar apenas se construye esta pantalla por primera vez.
      _maybeCelebrateMilestone();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se suscribe al `RouteObserver` compartido para detectar cuando el
    // usuario *vuelve* a esta pantalla (p. ej. al cerrar
    // `PrayerDetailScreen` despues de marcar una oracion como orada), que
    // es el momento correcto para mostrar la celebracion de hito de racha
    // (ver `didPopNext`).
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _subscribedRoute) {
      if (_subscribedRoute != null) {
        appRouteObserver.unsubscribe(this);
      }
      appRouteObserver.subscribe(this, route);
      _subscribedRoute = route;
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _entranceController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Se volvio a esta pantalla desde otra que se acaba de cerrar (ver
    // `PrayerDetailScreen`): buen momento para mostrar una celebracion de
    // hito si `markPrayedToday` dejo una pendiente.
    _maybeCelebrateMilestone();
  }

  void _maybeCelebrateMilestone() {
    if (!mounted) return;
    final streak = context.read<StreakService>();
    final milestone = streak.pendingMilestone;
    if (milestone == null) return;
    streak.acknowledgeMilestoneShown();
    HapticFeedback.mediumImpact();
    setState(() => _celebratingMilestone = milestone);
  }

  Future<_FeedData> _load() async {
    final repo = context.read<PrayerRepository>();
    final prefs = context.read<PrefsService>();
    final categories = prefs.preferredCategories;
    final oracionDelDia = await repo.prayerOfTheDay(
      preferredCategories: categories,
    );
    final feed = await repo.byCategories(categories);
    feed.removeWhere((p) => p.id == oracionDelDia.id);
    // Coherencia: primero las oraciones del primer tema elegido, luego el
    // segundo, etc.
    feed.sort((a, b) => categories
        .indexOf(a.categoria)
        .compareTo(categories.indexOf(b.categoria)));

    // Prueba social honesta (ver `CommunityStatsService`): hoy siempre
    // devuelve `null` porque no existe un backend real que agregue
    // usuarios activos, asi que el widget de inicio cae de forma segura al
    // copy no cuantificado. Queda listo para mostrar un numero en vivo el
    // dia que se conecte un backend real, sin volver a tocar esta pantalla.
    const communityStats = StubCommunityStatsService();
    final prayingNowEstimate = await communityStats.getPrayingNowEstimate();

    return _FeedData(
      oracionDelDia: oracionDelDia,
      feed: feed,
      prayingNowEstimate: prayingNowEstimate,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  /// Envuelve [child] en una entrada escalonada de fundido+desplazamiento:
  /// el fundido usa una curva suave sin overshoot (`Curves.easeOutCubic`,
  /// segura para valores de opacidad entre 0.0 y 1.0), mientras que el
  /// desplazamiento vertical usa una curva organica con "rebote"
  /// (`Curves.easeOutBack`, segura para un `Offset` aunque exceda
  /// momentaneamente el rango 0..1). [start]/[end] ubican el tramo de
  /// [_entranceController] (0.0 a 1.0) que le corresponde a esta seccion,
  /// para que las secciones aparezcan una tras otra en vez de todas a la
  /// vez.
  Widget _staggeredSection(
    Widget child, {
    required double start,
    required double end,
  }) {
    final fade = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    ));
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakService>();
    final isPlus = context.watch<PurchaseService>().isPlusUser;

    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<_FeedData>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    // 0. Encabezado calido: saludo segun la hora del dia,
                    // ahora mas liviano (la racha y el arbol viven en la
                    // pradera de abajo, no aqui).
                    _staggeredSection(
                      SafeArea(
                        bottom: false,
                        child: _GreetingHeader(
                          nombre: context.read<PrefsService>().userName,
                        ),
                      ),
                      start: 0.0,
                      end: 0.45,
                    ),
                    const SizedBox(height: 16),
                    // 1. HERO v11: la pradera del Salmo 23 — numero
                    // gigante de racha ("dias caminando con el Pastor"),
                    // anillo de minutos del dia, arbol de fe, arroyo,
                    // flores que crecen con los minutos orados y la
                    // ovejita (que eres tu).
                    _staggeredSection(
                      MeadowHero(
                        streak: streak.currentStreak,
                        atRisk: streak.streakAtRisk,
                        prayedToday: streak.prayedToday,
                        minutesToday: streak.minutesToday,
                        cumulativeMinutes: streak.cumulativeMinutes,
                        sheepLost: (streak.daysSinceLastPrayed ?? 0) >= 2,
                        freezeTokens: (isPlus && streak.freezeTokens > 0)
                            ? streak.freezeTokens
                            : null,
                      ),
                      start: 0.05,
                      end: 0.6,
                    ),
                    const SizedBox(height: 24),
                    // 2. La oracion del dia, ahora segunda en jerarquia
                    // visual despues de la pradera (sigue siendo la
                    // accion principal del dia).
                    _staggeredSection(
                      _HeroPrayerSection(
                        prayer: data.oracionDelDia,
                        onTap: () => _openDetail(data.oracionDelDia),
                      ),
                      start: 0.15,
                      end: 0.75,
                    ),
                    const SizedBox(height: 16),
                    // 3. Prueba social honesta.
                    _staggeredSection(
                      _SocialProofBanner(
                        prayingNowEstimate: data.prayingNowEstimate,
                      ),
                      start: 0.3,
                      end: 0.85,
                    ),
                    const SizedBox(height: 28),
                    // 4. Feed personalizado + banner Plus.
                    _staggeredSection(
                      _ParaTiSection(
                        feed: data.feed,
                        isPlus: isPlus,
                        onOpenPrayer: _openDetail,
                        onOpenPaywall: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PaywallScreen()),
                          );
                        },
                      ),
                      start: 0.4,
                      end: 1.0,
                    ),
                  ],
                ),
              );
            },
          ),
          if (_celebratingMilestone != null)
            _MilestoneCelebrationOverlay(
              milestone: _celebratingMilestone!,
              onDismiss: () => setState(() => _celebratingMilestone = null),
            ),
        ],
      ),
    );
  }

  void _openDetail(Prayer prayer) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PrayerDetailScreen(prayer: prayer)),
    );
  }
}

/// Encabezado calido del inicio: avatar de la ovejita, fecha en español y
/// saludo serif segun la hora del dia. Desde v11 es deliberadamente
/// liviano: la racha, el arbol y los minutos viven en la pradera
/// (`MeadowHero`), no aqui.
class _GreetingHeader extends StatelessWidget {
  final String nombre;

  const _GreetingHeader({required this.nombre});

  String get _saludo {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hoy = DateTime.now();
    const dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final fecha =
        '${dias[hoy.weekday - 1]}, ${hoy.day} de ${meses[hoy.month - 1]}';

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ClipOval(
              child: Container(
                width: 48,
                height: 48,
                color: scheme.primaryContainer,
                padding: const EdgeInsets.all(5),
                child: Image.asset(
                  'assets/mascot/ovejita.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fecha.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nombre.isEmpty ? _saludo : '$_saludo, $nombre 🌅',
                  style: AppTypography.display.copyWith(
                    fontSize: 24,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Seccion de la oracion del dia: overline dorada + titulo serif + la
/// tarjeta destacada (fondo primario profundo, ver
/// `PrayerCard(destacada: true)`).
class _HeroPrayerSection extends StatelessWidget {
  final Prayer prayer;
  final VoidCallback onTap;

  const _HeroPrayerSection({required this.prayer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 2,
              color: scheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'PARA HOY',
              style: AppTypography.caption.copyWith(color: scheme.secondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Oración del día',
          style: AppTypography.headline.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 14),
        PrayerCard(prayer: prayer, destacada: true, onTap: onTap),
      ],
    );
  }
}

/// Feed personalizado ("Para ti") y banner de Plus: tercer nivel de
/// jerarquia, debajo de la pradera y de la oracion del dia.
class _ParaTiSection extends StatelessWidget {
  final List<Prayer> feed;
  final bool isPlus;
  final ValueChanged<Prayer> onOpenPrayer;
  final VoidCallback onOpenPaywall;

  const _ParaTiSection({
    required this.feed,
    required this.isPlus,
    required this.onOpenPrayer,
    required this.onOpenPaywall,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Para ti', style: AppTypography.headline),
        const SizedBox(height: 4),
        Text(
          'Según los temas que elegiste en tu perfil.',
          style: AppTypography.body.copyWith(color: AppColors.inkSoft),
        ),
        const SizedBox(height: 12),
        if (feed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Aún no elegiste temas de interés. Ve a Ajustes > '
              'Mis intereses para personalizar tu inicio.',
              style: AppTypography.body.copyWith(color: AppColors.inkSoft),
            ),
          )
        else
          ...List.generate(feed.length, (i) {
            final p = feed[i];
            final bloqueada = !isPlus && i >= 2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PrayerCard(
                prayer: p,
                bloqueada: bloqueada,
                insignia: (!isPlus && i == 1) ? '🎙️ Órala en voz alta' : null,
                onTap: bloqueada ? onOpenPaywall : () => onOpenPrayer(p),
              ),
            );
          }),
        const SizedBox(height: 12),
        if (!isPlus) _PlusBanner(onTap: onOpenPaywall),
      ],
    );
  }
}

/// Banner de "prueba social" honesta en el inicio: si [prayingNowEstimate]
/// es `null` (todavia no hay backend real que agregue usuarios activos, ver
/// `CommunityStatsService`), muestra un copy generico y verdadero en vez de
/// inventar un numero (evita el patron oscuro de prueba social falsa).
class _SocialProofBanner extends StatelessWidget {
  final int? prayingNowEstimate;

  const _SocialProofBanner({required this.prayingNowEstimate});

  @override
  Widget build(BuildContext context) {
    final estimate = prayingNowEstimate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.tealLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_outlined, size: 18, color: AppColors.tealDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              estimate != null
                  ? '$estimate personas orando en este momento'
                  : 'Cada día, muchas personas usan Ora Ahora para hacer una '
                      'pausa y orar.',
              style: AppTypography.caption.copyWith(color: AppColors.tealDeep),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlusBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _PlusBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.amberLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium, color: AppColors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Conoce Ora Ahora Plus', style: AppTypography.title),
                  Text(
                    'Apps ilimitadas en Pausa y Ora, fichas de congelación y más.',
                    style: AppTypography.caption.copyWith(color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _FeedData {
  final Prayer oracionDelDia;
  final List<Prayer> feed;
  final int? prayingNowEstimate;

  const _FeedData({
    required this.oracionDelDia,
    required this.feed,
    required this.prayingNowEstimate,
  });
}

/// Overlay breve mostrado al alcanzar un nuevo hito de racha (ver
/// `StreakService.milestones`/`pendingMilestone`). Se descarta al tocar en
/// cualquier parte de la pantalla. Entra con una animacion organica
/// de "rebote" (`Curves.elasticOut` en la escala) en vez de aparecer sin
/// transicion.
class _MilestoneCelebrationOverlay extends StatefulWidget {
  final int milestone;
  final VoidCallback onDismiss;

  const _MilestoneCelebrationOverlay({
    required this.milestone,
    required this.onDismiss,
  });

  @override
  State<_MilestoneCelebrationOverlay> createState() =>
      _MilestoneCelebrationOverlayState();
}

class _MilestoneCelebrationOverlayState
    extends State<_MilestoneCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // La escala usa `elasticOut` (rebote organico) para que la celebracion
    // se sienta como un pequeño festejo, no como un dialogo mas.
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    // El fundido del velo oscuro usa una curva sin rebote, y solo ocupa el
    // primer 40% de la duracion (aparece rapido, luego el rebote de la
    // tarjeta sigue un poco mas).
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: FadeTransition(
          opacity: _fade,
          child: Container(
            color: Colors.black54,
            alignment: Alignment.center,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // v11b: la ovejita celebra el hito contigo (antes era
                    // un icono generico de Material).
                    Image.asset(
                      'assets/mascot/ovejita_celebrando.png',
                      height: 96,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      StreakService.milestoneMessage(widget.milestone),
                      textAlign: TextAlign.center,
                      style: AppTypography.title,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: widget.onDismiss,
                      child: const Text('¡Gracias, Dios!'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
EOF_LIB_SCREENS_HOME_HOME_SCREEN_DART

mkdir -p "$(dirname lib/screens/prayer_detail/prayer_detail_screen.dart)"
cat > lib/screens/prayer_detail/prayer_detail_screen.dart <<'EOF_LIB_SCREENS_PRAYER_DETAIL_PRAYER_DETAIL_SCREEN_DART'
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../services/prefs_service.dart';
import '../../services/purchase_service.dart';
import '../../services/streak_service.dart';
import '../../services/voice_prayer_service.dart';
import '../../widgets/amen_celebration.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Muestra el texto completo de una oracion, la referencia biblica y el
/// boton para marcarla como orada hoy (actualiza la racha).
///
/// Si en Ajustes > Voz se activo "Detectar cuando termino de orar (con
/// micrófono)" Y el reconocimiento de voz en el dispositivo esta
/// disponible en este telefono, tambien se muestra un boton opcional
/// "Escuchar mi oración" (ver [_VoicePrayerSection] mas abajo) que usa
/// `VoicePrayerService` (paquete `speech_to_text`, SIEMPRE con
/// `onDevice: true`) para confirmar automaticamente la misma accion que
/// el boton manual, sin reemplazarlo nunca: el boton manual sigue siempre
/// visible y funcional, incluso si el interruptor de voz esta activo.
class PrayerDetailScreen extends StatefulWidget {
  final Prayer prayer;

  const PrayerDetailScreen({super.key, required this.prayer});

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen>
    with TickerProviderStateMixin {
  bool _markedNow = false;

  final VoicePrayerService _voiceService = VoicePrayerService();
  late final AnimationController _pulseController;

  /// Entrada suave de toda la pantalla (fundido, sin desplazamiento) al
  /// abrir una oracion, para que se sienta consistente con el mismo
  /// patron de entrada usado en el inicio (`Curves.easeOutCubic` sobre la
  /// opacidad, ver `home_screen.dart` -> `_staggeredSection`). Aqui es una
  /// unica seccion (no escalonada) porque toda la pantalla es, en esencia,
  /// un solo "momento" (la tarjeta de oracion), a diferencia del inicio
  /// que tiene varias secciones con distinta jerarquia.
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;

  bool _listening = false;
  String _partialText = '';
  Timer? _progressTimer;

  /// Palabras significativas (4+ letras, sin tildes) del texto de la
  /// oracion: la confirmacion por voz exige que la persona diga una
  /// parte real de ESTA oracion, no cualquier cosa.
  late final Set<String> _prayerTokens;
  final Set<String> _matchedTokens = {};

  double get _coverage => _prayerTokens.isEmpty
      ? 0
      : _matchedTokens.length / _prayerTokens.length;

  /// Cobertura minima de la oracion dicha en voz alta para confirmarla.
  static const double _coverageToConfirm = 0.55;

  /// Si la persona cierra con "amen", basta con esta cobertura.
  static const double _coverageWithAmen = 0.30;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _prayerTokens = _tokenize(widget.prayer.texto);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pulseController.dispose();
    _entranceController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  static Set<String> _tokenize(String text) {
    final normalized = _stripDiacritics(text.toLowerCase());
    return RegExp(r'[a-zñ]{4,}')
        .allMatches(normalized)
        .map((m) => m.group(0)!)
        .toSet();
  }

  /// Nunca se pide el microfono "en frio": la primera vez se muestra la
  /// pantalla que explica con calma para que sirve y que la voz se
  /// procesa 100% en el telefono. Solo despues se inicia la escucha.
  Future<void> _ensureVoiceReadyAndStart() async {
    final prefs = context.read<PrefsService>();
    // Si el sistema YA dio el permiso, cero preguntas: a orar directo.
    final yaTienePermiso = await _voiceService.hasMicPermission;
    if (!mounted) return;
    if (yaTienePermiso) {
      final listo = await _voiceService.checkAvailability();
      if (!mounted) return;
      if (!listo) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('No pudimos iniciar el micrófono en este teléfono 😔'),
        ));
        return;
      }
      await _startListening();
      return;
    }
    // Sin permiso: UNA sola pantalla de contexto y luego el dialogo del
    // sistema. Nunca doble pregunta.
    if (true) {
      final acepta = await showModalBottomSheet<bool>(
        context: context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎙️🙏', style: TextStyle(fontSize: 34)),
              const SizedBox(height: 12),
              Text('Oremos juntos, en voz alta',
                  style: AppTypography.headline.copyWith(fontSize: 21)),
              const SizedBox(height: 10),
              Text(
                'Si me lo permites, te escucho mientras oras y marco la '
                'oración por ti cuando la termines. Para eso necesito '
                'acceso a tu micrófono. Tu voz se queda en tu teléfono: '
                'nunca se graba ni se envía a ningún lado.',
                style: AppTypography.body.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sí, escúchame orar 🙏'),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Ahora no'),
                ),
              ),
            ],
          ),
        ),
      );
      if (acepta != true || !mounted) return;
      await prefs.setMicPrimingDone(true);
      await prefs.setVoiceDisclosureSeen(true);
      if (!mounted) return;
    }
    final available = await _voiceService.checkAvailability();
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('No pudimos activar el micrófono en este teléfono 😔'),
      ));
      return;
    }
    await _startListening();
  }

  static String _stripDiacritics(String input) {
    const from = 'áéíóúÁÉÍÓÚñÑ';
    const to = 'aeiouAEIOUnN';
    var result = input;
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }

  bool _containsAmen(String text) {
    final normalized = _stripDiacritics(text.toLowerCase());
    return RegExp(r'\bamen\b').hasMatch(normalized);
  }

  /// Llamada por AMBOS caminos de confirmacion (el boton manual y la
  /// deteccion por voz): actualiza la racha con exactamente la misma
  /// funcion (`StreakService.markPrayedToday`) para que el resultado sea
  /// identico sin importar como se confirmo la oracion.
  Future<void> _confirmPrayed() async {
    final streak = context.read<StreakService>();
    final isPlus = context.read<PurchaseService>().isPlusUser;
    if (streak.prayedToday) {
      // Orar mas de una vez al dia SIEMPRE se puede: la racha no cambia,
      // pero el arbol de fe sigue sumando minutos.
      await streak.addExtraMinutes(widget.prayer.duracionEstimadaMin);
    } else {
      await streak.markPrayedToday(
        isPlusUser: isPlus,
        minutes: widget.prayer.duracionEstimadaMin,
      );
    }
    if (!mounted) return;
    setState(() => _markedNow = true);
  }

  Future<void> _onManualMarkPressed() async {
    final streak = context.read<StreakService>();
    final yaHabiaOrado = streak.prayedToday;
    await _confirmPrayed();
    if (!mounted) return;
    if (yaHabiaOrado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Amén! Tu árbol de fe sigue creciendo 🌱 '
            '(+${widget.prayer.duracionEstimadaMin} min)',
          ),
        ),
      );
    } else {
      // Primera oracion del dia: momento Amen a pantalla completa.
      await showAmenCelebration(
        context,
        streak: streak.currentStreak,
        referencia: widget.prayer.referenciaBiblica,
      );
    }
  }

  Future<void> _startListening() async {
    if (_listening || _markedNow) return;

    setState(() {
      _listening = true;
      _partialText = '';
      _matchedTokens.clear();
    });

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted && _listening) setState(() {});
      },
    );

    final started = await _voiceService.startListening(
      onPartialResult: _onPartialResult,
      onDone: _onListeningDone,
    );

    if (!started && mounted) {
      // No disponible en este intento (permiso revocado, sin modelo
      // on-device, etc.): degradarse en silencio, sin dialogos de error.
      _progressTimer?.cancel();
      setState(() => _listening = false);
    }
  }

  void _onPartialResult(String recognizedWords) {
    if (!mounted || !_listening) return;
    _matchedTokens.addAll(
      _tokenize(recognizedWords).where(_prayerTokens.contains),
    );
    setState(() => _partialText = recognizedWords);

    // Solo cuenta como orada si de verdad se dijo (buena parte de) ESTA
    // oracion: cobertura alta por si sola, o cierre con "amen" cuando ya
    // se dijo al menos un tercio.
    if (_coverage >= _coverageToConfirm ||
        (_containsAmen(recognizedWords) && _coverage >= _coverageWithAmen)) {
      _handleAutoConfirm();
    }
  }

  Future<void> _handleAutoConfirm() async {
    if (_markedNow) return;
    _progressTimer?.cancel();
    await _voiceService.stopListening();
    if (!mounted) return;
    setState(() => _listening = false);

    final streak = context.read<StreakService>();
    final yaHabiaOrado = streak.prayedToday;
    await _confirmPrayed();
    if (!mounted) return;
    if (yaHabiaOrado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Amén! Te escuchamos orar 🙏 Tu árbol sigue '
              'creciendo 🌱'),
        ),
      );
    } else {
      await showAmenCelebration(
        context,
        streak: streak.currentStreak,
        referencia: widget.prayer.referenciaBiblica,
      );
    }
  }

  /// Se llama cuando `speech_to_text` deja de escuchar sin que la
  /// pantalla lo haya pedido (silencio prolongado detectado por el
  /// propio motor, error, o limite maximo de tiempo alcanzado). Nunca
  /// muestra dialogos de error: solo vuelve al estado inicial para que
  /// la persona pueda tocar de nuevo "Escuchar mi oración" o usar el
  /// boton manual.
  void _onListeningDone({required bool success}) {
    if (!mounted) return;
    _progressTimer?.cancel();
    setState(() => _listening = false);
  }

  Future<void> _cancelListening() async {
    _progressTimer?.cancel();
    await _voiceService.stopListening();
    if (!mounted) return;
    setState(() {
      _listening = false;
      _partialText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakService>();
    final yaOradaHoy = streak.prayedToday;

    return Scaffold(
      appBar: AppBar(
        title: Text(PrayerCategories.displayName(widget.prayer.categoria)),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _entranceFade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_listening)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 150),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        widget.prayer.texto,
                        style: AppTypography.prayerText.copyWith(
                          fontSize: 14.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  )
                else
                  _PrayerHeroCard(prayer: widget.prayer),
                SizedBox(height: _listening ? 14 : 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _markedNow ? null : _onManualMarkPressed,
                    icon: Icon(
                      _markedNow
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                    ),
                    label: Text(
                      _markedNow
                          ? 'Oración registrada ✅'
                          : yaOradaHoy
                              ? 'Orar esta también 🙏'
                              : 'Amén — ya oré 🙏',
                    ),
                  ),
                ),
                if (!_markedNow) ...[
                  const SizedBox(height: 14),
                  _VoicePrayerSection(
                    listening: _listening,
                    partialText: _partialText,
                    coverage: _coverage,
                    pulseController: _pulseController,
                    onStart: _ensureVoiceReadyAndStart,
                    onCancel: _cancelListening,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pagina devocional de la oracion: se lee como la pagina de un libro,
/// no como una tarjeta de UI. Overline dorada centrada, titulo serif
/// centrado, texto de oracion en serif con interlineado generoso y la
/// referencia biblica como cita con filete dorado.
class _PrayerHeroCard extends StatelessWidget {
  final Prayer prayer;

  const _PrayerHeroCard({required this.prayer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.brightness == Brightness.dark
            ? scheme.surfaceContainerHighest
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(26, 32, 26, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ORACIÓN · ${prayer.duracionEstimadaMin} MIN',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: scheme.secondary),
          ),
          const SizedBox(height: 14),
          Text(
            prayer.titulo,
            textAlign: TextAlign.center,
            style: AppTypography.display.copyWith(
              fontSize: 27,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          // Pequeño ornamento tipografico como separador, en vez de una
          // linea dura.
          Text(
            '✦',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: scheme.secondary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            prayer.texto,
            style: AppTypography.prayerText.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: scheme.secondary, width: 2),
              ),
            ),
            child: Text(
              prayer.referenciaBiblica,
              style: AppTypography.quote.copyWith(color: scheme.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boton "Orar en voz alta" + indicador de escucha con barra de progreso
/// de la propia oracion (que porcentaje del texto ya se dijo). Todo el
/// estado vive en `_PrayerDetailScreenState`.
///
/// v11b: mientras se escucha, la ovejita asoma SOLO LA CABEZA por el
/// borde inferior del panel (ojos cerrados, escuchando en paz), como
/// pide el rediseno "Tu caminar con el Pastor". La imagen queda recortada
/// por el propio panel (`clipBehavior`), asi que literalmente "se asoma".
class _VoicePrayerSection extends StatelessWidget {
  final bool listening;
  final String partialText;
  final double coverage;
  final AnimationController pulseController;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  const _VoicePrayerSection({
    required this.listening,
    required this.partialText,
    required this.coverage,
    required this.pulseController,
    required this.onStart,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!listening) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.mic_none_rounded),
            label: const Text('Orar en voz alta 🎙️'),
          ),
          const SizedBox(height: 6),
          Text(
            'Si oras en voz alta, te escuchamos y marcamos la oración por '
            'ti. Tu voz nunca sale de tu teléfono.',
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSoft,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final pct = (coverage * 100).clamp(0, 100).round();
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18163A), Color(0xFF0A3A30)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 26, 18, 14),
            child: Column(
              children: [
                // MIC GIGANTE con ondas que respiran (hecho para grabarse)
                SizedBox(
                  width: 190,
                  height: 190,
                  child: AnimatedBuilder(
                    animation: pulseController,
                    builder: (context, _) {
                      final v = pulseController.value;
                      Widget onda(double base, double alpha) => Container(
                            width: base + 46 * v,
                            height: base + 46 * v,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFD18C)
                                    .withValues(alpha: alpha * (1 - v * 0.6)),
                                width: 2.5,
                              ),
                            ),
                          );
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          onda(150, 0.35),
                          onda(118, 0.55),
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFFFFE7C2),
                                  Color(0xFFFFD18C),
                                  Color(0xFFE2A85B),
                                ],
                                stops: [0.0, 0.6, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD18C)
                                      .withValues(alpha: 0.45 + 0.3 * v),
                                  blurRadius: 34 + 18 * v,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.mic_rounded,
                                size: 48, color: Color(0xFF241F10)),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text('Te escucho… sigue orando 🙏',
                    style: AppTypography.headline.copyWith(
                        fontSize: 20, color: const Color(0xFFF7F3EA))),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: coverage.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFD18C)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pct == 0
                      ? 'Lee la oración en voz alta, con calma'
                      : 'Ya llevas el $pct% · cierra con "Amén"',
                  style: AppTypography.caption.copyWith(
                      color: const Color(0xFFF7F3EA).withValues(alpha: 0.7),
                      letterSpacing: 0.4),
                  textAlign: TextAlign.center,
                ),
                if (partialText.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    partialText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.quote.copyWith(
                      fontSize: 13.5,
                      color: const Color(0xFFF7F3EA).withValues(alpha: 0.75),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onCancel,
                  child: Text('Cancelar',
                      style: TextStyle(
                          color: const Color(0xFFF7F3EA)
                              .withValues(alpha: 0.6))),
                ),
                // Aire extra para que la cabeza de la ovejita no tape el
                // boton de cancelar.
                const SizedBox(height: 30),
              ],
            ),
          ),
          // La ovejita asoma solo la cabeza por el borde inferior,
          // escuchando en paz (el panel la recorta con clipBehavior).
          Positioned(
            bottom: -16,
            right: 14,
            child: Image.asset(
              'assets/mascot/ovejita_escuchando.png',
              height: 82,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
EOF_LIB_SCREENS_PRAYER_DETAIL_PRAYER_DETAIL_SCREEN_DART

# --- Verificacion estatica ---
python3 - <<'EOF_CHECK'
import re, sys
files = ['lib/models/streak.dart', 'lib/services/streak_service.dart', 'lib/widgets/meadow_hero.dart', 'lib/screens/home/home_screen.dart', 'lib/screens/prayer_detail/prayer_detail_screen.dart']
prohibited = ['la paz sea contigo', 'rosario', 'avemaria', 'ave maria']
ok = True
for f in files:
    low = open(f, encoding='utf-8').read().lower()
    for p in prohibited:
        if p in low:
            print(f'{f}: FRASE PROHIBIDA: {p}'); ok = False
for name in ['ovejita_celebrando','ovejita_esperando','ovejita_escuchando','ovejita_perdida']:
    import os
    p = f'assets/mascot/{name}.png'
    if not os.path.exists(p) or os.path.getsize(p) < 1000:
        print(f'FALTA O VACIA: {p}'); ok = False
if not ok:
    sys.exit(1)
print('Verificacion estatica: OK')
EOF_CHECK

echo ""
echo "apply_v11b.sh aplicado: expresiones de la ovejita integradas."
echo "Siguiente: flutter pub get && flutter analyze && flutter build apk --debug"
