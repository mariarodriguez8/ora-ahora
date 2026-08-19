import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Punto unico de acceso a `SharedPreferences` y catalogo central de claves.
///
/// IMPORTANTE (contrato con el codigo nativo Kotlin):
/// El plugin `shared_preferences` en Android guarda todas las claves en el
/// archivo `FlutterSharedPreferences` con el prefijo `flutter.` delante de
/// cada clave (p. ej. la clave Dart `gated_apps` se guarda como
/// `flutter.gated_apps`). `PrayerGateForegroundService.kt` y
/// `PrayerGateActivity.kt` leen ese mismo archivo directamente para saber
/// que apps debe bloquear.
///
/// Para evitar la codificacion especial que usa el plugin para `List<String>`
/// y `double` (usa un prefijo mágico en Base64 para esos dos tipos), aqui
/// SOLO usamos `setString` (texto plano UTF-8, sin transformar) para los
/// valores que el lado nativo necesita leer, y `setBool` para banderas
/// (los booleanos SI se guardan de forma nativa con `putBoolean`, por lo
/// que son seguros de leer con `getBoolean` desde Kotlin). Los enteros que
/// necesita leer Kotlin se guardan tambien como `String` para evitar
/// depender de si el plugin los serializa como Int o como Long.
class PrefsKeys {
  // --- Onboarding / perfil ---
  static const onboardingComplete = 'onboarding_complete';
  static const preferredCategories = 'preferred_categories'; // String JSON
  static const morningTime = 'morning_time'; // "HH:mm"
  static const nightTime = 'night_time'; // "HH:mm"

  // --- Racha ---
  static const streakState = 'streak_state'; // String JSON
  static const estampasSeenStreak = 'estampas_seen_streak'; // int

  // --- Recordatorios ---
  static const reminderTimes = 'reminder_times'; // String JSON List<"HH:mm">
  static const notificationsEnabled = 'notifications_enabled';

  // --- Compras / Plus ---
  static const isPlusUser = 'is_plus_user';

  // --- Paywall ---
  /// Se pone en `true` la primera vez que se muestra el paywall justo
  /// despues de terminar el onboarding (el momento "aha" del usuario), asi
  /// no se vuelve a mostrar automaticamente en cada apertura de la app.
  static const paywallShownAfterOnboarding = 'paywall_shown_after_onboarding';

  // --- Apariencia (paletas de color y accesibilidad) ---
  /// Id (nombre del enum `AppPaletteId`) de la paleta elegida a mano por
  /// el usuario en Ajustes > Apariencia. Si es `null`/vacio, se usa el
  /// mapeo por defecto segun el modo claro/oscuro del sistema (ver
  /// `AppearanceService.resolveForBrightness`).
  static const selectedPaletteId = 'selected_palette_id';

  /// "Modo Simple": aumenta el tamaño de fuente y el tamaño de los botones
  /// principales (~65dp) para usuarios mayores o con baja vision.
  static const simpleModeEnabled = 'simple_mode_enabled';

  // --- Pausa y Ora (leido tambien por Kotlin) ---
  /// String con JSON array de package names, ej: ["com.instagram.android"]
  static const gatedApps = 'gated_apps';
  static const gatePrayers = 'gate_prayers'; // JSON array de textos (leido por Kotlin)

  /// "true"/"false" como String (no bool) para lectura nativa sin ambiguedad.
  static const gateEnabledFlag = 'gate_enabled_flag';

  /// Minutos de gracia antes de volver a mostrar la pausa para la misma app,
  /// guardado como String (ej. "20") para que Kotlin haga Integer.parseInt.
  static const gateGraceMinutes = 'gate_grace_minutes';

  /// (v8) La clave conserva su nombre historico ("accessibility_...") para
  /// no perder el estado de usuarios que ya vieron el explainer, pero desde
  /// v8 marca haber visto la pantalla de los DOS permisos de Pausa y Ora
  /// (Acceso de uso + Mostrar sobre otras apps).
  static const accessibilityExplainerSeen = 'accessibility_explainer_seen';

