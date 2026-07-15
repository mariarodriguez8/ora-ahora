import 'package:flutter/material.dart';

/// Escala tipografica "Santuario" de Ora Ahora.
///
/// Dos familias empaquetadas en `assets/fonts/` (licencia OFL, sin
/// dependencia de red ni de paquetes externos):
///
/// - **Fraunces** (serif calida, optica "Soft"): titulos, momentos hero y
///   el texto de las oraciones. Es la voz "devocional/editorial" de la
///   app — lo que la separa visualmente de una app generica de Material.
/// - **Figtree** (sans geometrica amable): todo el texto de interfaz
///   (botones, etiquetas, cuerpo de apoyo, ajustes).
///
/// Se conservan los nombres de estilo historicos (`display`, `headline`,
/// `title`, `body`, `bodyLarge`, `caption`) para no romper referencias, y
/// se agregan `prayerText` y `quote` para el texto devocional.
class AppTypography {
  AppTypography._();

  static const String serifFamily = 'Fraunces';
  static const String sansFamily = 'Figtree';

  /// Momentos hero: titulo de bienvenida, titulos de oracion, numeros de
  /// racha grandes. Serif, con interlineado compacto.
  static const TextStyle display = TextStyle(
    fontFamily: serifFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.12,
  );

  /// Titulos de seccion ("Para ti", pantallas internas). Serif.
  static const TextStyle headline = TextStyle(
    fontFamily: serifFamily,
    fontSize: 23,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.18,
  );

  /// Titulos de tarjeta y filas. Sans con peso alto.
  static const TextStyle title = TextStyle(
    fontFamily: sansFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontFamily: sansFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: sansFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.55,
  );

  /// Etiquetas cortas y overlines (categoria, "PARA HOY", metadatos).
  /// Mayusculas con tracking ancho = sensacion de etiqueta cuidada.
  static const TextStyle caption = TextStyle(
    fontFamily: sansFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
    height: 1.3,
  );

  /// Texto completo de una oracion: serif regular, cuerpo grande y aire
  /// generoso — debe leerse como un libro devocional, no como UI.
  static const TextStyle prayerText = TextStyle(
    fontFamily: serifFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.65,
  );

  /// Referencias biblicas y citas: serif italica.
  static const TextStyle quote = TextStyle(
    fontFamily: serifFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    letterSpacing: 0.1,
    height: 1.45,
  );
}
