import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'onboarding_first_prayer_screen.dart';
import 'onboarding_progress_dots.dart';

class OnboardingSocialScreen extends StatelessWidget {
  const OnboardingSocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const OnboardingTopBar(step: 4),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No vas a caminar\nesto a solas ✨',
                  style: AppTypography.display.copyWith(fontSize: 28)),
              const SizedBox(height: 12),
              Text(
                'No estás en esto por tu cuenta. Cada día, miles de personas '
                'en toda Hispanoamérica paran un minuto para lo mismo que tú.',
                style:
                    AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.tealLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"Antes abría Instagram sin pensar. Ahora, muchas de '
                      'esas veces, termino orando. Mi ansiedad ya no manda."',
                      style: AppTypography.quote.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text('— Carolina, 54 años',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.inkSoft)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('🌱🌿🌳', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tu árbol de fe crece con cada oración — y nunca '
                      'retrocede.',
                      style: AppTypography.body
                          .copyWith(color: AppColors.inkSoft),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const OnboardingFirstPrayerScreen()),
                    );
                  },
                  child: const Text('Quiero empezar 🙏'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