  // --- Patrones de uso / Recordatorio inteligente ---
  /// String con JSON array de timestamps (epoch millis), escrito por
  /// `PrayerGateForegroundService.kt` (lado nativo) cada vez que detecta
  /// la apertura de una app "gateada". Flutter SOLO lee esta clave (ver
  /// `UsagePatternService`); nunca la escribe.
  static const usagePatternLog = 'usage_pattern_log';

  /// Interruptor (opt-in, apagado por defecto) del recordatorio adicional
  /// basado en el horario habitual de apertura de apps "gateadas".
  static const smartReminderEnabled = 'smart_reminder_enabled';

  // --- Deteccion de oracion por voz (on-device, opt-in) ---
  /// Interruptor (apagado por defecto) de la deteccion automatica de fin
  /// de oracion usando el microfono y reconocimiento de voz 100% en el
  /// dispositivo (paquete `speech_to_text`). Ver `VoicePrayerService` y
  /// `PrayerDetailScreen`. Nunca se usa para nada mas que decidir si se
  /// muestra el boton "Escuchar mi oración".
  static const voiceDetectionEnabled = 'voice_detection_enabled';
  static const userName = 'user_name';
  static const micPrimingDone = 'mic_priming_done_v2';

  /// `true` una vez que la persona vio la pantalla de aviso previo
  /// (`VoiceExplainerScreen`) y concedio el permiso de microfono, para no
  /// volver a mostrar esa pantalla cada vez que reactive el interruptor.
  static const voiceDisclosureSeen = 'voice_disclosure_seen';
}

class PrefsService {
  final SharedPreferences _prefs;

  PrefsService(this._prefs);

