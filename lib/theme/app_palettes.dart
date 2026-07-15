import 'package:flutter/material.dart';

/// Identificador estable de cada paleta seleccionable. Los NOMBRES del
/// enum se conservan tal cual (se guardan en SharedPreferences como
/// String via `value.name`), aunque las paletas fueron redisenadas por
/// completo: asi una preferencia guardada con la version anterior sigue
/// resolviendo a una paleta valida sin migracion.
enum AppPaletteId {
  fusionFresca,
  naturalezaSerena,
  maresProfundos,
  zafiroCalmo,
}

/// Paletas "Santuario" seleccionables en Ajustes > Apariencia.
///
/// Las 4 son variaciones del mismo lenguaje (fondo papel calido + un
/// color profundo de marca + dorado como acento), no 4 estilos distintos:
/// asi cualquier eleccion del usuario se ve deliberada y coherente.
///
/// Cada pareja texto/fondo fue verificada numericamente (formula de
/// contraste WCAG 2.1) con minimo 4.5:1 para texto normal.
class AppPalette {
  final AppPaletteId id;
  final String nombre;
  final String descripcion;
  final ColorScheme colorScheme;

  /// 4 tonos representativos para el "swatch" de vista previa en Ajustes.
  final List<Color> swatch;

  const AppPalette({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.colorScheme,
    required this.swatch,
  });

  bool get isDark => colorScheme.brightness == Brightness.dark;

  static const _errorLight = Color(0xFFA93F2E);
  static const _onErrorLight = Colors.white;
  static const _errorContainerLight = Color(0xFFF6DCD5);
  static const _onErrorContainerLight = Color(0xFF551A0E);

  static const _errorDark = Color(0xFFE8A594);
  static const _onErrorDark = Color(0xFF441106);
  static const _errorContainerDark = Color(0xFF7B3020);
  static const _onErrorContainerDark = Color(0xFFF6DCD5);

