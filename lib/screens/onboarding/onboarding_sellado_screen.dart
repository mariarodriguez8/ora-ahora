import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'funnel_base.dart';

/// La celebracion del pacto.
///
/// Acaba de firmar algo que le costo. Si lo siguiente que ve es un precio,
/// el momento se pierde. Esta pantalla no pide nada: solo se queda dos
/// segundos en silencio para que el gesto exista.
class OnboardingSelladoScreen extends StatefulWidget {
  const OnboardingSelladoScreen({super.key});

  @override
  State<OnboardingSelladoScreen> createState() =>
      _OnboardingSelladoScreenState();
}

class _OnboardingSelladoScreenState extends State<OnboardingSelladoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _mostrarBoton = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    // Dos segundos sin salida. El silencio es lo que hace el momento.
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _mostrarBoton = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nombre = FunnelAnswers.nombre;
    return Scaffold(
      backgroundColor: AppColors.amberLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 34),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
                child: Image.asset('assets/mascot/ovejita_celebrando.png',
                    height: 210, fit: BoxFit.contain),
              ),
              const SizedBox(height: 26),
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _c,
                  curve: const Interval(0.45, 1, curve: Curves.easeOut),
                ),
                child: Column(
                  children: [
                    Text('Queda escrito.',
                        textAlign: TextAlign.center,
                        style: AppTypography.display.copyWith(
                          fontSize: 34,
                          color: AppColors.tealDeep,
                        )),
                    const SizedBox(height: 12),
                    Text(
                      nombre.isEmpty
                          ? 'Hoy volviste. Él ya lo sabe.'
                          : '$nombre, hoy volviste. Él ya lo sabe.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.amber,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AnimatedOpacity(
                opacity: _mostrarBoton ? 1 : 0,
                duration: const Duration(milliseconds: 500),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _mostrarBoton
                        ? () => Navigator.of(context).pop()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealDeep,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text('Continuar',
                        style: AppTypography.title.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
