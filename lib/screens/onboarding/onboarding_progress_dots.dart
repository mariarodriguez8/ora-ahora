import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Barra superior compartida por TODAS las pantallas del onboarding:
/// boton de volver + puntos de progreso + la ovejita.
///
/// v11d (pedido de Maria): la ovejita aparece COMPLETA (nunca recortada)
/// en la esquina superior, alternando lado y POSE segun la pantalla —
/// pensativa con signo de interrogacion cuando se pregunta el nombre,
/// orando antes de la primera oracion, celebrando en el pacto, etc.
class OnboardingTopBar extends StatelessWidget implements PreferredSizeWidget {
  final int step; // 0-indexado
  final int totalSteps;
  final VoidCallback? onBack;

  const OnboardingTopBar({
    super.key,
    required this.step,
    this.totalSteps = 10,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76);

  /// Pose de la ovejita y lado (true = derecha) por paso del onboarding.
  /// 0 nombre · 1 temas · 2 horarios · 3 plan · 4 testimonio ·
  /// 5 primera oracion · 6 pacto · 7 recordatorios · 8 permisos · 9 final
  static (String, bool) _poseFor(int step) {
    switch (step) {
      case 0:
        return ('assets/mascot/ovejita_pensativa.png', true);
      case 1:
        return ('assets/mascot/ovejita_esperando.png', false);
      case 2:
        return ('assets/mascot/ovejita.png', true);
      case 3:
        return ('assets/mascot/ovejita_pensativa.png', false);
      case 4:
        return ('assets/mascot/ovejita_celebrando.png', true);
      case 5:
        return ('assets/mascot/ovejita_orando.png', false);
      case 6:
        return ('assets/mascot/ovejita_celebrando.png', true);
      case 7:
        return ('assets/mascot/ovejita_esperando.png', false);
      case 8:
        return ('assets/mascot/ovejita.png', true);
      default:
        return ('assets/mascot/ovejita_celebrando.png', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (asset, right) = _poseFor(step);

    // La ovejita entra con un pequeno "pop" suave, completa y visible.
    final sheep = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Image.asset(
        asset,
        height: 56,
        fit: BoxFit.contain,
      ),
    );

    return SizedBox(
      height: preferredSize.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _BackCircle(onTap: onBack ?? () => Navigator.of(context).maybePop()),
            if (!right) ...[const SizedBox(width: 10), sheep],
            const Spacer(),
            _BarraProgreso(fraccion: _fraccionPara(step)),
            const Spacer(),
            if (right)
              sheep
            else
              const SizedBox(width: 56),
          ],
        ),
      ),
    );
  }
}

class _BackCircle extends StatelessWidget {
  final VoidCallback onTap;
  const _BackCircle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tealLight.withOpacity(0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_rounded, color: AppColors.tealDeep, size: 20),
        ),
      ),
    );
  }
}

/// Progreso ponderado por esfuerzo, no por numero de pantallas.
///
/// Cuando aparece esta barra la persona ya paso ocho pantallas del embudo,
/// asi que arranca lejos de cero: eso es cierto, no un truco. Y avanza mas
/// en los pasos que cuestan poco (mirar el plan, leer el testimonio) que en
/// los que cuestan de verdad (firmar el pacto, dar permisos). El resultado
/// es la curva que engancha: rapido al principio, mas lento cuando ya
/// invertiste demasiado como para irte.
double _fraccionPara(int step) {
  const tramos = <double>[
    0.24, 0.35, 0.46, 0.56, 0.64, 0.73, 0.85, 0.91, 0.97, 1.00,
  ];
  if (step < 0) return tramos.first;
  if (step >= tramos.length) return 1;
  return tramos[step];
}

class _BarraProgreso extends StatelessWidget {
  final double fraccion;
  const _BarraProgreso({required this.fraccion});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            Container(color: AppColors.tealLight),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOut,
              widthFactor: fraccion.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(color: AppColors.tealDeep),
            ),
          ],
        ),
      ),
    );
  }
}
