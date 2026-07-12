import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palettes.dart';

/// Tema Material 3 de Ora Ahora (modo claro y oscuro).
class AppTheme {
  AppTheme._();

  /// Construye un [ThemeData] completo a partir de una [AppPalette] (una
  /// de las 4 paletas seleccionables en Ajustes > Apariencia, ver
  /// `app_palettes.dart`).
  ///
  /// [simpleMode] implementa el interruptor de accesibilidad "Modo
  /// Simple": aumenta la altura minima de los botones principales a 65dp
  /// (para usuarios mayores, mas facil de acertar con el dedo) y usa una
  /// tipografia de boton ligeramente mayor. El aumento del tamaño de
  /// fuente GENERAL de la app (no solo botones) se aplica por separado en
  /// `main.dart` mediante un `MediaQuery`/`TextScaler` a nivel de toda la
  /// app, para que tambien afecte a los textos que usan `AppTypography`
  /// directamente (no solo los que usan `Theme.of(context).textTheme`).
  static ThemeData fromPalette(AppPalette palette, {bool simpleMode = false}) {
    final scheme = palette.colorScheme;
    final buttonHeight = simpleMode ? 65.0 : 52.0;

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        surfaceTintColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: simpleMode ? 18 : 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          minimumSize: Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.secondaryContainer,
        selectedColor: scheme.primary,
        labelStyle: TextStyle(color: scheme.onSecondaryContainer),
        secondaryLabelStyle: TextStyle(color: scheme.onPrimary),
        shape: StadiumBorder(side: BorderSide(color: scheme.secondaryContainer)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline.withValues(alpha: 0.3)),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : scheme.outline.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  /// Tema claro heredado (paleta original "noche tranquila" de
  /// AppColors). Se conserva sin usar activamente desde `main.dart` (que
  /// ahora construye el tema via [fromPalette]/[AppPalette]) para no
  /// romper ninguna referencia existente a `AppTheme.light()`.
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.tealMedium,
      brightness: Brightness.light,
      primary: AppColors.tealDeep,
      secondary: AppColors.amber,
      surface: AppColors.cream,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.tealLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tealDeep,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.tealDeep,
          side: const BorderSide(color: AppColors.tealDeep),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.tealDeep),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.tealLight,
        selectedColor: AppColors.tealDeep,
        labelStyle: const TextStyle(color: AppColors.ink),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: StadiumBorder(side: BorderSide(color: AppColors.tealLight)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.tealLight),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.tealDeep
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.tealLight
              : AppColors.sand,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.tealMedium,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
