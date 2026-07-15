import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/notification_service.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'onboarding_gate_screen.dart';
import 'onboarding_progress_dots.dart';

/// Priming del permiso de notificaciones: primero se explica el beneficio
/// concreto y personal; solo si la persona acepta se dispara el prompt
/// nativo de Android.
class OnboardingRemindersScreen extends StatelessWidget {
  const OnboardingRemindersScreen({super.key});

  void _next(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingGateScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.read<PrefsService>();
    final nombre = prefs.userName;
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
              Text('¿Te avisamos cuando\nsea tu momento?',
                  style: AppTypography.display.copyWith(fontSize: 28)),
              const SizedBox(height: 12),
              Text(
                'A las ${prefs.morningTime} y a las ${prefs.nightTime} te '
                'mandaremos un recordatorio cortito y amable'
                '${nombre.isEmpty ? '' : ', $nombre'}. '
                'Es lo que más ayuda a no romper la racha 🔥',
                style:
                    AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.tealLight),
                ),
                child: Row(
                  children: [
                    const Text('🔔', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '"${nombre.isEmpty ? 'Hola' : nombre}, tu momento '
                        'con Dios te espera 🙏"',
                        style: AppTypography.quote.copyWith(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final notif = context.read<NotificationService>();
                    final ok = await notif.requestPermission();
                    if (ok) {
                      await notif.refreshSchedule(prefs.reminderTimes);
                    }
                    if (!context.mounted) return;
                    _next(context);
                  },
                  child: const Text('Sí, recuérdamelo 🔔'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => _next(context),
                  child: Text('Ahora no',
                      style: AppTypography.body
                          .copyWith(color: AppColors.inkSoft)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
