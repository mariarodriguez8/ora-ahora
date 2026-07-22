import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/gate_service.dart';
import '../../services/notification_service.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../gate_explainer/gate_explainer_screen.dart';
import '../paywall/paywall_screen.dart';
import '../settings/gated_apps_screen.dart';
import 'onboarding_done_screen.dart';
import 'onboarding_progress_dots.dart';

/// Priming del permiso de notificaciones: primero se explica el beneficio
/// concreto y personal; solo si la persona acepta se dispara el prompt
/// nativo de Android.
class OnboardingRemindersScreen extends StatelessWidget {
  const OnboardingRemindersScreen({super.key});

  Future<void> _next(BuildContext context) async {
    // El paywall y los permisos de "Pausa y Ora" viven AQUI, dentro del
    // onboarding, justo despues de los permisos esenciales. Son pasos de
    // NAVEGACION garantizados (no dependen de ninguna marca guardada que
    // Android pueda restaurar), asi que SIEMPRE aparecen para un usuario
    // nuevo, en el orden correcto: esenciales -> paywall -> Pausa y Ora.
    final prefs = context.read<PrefsService>();
    // Marca para que el inicio no vuelva a mostrar el paywall (ya se ve aqui).
    await prefs.setPaywallShownAfterOnboarding(true);
    if (!context.mounted) return;
    // Paso A: Paywall (prueba/compra), ultimo gran paso del onboarding.
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
    if (!context.mounted) return;
    // Paso B: JUSTO despues, permisos de Pausa y Ora si aun faltan.
    final gate = context.read<GateService>();
    final tienePermisos = await gate.hasAllGatePermissions();
    if (context.mounted && !tienePermisos) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GateExplainerScreen()),
      );
    }
    if (!context.mounted) return;
    // Paso C: elegir QUE apps piden una pausa (TikTok, Instagram, etc.).
    // Este paso SIEMPRE aparece en el onboarding: nadie deberia tener que
    // adivinar que hay que ir a Ajustes a configurarlo (pedido de Maria).
    // "Continuar" (o el gesto de volver) simplemente cierra esta pantalla;
    // el cierre del onboarding se hace una sola vez, abajo.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => GatedAppsScreen(
          onboardingContinue: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
    if (!context.mounted) return;
    // Paso D: cierre del onboarding (una sola vez, venga de "Continuar" o
    // del gesto de volver desde la seleccion de apps).
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingDoneScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.read<PrefsService>();
    final nombre = prefs.userName;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const OnboardingTopBar(step: 8),
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
                    try {
                      final notif = context.read<NotificationService>();
                      final ok = await notif.requestPermission();
                      if (ok) {
                        await notif.refreshSchedule(prefs.reminderTimes);
                      }
                    } catch (_) {
                      // Aunque falle el permiso, nunca dejamos a la persona
                      // atascada: seguimos siempre.
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
