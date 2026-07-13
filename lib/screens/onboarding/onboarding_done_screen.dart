import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/prefs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../home/home_screen.dart';

class OnboardingDoneScreen extends StatelessWidget {
  const OnboardingDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.tealLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.tealDeep, size: 48),
              ),
              const SizedBox(height: 28),
              Text('¡Todo listo!', style: AppTypography.display),
              const SizedBox(height: 14),
              Text(
                'Ya puedes empezar a orar con Ora Ahora. Cuando quieras, '
                'desde Ajustes podrás activar recordatorios diarios y la '
                'función "Pausa y Ora" para hacer una pausa antes de abrir '
                'las apps que más te distraen.',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final prefs = context.read<PrefsService>();
                    await prefs.setOnboardingComplete(true);
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Ir a mi inicio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
