import 'package:flutter/material.dart';

import '../theme/app_palettes.dart';
import 'prefs_service.dart';

/// Controla la apariencia elegida por el usuario: cual de las 4
/// [AppPalette] usar, y si "Modo Simple" (accesibilidad: fuente mas grande
/// y botones mas altos, pensado para usuarios mayores) esta activo.
///
/// Si el usuario nunca eligio una paleta a mano, se sigue el mapeo por
/// defecto segun el brillo del sistema: Zafiro Calmo (clara, de alto
/// contraste) para modo claro, Mares Profundos (oscura) para modo oscuro.
/// Si el usuario SI eligio una paleta explicita, esa paleta se usa
/// siempre, sin importar si el sistema esta en claro u oscuro (para que
/// la eleccion del usuario no se sienta "revertida" por el sistema).
class AppearanceService extends ChangeNotifier {
  final PrefsService _prefs;

  AppearanceService(this._prefs);

  AppPaletteId? get explicitPaletteId =>
      AppPalette.idFromStringOrNull(_prefs.selectedPaletteId);

  bool get simpleModeEnabled => _prefs.simpleModeEnabled;

  Future<void> setPalette(AppPaletteId id) async {
    await _prefs.setSelectedPaletteId(id.name);
    notifyListeners();
  }

  /// Vuelve a seguir el tema claro/oscuro del sistema (deshace una
  /// eleccion explicita de paleta).
  Future<void> useSystemDefault() async {
    await _prefs.setSelectedPaletteId(null);
    notifyListeners();
  }

  Future<void> setSimpleMode(bool value) async {
    await _prefs.setSimpleModeEnabled(value);
    notifyListeners();
  }

  /// Resuelve que paleta usar segun el brillo actual del sistema, salvo
  /// que el usuario haya elegido una paleta explicita.
  AppPalette resolveForSystemBrightness(Brightness systemBrightness) {
    final explicit = explicitPaletteId;
    if (explicit != null) return AppPalette.byId(explicit);
    return systemBrightness == Brightness.dark
        ? AppPalette.maresProfundos
        : AppPalette.zafiroCalmo;
  }
}
