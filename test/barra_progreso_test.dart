import 'package:flutter_test/flutter_test.dart';
import 'package:ora_ahora/screens/onboarding/onboarding_progress_dots.dart'
    show progresoPonderado, kPasosOnboarding;

/// Orden real del embudo, 18 pantallas:
///   1       el nombre
///   2 a 9   las 8 del embudo narrativo
///   10 a 18 el resto del onboarding
void main() {
  test('La barra nunca retrocede', () {
    var anterior = -1.0;
    for (var i = 1; i <= kPasosOnboarding; i++) {
      final f = progresoPonderado(i, kPasosOnboarding);
      expect(f, greaterThan(anterior),
          reason: 'la pantalla $i pinta $f y la anterior $anterior');
      anterior = f;
    }
  });

  test('Las primeras 7 pantallas corren rapido', () {
    // Al acabar la septima el usuario debe sentir que ya va por dos tercios.
    expect(progresoPonderado(7, kPasosOnboarding), greaterThan(0.60));
  });

  test('Los extremos son limpios', () {
    expect(progresoPonderado(0, kPasosOnboarding), 0);
    expect(progresoPonderado(kPasosOnboarding, kPasosOnboarding), 1);
  });
}
