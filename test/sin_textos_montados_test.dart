// Caza textos montados y desbordes antes de que lleguen al telefono.
//
// Flutter registra los desbordes ("RenderFlex overflowed by N pixels")
// como excepciones durante el pintado, asi que basta con renderizar cada
// pantalla y comprobar que no salto ninguna.
//
// Se prueba en el movil mas pequeno que se usa de verdad en Latinoamerica
// (320 de ancho) y con la letra al maximo que la app permite (1.3), que es
// la combinacion donde todo se rompe.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ora_ahora/services/prefs_service.dart';
import 'package:ora_ahora/theme/app_theme.dart';
import 'package:ora_ahora/widgets/camino_hoy.dart';
import 'package:ora_ahora/screens/onboarding/funnel_screens.dart';

/// Los tamanos reales donde hay que aguantar.
const _pantallas = <String, Size>{
  'movil pequeno': Size(320, 600),
  'movil normal': Size(360, 740),
  'movil grande': Size(412, 915),
};

/// Letra normal y letra al tope que permite la app.
const _escalas = <double>[1.0, 1.3];

/// Las pantallas del embudo, que son las que llevan el texto mas grande
/// y por tanto las que primero se rompen con la letra al maximo.
const _delEmbudo = <String, Widget>{
  '1 te ha pasado': FunnelQ1(),
  '2 horas de celular': FunnelQ2(),
  '3 tiempo con Dios': FunnelQ3(),
  '4 el espejo': FunnelMirror(),
  '5 la gracia': FunnelGrace(),
  '6 el minuto': FunnelMinute(),
  '7 el regalo': FunnelRegalo(),
  '8 la cancion': FunnelCancion(),
};

Future<void> _pintarPantalla(
  WidgetTester tester,
  Widget pantalla, {
  required Size tamano,
  required double escala,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: tamano,
          textScaler: TextScaler.linear(escala),
        ),
        child: pantalla,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

Future<void> _pintar(
  WidgetTester tester,
  Widget hijo, {
  required Size tamano,
  required double escala,
  required PrefsService prefs,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Provider<PrefsService>.value(
      value: prefs,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: tamano,
            textScaler: TextScaler.linear(escala),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: hijo,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  late PrefsService prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'flutter.camino_inicio': 20260901,
      'flutter.camino_dias': 30,
      'flutter.tope_pausas': 3,
      'flutter.pausas_dia': 0,
      'flutter.pausas_hoy': 0,
    });
    prefs = await PrefsService.create();
  });

  group('La tarjeta del camino aguanta', () {
    for (final pantalla in _pantallas.entries) {
      for (final escala in _escalas) {
        testWidgets('${pantalla.key} con letra x$escala', (tester) async {
          await _pintar(
            tester,
            const CaminoHoy(),
            tamano: pantalla.value,
            escala: escala,
            prefs: prefs,
          );
          expect(tester.takeException(), isNull,
              reason: 'Algo se desborda en ${pantalla.key} a x$escala');
        });
      }
    }
  });

  group('Las pantallas del embudo aguantan', () {
    for (final pantalla in _delEmbudo.entries) {
      for (final escala in _escalas) {
        testWidgets('${pantalla.key} a x$escala en movil pequeno',
            (tester) async {
          await _pintarPantalla(
            tester,
            pantalla.value,
            tamano: const Size(320, 600),
            escala: escala,
          );
          expect(tester.takeException(), isNull,
              reason: 'Se desborda: ${pantalla.key} a x$escala');
        });
      }
    }
  });
}
