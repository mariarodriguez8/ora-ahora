import 'package:flutter/material.dart';

/// Escala tipografica de Ora Ahora, basada unicamente en la fuente de
/// sistema (Roboto en Android) para no depender de ningun paquete de
/// fuentes externas (no hay acceso a internet en el entorno de
/// desarrollo para traer `google_fonts` ni archivos de fuente propios).
///
/// La jerarquia "premium" se construye SIN una fuente nueva, jugando con
/// tres palancas que si estan disponibles con la fuente de sistema:
/// 1. Mayor contraste de tamaño entre niveles (el "display" ahora es
///    notablemente mas grande que el "headline", en vez de una escala
///    plana donde todo se ve parecido).
/// 2. Contraste de peso mas deliberado (w800 solo para el momento "hero"
///    del display, w700 para headline, w600 para title, dejando w400/w500
///    para texto de apoyo).
/// 3. `letterSpacing` afinado por nivel: ligeramente negativo en los
///    tamaños grandes (mas denso y confiado, como en apps premium) y
///    ligeramente positivo/ancho en `caption`/`overline` (sensacion de
///    "etiqueta" cuidada, no un texto pequeño descuidado).
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Roboto';

  /// Momentos "hero": numero de racha grande, titulo de bienvenida del
  /// onboarding, etc. Antes no existia un nivel por encima de `display`;
  /// se usa el propio `display` con mas tamaño/peso que antes.
  static const TextStyle display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.55,
  );

  /// Usado en etiquetas cortas (chips, metadatos, "hace 2 min"). El
  /// `letterSpacing` positivo y el peso medio le dan una sensacion de
  /// etiqueta cuidada en vez de "texto pequeño olvidado".
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    height: 1.3,
  );
}
