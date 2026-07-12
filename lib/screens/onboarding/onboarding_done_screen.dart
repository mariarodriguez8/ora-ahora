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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Icon(Icons.check_circle, color: AppColors.success, size: 64),
              const SizedBox(height: 24),
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
                child: ElevatedButton(
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