  /// "Bosque y Lino" (por defecto): la paleta de marca. Papel marfil,
  /// verde abeto profundo y dorado viejo. Contrastes clave: primary
  /// sobre surface 12.1:1; dorado sobre marfil 5.1:1.
  static const zafiroCalmo = AppPalette(
    id: AppPaletteId.zafiroCalmo,
    nombre: 'Bosque y Lino',
    descripcion: 'La paleta de Ora Ahora: papel cálido y verde profundo.',
    swatch: [
      Color(0xFFF7F3EA),
      Color(0xFFDCE8DE),
      Color(0xFF8A5F27),
      Color(0xFF16342B),
    ],
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF16342B),
      onPrimary: Color(0xFFF7F3EA),
      primaryContainer: Color(0xFFDCE8DE),
      onPrimaryContainer: Color(0xFF16342B),
      secondary: Color(0xFF8A5F27),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFEDE5D2),
      onSecondaryContainer: Color(0xFF4F3610),
      tertiary: Color(0xFF2C5747),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFEBD7AE),
      onTertiaryContainer: Color(0xFF4F3610),
      error: _errorLight,
      onError: _onErrorLight,
      errorContainer: _errorContainerLight,
      onErrorContainer: _onErrorContainerLight,
      surface: Color(0xFFF7F3EA),
      onSurface: Color(0xFF1C1F1D),
      surfaceContainerHighest: Color(0xFFEDE5D2),
      onSurfaceVariant: Color(0xFF545A52),
      outline: Color(0xFFC7C0AE),
      outlineVariant: Color(0xFFDFD9C8),
    ),
  );

  /// "Amanecer": variacion calida sobre terracota, para quien prefiere
  /// tonos de alba. Terracota profunda sobre papel rosado (7.8:1).
  static const fusionFresca = AppPalette(
    id: AppPaletteId.fusionFresca,
    nombre: 'Amanecer',
    descripcion: 'Cálida y rosada, como la primera luz del día.',
    swatch: [
      Color(0xFFFBF1E9),
      Color(0xFFF6DDCB),
      Color(0xFFB98352),
      Color(0xFF6E3F2E),
    ],
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF6E3F2E),
      onPrimary: Color(0xFFFBF1E9),
      primaryContainer: Color(0xFFF6DDCB),
      onPrimaryContainer: Color(0xFF6E3F2E),
      secondary: Color(0xFF8A5F27),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF2E4CE),
      onSecondaryContainer: Color(0xFF4F3610),
      tertiary: Color(0xFF5C6E54),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFE2E8D6),
      onTertiaryContainer: Color(0xFF2E3B28),
      error: _errorLight,
      onError: _onErrorLight,
      errorContainer: _errorContainerLight,
      onErrorContainer: _onErrorContainerLight,
      surface: Color(0xFFFBF1E9),
      onSurface: Color(0xFF241F1B),
      surfaceContainerHighest: Color(0xFFF2E4D4),
      onSurfaceVariant: Color(0xFF5C554E),
      outline: Color(0xFFCFC2B0),
      outlineVariant: Color(0xFFE5DACA),
    ),
  );

  /// "Oliva y Salvia": variacion botanica sobre verdes de hoja. Oliva
  /// profunda sobre papel (7.2:1).
  static const naturalezaSerena = AppPalette(
    id: AppPaletteId.naturalezaSerena,
    nombre: 'Oliva y Salvia',
    descripcion: 'Botánica y serena, tonos de hoja y tierra.',
    swatch: [
      Color(0xFFF5F2E7),
      Color(0xFFE1E7D3),
      Color(0xFF7E9169),
      Color(0xFF3E5637),
    ],
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF3E5637),
      onPrimary: Color(0xFFF5F2E7),
      primaryContainer: Color(0xFFE1E7D3),
      onPrimaryContainer: Color(0xFF2C3F27),
      secondary: Color(0xFF8A5F27),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFEDE5CE),
      onSecondaryContainer: Color(0xFF4F3610),
      tertiary: Color(0xFF5A7161),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFDDE7DD),
      onTertiaryContainer: Color(0xFF2C3F33),
      error: _errorLight,
      onError: _onErrorLight,
      errorContainer: _errorContainerLight,
      onErrorContainer: _onErrorContainerLight,
      surface: Color(0xFFF5F2E7),
      onSurface: Color(0xFF1E211C),
      surfaceContainerHighest: Color(0xFFEAE5D2),
      onSurfaceVariant: Color(0xFF565B50),
      outline: Color(0xFFC3C1A9),
      outlineVariant: Color(0xFFDCDAC5),
    ),
  );

  /// "Vigilia" (oscura): para orar de noche. Verde-negro profundo (en la
  /// familia de la marca, no un navy ajeno), salvia clara como primario
  /// (9.4:1 sobre el fondo) y dorado suave como acento (8.7:1).
  static const maresProfundos = AppPalette(
    id: AppPaletteId.maresProfundos,
    nombre: 'Vigilia',
    descripcion: 'Oscura y silenciosa, para orar antes de dormir.',
    swatch: [
      Color(0xFF111F1A),
      Color(0xFF24523F),
      Color(0xFFA9C8B4),
      Color(0xFFD9B37C),
    ],
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFA9C8B4),
      onPrimary: Color(0xFF111F1A),
      primaryContainer: Color(0xFF24523F),
      onPrimaryContainer: Color(0xFFDCE8DE),
      secondary: Color(0xFFD9B37C),
      onSecondary: Color(0xFF3C2B10),
      secondaryContainer: Color(0xFF4F3D1E),
      onSecondaryContainer: Color(0xFFEBD7AE),
      tertiary: Color(0xFF9DBBAD),
      onTertiary: Color(0xFF11241C),
      tertiaryContainer: Color(0xFF2C4A3C),
      onTertiaryContainer: Color(0xFFDCE8DE),
      error: _errorDark,
      onError: _onErrorDark,
      errorContainer: _errorContainerDark,
      onErrorContainer: _onErrorContainerDark,
      surface: Color(0xFF111F1A),
      onSurface: Color(0xFFECE9E0),
      surfaceContainerHighest: Color(0xFF1C2F27),
      onSurfaceVariant: Color(0xFFB4BDB2),
      outline: Color(0xFF4E5F54),
      outlineVariant: Color(0xFF32423A),
    ),
  );

  static const List<AppPalette> all = [
    zafiroCalmo,
    fusionFresca,
    naturalezaSerena,
    maresProfundos,
  ];

  static AppPalette byId(AppPaletteId id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return zafiroCalmo;
  }

  /// Convierte el `String` guardado en SharedPreferences (nombre del
  /// enum) de vuelta a [AppPaletteId]. Devuelve `null` si no hay ninguno
  /// guardado.
  static AppPaletteId? idFromStringOrNull(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final value in AppPaletteId.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}
