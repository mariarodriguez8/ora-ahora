import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Barra superior compartida por TODAS las pantallas del onboarding:
/// boton de volver + puntos de progreso. v11c: la ovejita (que eres tu,
/// Juan 10:27) CAMINA sobre los puntos y avanza contigo en cada paso —
/// asi la mascota acompana todo el onboarding de forma coherente con la
/// narrativa "tu caminar con el Pastor".
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
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    // Ancho fijo de la fila de puntos: (totalSteps) puntos de 7px con
    // 6px de margen + 13px extra del punto activo (que mide 20px).
    final dotsWidth = totalSteps * 13.0 + 13.0;
    final sheepX = totalSteps <= 1
        ? 0.0
        : -1.0 + 2.0 * (step.clamp(0, totalSteps - 1)) / (totalSteps - 1);

    return SizedBox(
      height: preferredSize.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _BackCircle(onTap: onBack ?? () => Navigator.of(context).maybePop()),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // La ovejita avanza hasta quedar sobre el punto activo.
                SizedBox(
                  width: dotsWidth,
                  height: 26,
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment(sheepX, 1),
                    child: Image.asset(
                      'assets/mascot/ovejita.png',
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
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
              ],
            ),
            const Spacer(),
            const SizedBox(width: 40),
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
