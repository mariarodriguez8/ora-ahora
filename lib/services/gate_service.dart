import 'package:device_apps/device_apps.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'prefs_service.dart';

/// Puente entre Flutter y el lado nativo Android para la funcion
/// "Pausa y Ora".
///
/// v8 (apto para Play Store): la deteccion de apps ya NO usa el servicio de
/// Accesibilidad (Google lo rechaza para este caso de uso) sino la pareja
/// estandar de las apps de bienestar digital:
///  - "Acceso de uso" (PACKAGE_USAGE_STATS): saber que app pasa a primer
///    plano (solo el nombre del paquete).
///  - "Mostrar sobre otras apps" (SYSTEM_ALERT_WINDOW): poner la pausa de
///    oracion encima de la app que se esta abriendo.
/// Ambos permisos se conceden manualmente en Ajustes de Android; este
/// servicio abre las pantallas correctas y comprueba su estado.
///
/// La lista de apps bloqueadas y las preferencias del gate se guardan con
/// `PrefsService` (SharedPreferences), que es el mismo archivo que lee
/// `PrayerGateForegroundService.kt` de forma nativa. El `MethodChannel`
/// solo se usa para operaciones que si requieren codigo nativo puntual
/// (abrir Ajustes, comprobar permisos, sincronizar el servicio detector).
class GateService extends ChangeNotifier {
  static const _channel = MethodChannel('com.oraahora.app/gate');

  final PrefsService _prefs;

  GateService(this._prefs);

  List<String> get gatedApps => _prefs.gatedApps;

  bool get gateEnabled => _prefs.gateEnabled;

  int get graceMinutes => _prefs.gateGraceMinutes;

  Future<void> setGateEnabled(bool value) async {
    await _prefs.setGateEnabled(value);
    // Arranca o detiene el servicio detector nativo segun el nuevo estado
    // (y los permisos actuales). Nunca debe bloquear el interruptor.
    await syncNativeService();
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

  /// Abre Ajustes > Acceso de uso de Android (en muchos telefonos llega
  /// directo a la fila de Ora Ahora).
  Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } on PlatformException {
      // Si falla (dispositivo no estandar), no bloqueamos el flujo de la
      // app; el usuario puede navegar manualmente.
    }
  }

  /// Abre Ajustes > Mostrar sobre otras apps para Ora Ahora.
  Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } on PlatformException {
      // Igual que arriba: nunca bloquear el flujo.
    }
  }

  /// Comprueba el permiso especial "Acceso de uso" (AppOpsManager,
  /// OPSTR_GET_USAGE_STATS).
  Future<bool> hasUsageAccess() async {
    try {
      final granted = await _channel.invokeMethod<bool>('hasUsageAccess');
      return granted ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Comprueba el permiso "Mostrar sobre otras apps"
  /// (Settings.canDrawOverlays).
  Future<bool> hasOverlayPermission() async {
    try {
      final granted =
          await _channel.invokeMethod<bool>('hasOverlayPermission');
      return granted ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// true solo si AMBOS permisos de "Pausa y Ora" estan concedidos.
  Future<bool> hasAllGatePermissions() async {
    final usage = await hasUsageAccess();
    if (!usage) return false;
    return hasOverlayPermission();
  }

  /// Pide al lado nativo arrancar o detener el servicio detector segun el
  /// interruptor y los permisos actuales. Idempotente.
  Future<void> syncNativeService() async {
    try {
      await _channel.invokeMethod('syncGateService');
    } on PlatformException {
      // El servicio tambien se reconcilia solo en MainActivity.onResume.
    }
  }

  // ---- v12: permiso extra de MIUI (Xiaomi/Redmi/POCO) ----

  /// true si el telefono es Xiaomi/Redmi/POCO (MIUI/HyperOS).
  Future<bool> isMiuiDevice() async {
    try {
      final miui = await _channel.invokeMethod<bool>('isMiuiDevice');
      return miui ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// MIUI: estado de su permiso "Mostrar ventanas emergentes mientras se
  /// ejecuta en segundo plano". `null` = no aplica o no se pudo comprobar.
  Future<bool?> isMiuiBackgroundStartAllowed() async {
    try {
      return await _channel
          .invokeMethod<bool?>('isMiuiBackgroundStartAllowed');
    } on PlatformException {
      return null;
    }
  }

  /// Abre la pantalla "Otros permisos" de MIUI para Ora Ahora.
  Future<void> openMiuiOtherPermissions() async {
    try {
      await _channel.invokeMethod('openMiuiOtherPermissions');
    } on PlatformException {
      // Nunca bloquear el flujo; el usuario puede llegar manualmente.
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
