import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';
import 'onboarding_name_screen.dart';

/// Bienvenida "WOW" 2026: fondo degradado profundo (como el logo), halo
/// de luz dorado que respira con una CRUZ LUMINOSA (restaurada en v11c),
/// y la ovejita — que eres tu (Juan 10:27) — asomandose desde la esquina
/// inferior derecha de la pantalla, mirando hacia la cruz.
///
/// v11c: se deshace el experimento de v11a de meter a la ovejita DENTRO
/// del halo (el recorte tenia fondo y se veia un rectangulo verde dentro
/// del circulo). La cruz vuelve a ser la protagonista del halo, como
/// estaba antes, y la mascota entra por la esquina con su recorte
/// transparente real (assets/mascot/ovejita_esperando.png, mirando hacia
/// arriba), sin tocar el resto de la composicion.
class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _entrance;

  static const _indigo = Color(0xFF18163A);
  static const _esmeralda = Color(0xFF0A3A30);
  static const _dorado = Color(0xFFFFD18C);
  static const _marfil = Color(0xFFF7F3EA);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..forward();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Widget _luz(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _dorado.withValues(alpha: opacity),
              blurRadius: size * 0.45,
              spreadRadius: size * 0.08,
            ),
          ],
        ),
      );

  /// Barra redondeada y luminosa (marfil→dorado) para armar la cruz de
  /// luz. [glow] varia con el pulso para que la cruz "respire" junto con
  /// el halo.
  Widget _barraDeLuz({
    required double width,
    required double height,
    required double glow,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_marfil, _dorado],
        ),
        boxShadow: [
          BoxShadow(
            color: _dorado.withValues(alpha: glow),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fadeIn = CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic));
    // La ovejita entra deslizandose desde la esquina, con la misma curva
    // de entrada del resto de la pantalla.
    final sheepIn = CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic));
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_indigo, _esmeralda],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    // Halo con cruz de luz que respira (como antes de v11a)
                    Center(
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final v = 0.92 + 0.08 * _pulse.value;
                          final glow = 0.55 + 0.25 * _pulse.value;
                          return Transform.scale(
                            scale: v,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _luz(210, 0.22 + 0.12 * _pulse.value),
                                Container(
                                  width: 190,
                                  height: 190,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: _marfil, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            _dorado.withValues(alpha: 0.55),
                                        blurRadius: 26,
                                      ),
                                    ],
                                  ),
                                ),
                                // Cruz de luz: brazo vertical + brazo
                                // horizontal un poco por encima del centro.
                                SizedBox(
                                  width: 160,
                                  height: 160,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      _barraDeLuz(
                                        width: 13,
                                        height: 96,
                                        glow: glow,
                                      ),
                                      Transform.translate(
                                        offset: const Offset(0, -16),
                                        child: _barraDeLuz(
                                          width: 64,
                                          height: 13,
                                          glow: glow,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    FadeTransition(
                      opacity: fadeIn,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tu momento\ncon Dios,\ntodos los días',
                            style: AppTypography.display
                                .copyWith(fontSize: 38, color: _marfil),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Una oración al día. Y una pausa antes de '
                  'abrir las apps que te distraen.',
                            style: AppTypography.bodyLarge.copyWith(
                                color: _marfil.withValues(alpha: 0.78)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    // El boton deja aire a la derecha para que la ovejita
                    // de la esquina no lo tape.
                    Padding(
                      padding: const EdgeInsets.only(right: 96),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dorado,
                            foregroundColor: const Color(0xFF241F10),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const OnboardingNameScreen()),
                            );
                          },
                          child: const Text('Comenzar mi camino 🙏'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 96),
                      child: Center(
                        child: Text(
                          'Gratis · unos minutos',
                          style: AppTypography.caption.copyWith(
                              color: _marfil.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // La ovejita asoma desde la esquina inferior derecha de la
            // PANTALLA (recorte transparente, mirando hacia la cruz),
            // entrando con un deslizamiento suave.
            Positioned(
              right: 16,
              bottom: 10,
              child: AnimatedBuilder(
                animation: sheepIn,
                builder: (context, child) {
                  final t = sheepIn.value;
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(40 * (1 - t), 0),
                      child: child,
                    ),
                  );
                },
                // v11d: la mascota OFICIAL, completa y sin recortar.
                child: Image.asset(
                  'assets/mascot/ovejita.png',
                  height: 124,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
