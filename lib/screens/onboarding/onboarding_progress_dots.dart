import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class OnboardingTopBar extends StatelessWidget implements PreferredSizeWidget {
  final int step; // 0-indexado
  final int totalSteps;
  final VoidCallback? onBack;

  const OnboardingTopBar({
    super.key,
    required this.step,
    this.totalSteps = 3,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: preferredSize.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _BackCircle(onTap: onBack ?? () => Navigator.of(context).maybePop()),
            const Spacer(),
            Row(
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
