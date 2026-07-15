import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';
import 'onboarding_name_screen.dart';

/// Bienvenida "WOW" 2026: fondo degradado profundo (como el logo), halo
/// de luz dorado que respira con una cruz luminosa, y texto marfil.
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

  @override
  Widget build(BuildContext context) {
    final fadeIn = CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic));
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_indigo, _esmeralda],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                // Halo con cruz de luz que respira
                Center(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      final v = 0.92 + 0.08 * _pulse.value;
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
                                    color: _dorado.withValues(alpha: 0.55),
                                    blurRadius: 26,
                                  ),
                                ],
                              ),
                            ),
                            // cruz de luz (geometria fija 84x84)
                            SizedBox(
                              width: 84,
                              height: 84,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 13,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      color: _marfil,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _dorado.withValues(alpha: 0.9),
                                          blurRadius: 22,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Align(
                                    alignment: const Alignment(0, -0.42),
                                    child: Container(
                                      width: 56,
                                      height: 13,
                                      decoration: BoxDecoration(
                                        color: _marfil,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
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
                        'Oraciones que se sienten tuyas, una pausa antes '
                        'de las apps que te roban la paz, y una fe que '
                        'crece día a día 🌱',
                        style: AppTypography.bodyLarge.copyWith(
                            color: _marfil.withValues(alpha: 0.78)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _dorado,
                      foregroundColor: const Color(0xFF241F10),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const OnboardingNameScreen()),
                      );
                    },
                    child: const Text('Comenzar mi camino 🙏'),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Gratis · Menos de 2 minutos',
                    style: AppTypography.caption
                        .copyWith(color: _marfil.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
