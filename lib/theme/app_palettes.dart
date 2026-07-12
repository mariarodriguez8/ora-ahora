import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Identificador estable de cada paleta seleccionable (se guarda en
/// SharedPreferences como String; ver PrefsService.selectedPaletteId y
/// AppearanceService).
enum AppPaletteId {
  fusionFresca,
  naturalezaSerena,
  maresProfundos,
  zafiroCalmo,
}

/// Definicion de una paleta de color seleccionable por el usuario en
/// Ajustes > Apariencia, tomada del informe de investigacion de mercado.
///
/// Cada paleta se implementa como un [ColorScheme] Material 3 explicito
/// (no `ColorScheme.fromSeed`) para poder verificar A MANO, color por
/// color, que cada pareja texto/fondo (`primary`/`onPrimary`,
/// `secondary`/`onSecondary`, `surface`/`onSurface`, etc.) cumple como
/// minimo un contraste de 4.5:1 (WCAG 2.1 AA para texto normal), ya que
/// este entorno no tiene Flutter/Dart instalado para poder confiar en un
/// algoritmo automatico (`ColorScheme.fromSeed` no garantiza que un color
/// de marca arbitrario pasado como override tenga un "on-color" con
/// contraste seguro).
///
/// Formula usada para los calculos de contraste (WCAG):
///   L = 0.2126*R + 0.7152*G + 0.0722*B  (con R,G,B linearizados de sRGB)
///   contraste = (L_claro + 0.05) / (L_oscuro + 0.05)
/// Cuando el color de marca es demasiado claro/medio para sostener texto
/// blanco con contraste >=4.5:1 (p. ej. #599F9E, #96AB88, #84A2C9,
/// #72A6B7), se usa como "on-color" el tono de tinta oscura de la marca
/// (`AppColors.ink`, #262321) o el propio color mas oscuro de esa misma
/// paleta, verificado numericamente antes de fijarlo aqui.
class AppPalette {
  final AppPaletteId id;
  final String nombre;
  final String descripcion;
  final ColorScheme colorScheme;

  /// Los 4 colores de marca originales de la investigacion, en el orden
  /// en que se documentaron, solo para pintar el "swatch" de vista previa
  /// en el selector de Ajustes. No se usan directamente como color de
  /// texto (ver nota de contraste arriba).
  final List<Color> swatch;

  const AppPalette({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.colorScheme,
    required this.swatch,
  });

  bool get isDark => colorScheme.brightness == Brightness.dark;

  // Valores de error Material 3 estandar (documentados por Flutter),
  // reutilizados tal cual para no inventar combinaciones de contraste
  // para un caso (mensajes de error) que no es el foco de esta paleta.
  static const _errorLight = Color(0xFFBA1A1A);
  static const _onErrorLight = Colors.white;
  static const _errorContainerLight = Color(0xFFFFDAD6);
  static const _onErrorContainerLight = Color(0xFF410002);

  static const _errorDark = Color(0xFFFFB4AB);
  static const _onErrorDark = Color(0xFF690005);
  static const _errorContainerDark = Color(0xFF93000A);
  static const _onErrorContainerDark = Color(0xFFFFDAD6);

  /// "Fusión Fresca": clara, energetica. Colores: #F4CBD3, #F7CD9A,
  /// #B8D3EE, #599F9E. #599F9E es el mas oscuro/saturado de los 4
  /// (luminancia ~0.29), insuficiente para texto blanco (contraste
  /// ~3.05:1), por lo que su on-color es AppColors.ink (contraste
  /// verificado ~5.1:1).
  static const fusionFresca = AppPalette(
    id: AppPaletteId.fusionFresca,
    nombre: 'Fusión Fresca',
    descripcion: 'Clara y energética, ideal para orar durante el día.',
    swatch: [
      Color(0xFFF4CBD3),
      Color(0xFFF7CD9A),
      Color(0xFFB8D3EE),
      Color(0xFF599F9E),
    ],
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF599F9E),
      onPrimary: AppColors.ink,
      primaryContainer: Color(0xFFB8D3EE),
      onPrimaryContainer: AppColors.ink,
      secondary: Color(0xFFF7CD9A),
      onSecondary: AppColors.ink,
      secondaryContainer: Color(0xFFF4CBD3),
      onSecondaryContainer: AppColors.ink,
      tertiary: Color(0xFFB8D3EE),
      onTertiary: AppColors.ink,
      tertiaryContainer: Color(0xFFF7CD9A),
      onTertiaryContainer: AppColors.ink,
      error: _errorLight,
      onError: _onErrorLight,
      errorContainer: _errorContainerLight,
      onErrorContainer: _onErrorContainerLight,
      surface: Color(0xFFFFF8F9),
      onSurface: AppColors.ink,
      outline: Color(0xFF599F9E),
    ),
  );

  /// "Naturaleza Serena": clara, botanica. Colores: #FDF1DB, #DFD5C6,
  /// #96AB88, #597B60. #597B60 (verde profundo, luminancia ~0.17) SI
  /// alcanza 4.5:1 con texto blanco (contraste calculado ~4.75:1).
  static const naturalezaSerena = AppPalette(
    id: AppPaletteId.naturalezaSerena,
    nombre: 'Naturaleza Serena',
    descripcion: 'Clara y botánica, tonos de tierra y hoja.',
    swatch: [
      Color(0xFFFDF1DB),
      Color(0xFFDFD5C6),
      Color(0xFF96AB88),
      Color(0xFF597B60),
    ],
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF597B60),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDFD5C6),
      onPrimaryContainer: AppColors.ink,
      secondary: Color(0xFF96AB88),
      onSecondary: AppColors.ink,
      secondaryContainer: Color(0xFFFDF1DB),
      onSecondaryContainer: AppColors.ink,
      tertiary: Color(0xFFDFD5C6),
      onTertiary: AppColors.ink,
      tertiaryContainer: Color(0xFFFDF1DB),
      onTertiaryContainer: AppColors.ink,
      error: _errorLight,
      onError: _onErrorLight,
      errorContainer: _errorContainerLight,
      onErrorContainer: _onErrorContainerLight,
      surface: Color(0xFFFDF1DB),
      onSurface: AppColors.ink,
      outline: Color(0xFF96AB88),
    ),
  );

  /// "Mares Profundos": oscura, nocturna/calma. Colores: #EDEDEE,
  /// #D6E0EA, #72A6B7, #092846. Fondo = #092846 (el mas oscuro, unico
  /// candidato razonable a `surface` en un tema oscuro); texto principal
  /// = #EDEDEE (contraste contra el fondo ~12.8:1). #72A6B7 como
  /// `primary` no alcanza 4.5:1 con texto blanco NI con #EDEDEE, asi que
  /// su on-color es el propio #092846 (contraste verificado ~5.6:1).
  static const maresProfundos = AppPalette(
    id: AppPaletteId.maresProfundos,
    nombre: 'Mares Profundos',
    descripcion: 'Oscura y nocturna, para orar antes de dormir.',
    swatch: [
      Color(0xFFEDEDEE),
      Color(0xFFD6E0EA),
      Color(0xFF72A6B7),
      Color(0xFF092846),
    ],
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF72A6B7),
      onPrimary: Color(0xFF092846),
      primaryContainer: Color(0xFFD6E0EA),
      onPrimaryContainer: Color(0xFF092846),
      secondary: Color(0xFFD6E0EA),
      onSecondary: Color(0xFF092846),
      secondaryContainer: Color(0xFFEDEDEE),
      onSecondaryContainer: Color(0xFF092846),
      tertiary: Color(0xFF72A6B7),
      onTertiary: Color(0xFF092846),
      tertiaryContainer: Color(0xFFD6E0EA),
      onTertiaryContainer: Color(0xFF092846),
      error: _errorDark,
      onError: _onErrorDark,
      errorContainer: _errorContainerDark,
      onErrorContainer: _onErrorContainerDark,
      surface: Color(0xFF092846),
      onSurface: Color(0xFFEDEDEE),
      outline: Color(0xFF72A6B7),
    ),
  );

  /// "Zafiro Calmo": clara, minimalista de alto contraste. Colores:
  /// #FFFFFF, #D6E0EA, #84A2C9, #1C1D37. #1C1D37 (casi negro azulado)
  /// contra #FFFFFF da un contraste ~16.4:1 (muy por encima del minimo
  /// AA), por lo que esta es la paleta por defecto/mas accesible.
  static const zafiroCalmo = AppPalette(
    id: AppPaletteId.zafiroCalmo,
    nombre: 'Zafiro Calmo',
    descripcion: 'Minimalista y de alto contraste (recomendada).',
    swatch: [
      Color(0xFFFFFFFF),
      Color(0xFFD6E0EA),
      Color(0xFF84A2C9),
      Color(0xFF1C1D37),
    ],
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF1C1D37),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD6E0EA),
      onPrimaryContainer: Color(0xFF1C1D37),
      secondary: Color(0xFF84A2C9),
      onSecondary: Color(0xFF1C1D37),
      secondaryContainer: Color(0xFFD6E0EA),
      onSecondaryContainer: Color(0xFF1C1D37),
      tertiary: Color(0xFF84A2C9),
      onTertiary: Color(0xFF1C1D37),
      tertiaryContainer: Color(0xFFD6E0EA),
      onTertiaryContainer: Color(0xFF1C1D37),
      error: _errorLight,
      onError: _onErrorLight,
      errorContainer: _errorContainerLight,
      onErrorContainer: _onErrorContainerLight,
      surface: Colors.white,
      onSurface: Color(0xFF1C1D37),
      outline: Color(0xFF84A2C9),
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

  /// Convierte el `String` guardado en SharedPreferences (nombre del enum,
  /// ej. "zafiroCalmo") de vuelta a [AppPaletteId]. Devuelve `null` si no
  /// hay ninguno guardado (para poder distinguir "sin preferencia
  /// explicita" de "eligio Zafiro Calmo a mano").
  static AppPaletteId? idFromStringOrNull(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final value in AppPaletteId.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}
