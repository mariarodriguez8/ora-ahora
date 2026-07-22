import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/prefs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../home/home_screen.dart';

class OnboardingDoneScreen extends StatelessWidget {
  /// Si se pasa [onContinue], esta pantalla NO es el final del onboarding:
  /// el boton dice "Continuar" y lleva al siguiente paso (elegir apps de
  /// Pausa y Ora) en vez de ir directo al inicio (pedido de Maria: el
  /// boton "Ir a mi inicio" saltaba el paso de elegir apps).
  final VoidCallback? onContinue;

  const OnboardingDoneScreen({super.key, this.onContinue});

  @override
  Widget build(BuildContext context) {
    final nombre = context.read<PrefsService>().userName;
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
                child: const Center(
                  child: Text('🌱', style: TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                nombre.isEmpty
                    ? '¡Tu semilla ya está\nplantada!'
                    : '¡Tu semilla ya está\nplantada, $nombre!',
                style: AppTypography.display.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 14),
              Text(
                onContinue != null
                    ? 'Hoy oraste por primera vez aquí 🌱 Falta un último '
                        'paso: elige qué apps te pedirán una pausa para orar.'
                    : 'Hoy oraste por primera vez aquí. Cada día que vuelvas, '
                        'tu árbol de fe crecerá un poquito más. Nos vemos '
                        'mañana a la misma hora — no vengas tarde 😄',
                style:
                    AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Caso onboarding: NO terminamos aqui; seguimos al paso
                    // de elegir apps. Solo cuando NO hay onContinue esta es
                    // la pantalla final y se va al inicio.
                    if (onContinue != null) {
                      onContinue!();
                      return;
                    }
                    final prefs = context.read<PrefsService>();
                    await prefs.setOnboardingComplete(true);
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: Text(
                      onContinue != null ? 'Continuar 🙏' : 'Ir a mi inicio 🏡'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
