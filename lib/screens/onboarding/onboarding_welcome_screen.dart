import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';
import '../../widgets/colina.dart';
import '../../widgets/titular_escalonado.dart';
import 'onboarding_name_screen.dart';

/// La primera pantalla de la app.
///
/// La anterior era una cruz dentro de un circulo dorado sobre un texto que
/// casi no se leia: generica, sin la ovejita, sin la pradera y sin nada
/// del lenguaje visual del resto. Y era lo primero que veia todo el mundo.
///
/// Esta abre con lo que la persona siente al bajar la app (que Dios sabe
/// por lo que esta pasando) y con el motivo por el que quiere acercarse,
/// no con una promesa de funcionalidad. La ilustracion dice lo mismo sin
/// palabras: una mano que entra desde fuera y se queda.
class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  static const _marfil = Color(0xFFF5F0E4);
  static const _dorado = Color(0xFFD9A93C);
  static const _fondo = Color(0xFF16342B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Colina(base: const Color(0xFF14332A), altura: 300),
          ),
          // La mano entra por la izquierda y cruza hacia la cabeza: esa
          // diagonal es lo que aleja la escena de la estampa simetrica.
          Positioned(
            left: -26,
            right: -10,
            bottom: 110,
            child: IgnorePointer(
              child: Image.asset(
                'assets/mascot/ovejita_consuelo.png',
                height: MediaQuery.of(context).size.height * 0.42,
                fit: BoxFit.contain,
                alignment: Alignment.bottomLeft,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                    decoration: BoxDecoration(
                      color: _marfil.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Gratis',
                      style: AppTypography.caption.copyWith(color: _marfil),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const TitularEscalonado(
                    frase: 'Él ya sabe\npor lo que estás pasando.\n'
                        '*Y no quiere que lo pases sin Él.*',
                    color: _marfil,
                    acento: _dorado,
                    base: 27,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ven como estás.\nNo hace falta más:\n'
                    'solo recibe la compañía del Padre.',
                    style: AppTypography.body.copyWith(
                      color: _marfil,
                      height: 1.4,
                      shadows: const [
                        Shadow(color: _fondo, blurRadius: 12),
                        Shadow(color: _fondo, blurRadius: 22),
                      ],
                    ),
                  ),
                const Spacer(),
                const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _marfil,
                        foregroundColor: _fondo,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const OnboardingNameScreen(),
                        ),
                      ),
                      child: const Text('Empezar'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const OnboardingNameScreen(),
                        ),
                      ),
                      child: Text(
                        'Ya tengo cuenta',
                        style: AppTypography.body.copyWith(
                          color: _marfil.withValues(alpha: 0.66),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