  static Future<PrefsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefsService(prefs);
  }

  // --- Onboarding ---
  bool get onboardingComplete =>
      _prefs.getBool(PrefsKeys.onboardingComplete) ?? false;

  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool(PrefsKeys.onboardingComplete, value);

  List<String> get preferredCategories {
    final raw = _prefs.getString(PrefsKeys.preferredCategories);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  Future<void> setPreferredCategories(List<String> categories) {
    return _prefs.setString(
      PrefsKeys.preferredCategories,
      jsonEncode(categories),
    );
  }

  String get morningTime => _prefs.getString(PrefsKeys.morningTime) ?? '07:00';

  Future<void> setMorningTime(String hhmm) =>
      _prefs.setString(PrefsKeys.morningTime, hhmm);

  String get nightTime => _prefs.getString(PrefsKeys.nightTime) ?? '21:30';

  Future<void> setNightTime(String hhmm) =>
      _prefs.setString(PrefsKeys.nightTime, hhmm);

  // --- Racha ---
  String? get streakStateJson => _prefs.getString(PrefsKeys.streakState);

  Future<void> setStreakStateJson(String json) =>
      _prefs.setString(PrefsKeys.streakState, json);

  // --- Recordatorios ---
  List<String> get reminderTimes {
    final raw = _prefs.getString(PrefsKeys.reminderTimes);
    if (raw == null || raw.isEmpty) return ['07:00'];
    return (jsonDecode(raw) as List).cast<String>();
  }

  Future<void> setReminderTimes(List<String> times) {
    return _prefs.setString(PrefsKeys.reminderTimes, jsonEncode(times));
  }

  bool get notificationsEnabled =>
      _prefs.getBool(PrefsKeys.notificationsEnabled) ?? false;

  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(PrefsKeys.notificationsEnabled, value);

  // --- Plus ---
  bool get isPlusUser => _prefs.getBool(PrefsKeys.isPlusUser) ?? false;

  Future<void> setIsPlusUser(bool value) =>
      _prefs.setBool(PrefsKeys.isPlusUser, value);

  /// Mayor racha con la que la persona ya abrió la galería de estampas
  /// (para avisar cuando hay una estampa nueva por ver).
  int get estampasSeenStreak =>
      _prefs.getInt(PrefsKeys.estampasSeenStreak) ?? 0;

  Future<void> setEstampasSeenStreak(int value) =>
      _prefs.setInt(PrefsKeys.estampasSeenStreak, value);

  // --- Paywall ---
  bool get paywallShownAfterOnboarding =>
      _prefs.getBool(PrefsKeys.paywallShownAfterOnboarding) ?? false;

  Future<void> setPaywallShownAfterOnboarding(bool value) =>
      _prefs.setBool(PrefsKeys.paywallShownAfterOnboarding, value);

  // --- Apariencia ---
  /// `null` significa "sin preferencia explicita" (seguir el sistema).
  String? get selectedPaletteId => _prefs.getString(PrefsKeys.selectedPaletteId);

  Future<void> setSelectedPaletteId(String? id) async {
    if (id == null) {
      await _prefs.remove(PrefsKeys.selectedPaletteId);
      return;
    }
    await _prefs.setString(PrefsKeys.selectedPaletteId, id);
  }

  bool get simpleModeEnabled =>
      _prefs.getBool(PrefsKeys.simpleModeEnabled) ?? false;

  Future<void> setSimpleModeEnabled(bool value) =>
      _prefs.setBool(PrefsKeys.simpleModeEnabled, value);

  // --- Pausa y Ora ---
  List<String> get gatedApps {
    final raw = _prefs.getString(PrefsKeys.gatedApps);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  Future<void> setGatePrayersJson(String json) =>
      _prefs.setString(PrefsKeys.gatePrayers, json);

  Future<void> setGatedApps(List<String> packageNames) {
    return _prefs.setString(PrefsKeys.gatedApps, jsonEncode(packageNames));
  }

  bool get gateEnabled =>
      (_prefs.getString(PrefsKeys.gateEnabledFlag) ?? 'false') == 'true';

  Future<void> setGateEnabled(bool value) =>
      _prefs.setString(PrefsKeys.gateEnabledFlag, value ? 'true' : 'false');

  int get gateGraceMinutes {
    final raw = _prefs.getString(PrefsKeys.gateGraceMinutes);
    final valor = int.tryParse(raw ?? '') ?? 3;
    // 20 minutos era el valor viejo y dejaba pasar sesiones enteras sin una
    // sola pausa. Quien lo tenga guardado de una version anterior pasa a 3.
    return valor == 20 ? 3 : valor;
  }

  Future<void> setGateGraceMinutes(int minutes) {
    return _prefs.setString(PrefsKeys.gateGraceMinutes, minutes.toString());
  }

  bool get accessibilityExplainerSeen =>
      _prefs.getBool(PrefsKeys.accessibilityExplainerSeen) ?? false;

  Future<void> setAccessibilityExplainerSeen(bool value) =>
      _prefs.setBool(PrefsKeys.accessibilityExplainerSeen, value);

  // --- Patrones de uso / Recordatorio inteligente ---
  /// JSON crudo (String) del registro de timestamps escrito nativamente
  /// por `PrayerGateForegroundService.kt`, o `null` si aun no hay
  /// ningun evento registrado. Ver `UsagePatternService` para el analisis.
  String? get usagePatternLogRaw => _prefs.getString(PrefsKeys.usagePatternLog);

  bool get smartReminderEnabled =>
      _prefs.getBool(PrefsKeys.smartReminderEnabled) ?? false;

  Future<void> setSmartReminderEnabled(bool value) =>
      _prefs.setBool(PrefsKeys.smartReminderEnabled, value);

  // --- Deteccion de oracion por voz ---
  bool get voiceDetectionEnabled =>
      _prefs.getBool(PrefsKeys.voiceDetectionEnabled) ?? false;

  Future<void> setVoiceDetectionEnabled(bool value) =>
      _prefs.setBool(PrefsKeys.voiceDetectionEnabled, value);

  /// Nombre de pila opcional (para saludos y notificaciones personales).
  String get userName => _prefs.getString(PrefsKeys.userName) ?? '';

  Future<void> setUserName(String value) =>
      _prefs.setString(PrefsKeys.userName, value.trim());

  /// `true` cuando ya se mostro (en esta instalacion) la explicacion
  /// amable del microfono antes de escuchar la primera oracion en voz alta.
  bool get micPrimingDone => _prefs.getBool(PrefsKeys.micPrimingDone) ?? false;

  Future<void> setMicPrimingDone(bool value) =>
      _prefs.setBool(PrefsKeys.micPrimingDone, value);

  bool get voiceDisclosureSeen =>
      _prefs.getBool(PrefsKeys.voiceDisclosureSeen) ?? false;

  Future<void> setVoiceDisclosureSeen(bool value) =>
      _prefs.setBool(PrefsKeys.voiceDisclosureSeen, value);
}
