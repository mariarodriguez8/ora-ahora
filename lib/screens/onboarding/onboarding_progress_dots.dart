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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(totalSteps, (i) {
                final active = i == step;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active ? AppColors.tealDeep : AppColors.tealLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
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
