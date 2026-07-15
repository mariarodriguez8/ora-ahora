import 'package:flutter/material.dart';

/// Paleta de marca "Santuario" de Ora Ahora.
///
/// Direccion visual: un espacio de oracion calido y editorial — verde
/// abeto profundo como color de marca (recogimiento, naturaleza), papel
/// marfil como fondo (calidez de libro devocional, nunca blanco frio) y
/// un dorado viejo como unico acento (lo sagrado, usado con moderacion).
///
/// NOTA sobre los nombres: se conservan los nombres de campo historicos
/// (`tealDeep`, `cream`, `amber`, ...) aunque los valores ya no son
/// literalmente "teal"/"amber", para no romper ninguna referencia
/// existente en las pantallas. El significado semantico se mantiene:
/// `tealDeep` = color de marca profundo, `cream` = fondo papel,
/// `amber` = acento dorado, etc.
class AppColors {
  AppColors._();

  /// Verde abeto profundo: color de marca principal (texto sobre claro,
  /// botones primarios, fondo hero). Contraste sobre [cream]: 12.1:1.
  static const Color tealDeep = Color(0xFF16342B);

  /// Verde medio para superficies de marca menos dominantes.
  static const Color tealMedium = Color(0xFF2C5747);

  /// Niebla de salvia: contenedor claro de marca (chips, iconos
  /// circulares, bordes suaves).
  static const Color tealLight = Color(0xFFDCE8DE);

  /// Papel marfil: fondo principal de toda la app.
  static const Color cream = Color(0xFFF7F3EA);

  /// Arena calida: segunda superficie clara (tarjetas tonales, pildoras).
  static const Color sand = Color(0xFFEDE5D2);

  /// Dorado viejo: acento sagrado. Contraste sobre [cream]: 5.1:1
  /// (apto para texto normal, WCAG AA).
  static const Color amber = Color(0xFF8A5F27);

  /// Dorado claro para fondos de acento suaves.
  static const Color amberLight = Color(0xFFEBD7AE);

  /// Tinta calida (texto principal). Contraste sobre [cream]: 15:1.
  static const Color ink = Color(0xFF1C1F1D);

  /// Tinta suave (texto secundario). Contraste sobre [cream]: 6.4:1.
  static const Color inkSoft = Color(0xFF545A52);

  static const Color danger = Color(0xFFA93F2E);
  static const Color success = Color(0xFF3E6B4A);
}
