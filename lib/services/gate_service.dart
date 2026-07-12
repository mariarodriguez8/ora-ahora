import 'package:device_apps/device_apps.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'prefs_service.dart';

/// Puente entre Flutter y el lado nativo Android para la funcion
/// "Pausa y Ora" (el bloqueo/gate basado en AccessibilityService).
///
/// La lista de apps bloqueadas y las preferencias del gate se guardan con
/// `PrefsService` (SharedPreferences), que es el mismo archivo que lee
/// `PrayerGateAccessibilityService.kt` de forma nativa. El `MethodChannel`
/// solo se usa para dos operaciones que si requieren codigo nativo puntual:
/// abrir la pantalla de ajustes de accesibilidad de Android, y comprobar si
/// nuestro servicio de accesibilidad esta activo.
class GateService extends ChangeNotifier {
  static const _channel = MethodChannel('com.proqube.oraahora/gate');

  final PrefsService _prefs;

  GateService(this._prefs);

  List<String> get gatedApps => _prefs.gatedApps;

  bool get gateEnabled => _prefs.gateEnabled;

  int get graceMinutes => _prefs.gateGraceMinutes;

  Future<void> setGateEnabled(bool value) async {
    await _prefs.setGateEnabled(value);
    notifyListeners();
  }

  Future<void> setGraceMinutes(int minutes) async {
    await _prefs.setGateGraceMinutes(minutes);
    notifyListeners();
  }

  bool isGated(String packageName) => gatedApps.contains(packageName);

  Future<void> addGatedApp(String packageName) async {
    final current = List<String>.from(gatedApps);
    if (!current.contains(packageName)) {
      current.add(packageName);
      await _prefs.setGatedApps(current);
      notifyListeners();
    }
  }

  Future<void> removeGatedApp(String packageName) async {
    final current = List<String>.from(gatedApps);
    current.remove(packageName);
    await _prefs.setGatedApps(current);
    notifyListeners();
  }

  Future<void> toggleGatedApp(String packageName, {required int maxApps}) async {
    if (isGated(packageName)) {
      await removeGatedApp(packageName);
      return;
    }
    if (gatedApps.length >= maxApps) {
      return; // el limite se comunica en la UI antes de llegar aqui
    }
    await addGatedApp(packageName);
  }

  /// Lista las apps instaladas con icono de lanzamiento (excluye apps de
  /// sistema sin interfaz), ordenadas alfabeticamente. Usa el paquete
  /// `device_apps`.
  Future<List<Application>> installedLaunchableApps() async {
    final apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );
    apps.sort((a, b) =>
        a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
    return apps;
  }

  /// Abre la pantalla nativa de Ajustes > Accesibilidad de Android para que
  /// el usuario active manualmente "Ora Ahora - Pausa y Ora".
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException {
      // Si falla (por ejemplo en un dispositivo no estandar), no bloqueamos
      // el flujo de la app; el usuario puede navegar manualmente.
    }
  }

  /// Comprueba si `PrayerGateAccessibilityService` esta activo en este
  /// momento segun Android (Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES).
  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final enabled =
          await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return enabled ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Comprueba si Android ya excluyo a Ora Ahora de la optimizacion de
  /// bateria (`PowerManager.isIgnoringBatteryOptimizations`). Si es
  /// `false`, "Pausa y Ora" corre el riesgo de ser silenciada por el
  /// sistema en fabricantes con gestion agresiva de bateria.
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final ignoring =
          await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return ignoring ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Abre el dialogo nativo de Android para pedirle al usuario que excluya
  /// a Ora Ahora de la optimizacion de bateria
  /// (`Intent.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`). No hace nada
  /// si ya esta excluida.
  Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } on PlatformException {
      // Si falla, el usuario puede hacerlo manualmente desde los ajustes
      // de bateria de su telefono; no bloqueamos el flujo de la app.
    }
  }
}
