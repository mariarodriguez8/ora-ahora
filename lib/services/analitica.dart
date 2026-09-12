import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Un unico sitio para la analitica, por dos razones:
///
/// 1. Los nombres de evento no se escriben a mano en dieciocho pantallas.
///    Si se desalinean, el embudo sale roto y no te enteras hasta tarde.
/// 2. En las pruebas no hay canal nativo. Si no se ha arrancado, todo esto
///    no hace nada en vez de reventar los 61 tests.
class Analitica {
  static const _clave = 'phc_tYvwsUFXw68kqHMk2LmtCLPWxQcv74rzzdo5hQ5JPa5b';
  static const _host = 'https://us.i.posthog.com';

  static bool _viva = false;

  /// Se llama una vez, en main(), antes de runApp.
  static Future<void> arrancar() async {
    if (_viva) return;
    try {
      final config = PostHogConfig(_clave)
        ..host = _host
        ..sessionReplay = true
        ..debug = kDebugMode;
      await Posthog().setup(config);
      _viva = true;
    } catch (_) {
      // Sin canal nativo (pruebas) o sin red: la app sigue igual de bien.
      _viva = false;
    }
  }

  static Future<void> _mandar(String nombre, [Map<String, Object>? props]) async {
    if (!_viva) return;
    try {
      await Posthog().capture(eventName: nombre, properties: props);
    } catch (_) {
      // La analitica nunca puede tumbar la app.
    }
  }

  // --- El embudo ---

  /// Se dispara al pintar cada pantalla del onboarding.
  /// En PostHog el embudo se arma con este evento filtrando por `paso`.
  static Future<void> pasoOnboarding(int paso, String pantalla) =>
      _mandar('onboarding_paso_visto', {'paso': paso, 'pantalla': pantalla});

  static Future<void> onboardingTerminado() =>
      _mandar('onboarding_terminado');


  /// Nombre legible de cada una de las 18 posiciones del embudo.
  /// Coincide con la barra de progreso que ve el usuario.
  static const nombres = <int, String>{
    1: 'nombre',
    2: 'te_ha_pasado',
    3: 'horas_celular',
    4: 'tiempo_con_dios',
    5: 'el_espejo',
    6: 'ten_parabola',
    7: 'ketsu_telefono',
    8: 'el_minuto',
    9: 'la_cancion',
    10: 'temas',
    11: 'horarios',
    12: 'plan',
    13: 'prueba_social',
    14: 'primera_oracion',
    15: 'pacto',
    16: 'compromiso',
    17: 'recordatorios',
    18: 'permisos',
  };

  static int _ultimoPaso = -1;

  /// Se llama desde build(). Guarda el ultimo paso para no mandar
  /// veinte eventos por cada repintado de la misma pantalla.
  static void pasoVisto(int paso) {
    if (_ultimoPaso == paso) return;
    _ultimoPaso = paso;
    pasoOnboarding(paso, nombres[paso] ?? 'paso_$paso');
  }
  // --- El dinero ---

  static Future<void> paywallVisto(String origen) =>
      _mandar('paywall_visto', {'origen': origen});

  static Future<void> compraHecha(String producto) =>
      _mandar('compra_hecha', {'producto': producto});

  // --- El bucle diario, que es lo que dice si la app retiene ---

  static Future<void> pausaAtendida() => _mandar('pausa_atendida');

  static Future<void> oracionTerminada(String origen) =>
      _mandar('oracion_terminada', {'origen': origen});

  /// Para lo que no tenga metodo propio todavia.
  static Future<void> evento(String nombre, [Map<String, Object>? props]) =>
      _mandar(nombre, props);
}
