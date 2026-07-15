import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../gate_explainer/gate_explainer_screen.dart';
import 'onboarding_done_screen.dart';
import 'onboarding_progress_dots.dart';

/// Presenta "Pausa y Ora" (lo que hace unica a la app) DURANTE el
/// onboarding, con lenguaje humano y sencillo. El permiso tecnico de
/// Accesibilidad se pide despues, en GateExplainerScreen, como exige
/// Google Play.
class OnboardingGateScreen extends StatelessWidget {
  const OnboardingGateScreen({super.key});

  void _next(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingDoneScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const OnboardingTopBar(step: 5),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Y esto es lo que nos\nhace diferentes ✨',
                  style: AppTypography.display.copyWith(fontSize: 28)),
              const SizedBox(height: 12),
              Text(
                '¿Te pasa que abres el celular "un minutito" y de repente '
                'se fue media hora? A todos nos pasa.',
                style:
                    AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 16),
              _Paso(
                emoji: '📱',
                texto: 'Tú eliges las apps que más te distraen '
                    '(por ejemplo, Instagram o TikTok).',
              ),
              _Paso(
                emoji: '✋',
                texto: 'Cuando vayas a abrirlas, Ora Ahora te detiene '
                    'unos segundos primero.',
              ),
              _Paso(
                emoji: '🙏',
                texto: 'Respiras, haces una oración cortita… y tú decides '
                    'si sigues o mejor no.',
              ),
              const SizedBox(height: 16),
              Text(
                'Para lograrlo, tu teléfono nos pedirá un permiso especial. '
                'En la siguiente pantalla te explicamos cuál es y cómo '
                'activarlo, paso a paso y sin apuro.',
                style: AppTypography.body.copyWith(color: AppColors.inkSoft),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const GateExplainerScreen()),
                    );
                    if (!context.mounted) return;
                    _next(context);
                  },
                  child: const Text('Quiero activarlo ✋🙏'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => _next(context),
                  child: Text('Lo activo después desde Ajustes',
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

class _Paso extends StatelessWidget {
  final String emoji;
  final String texto;
  const _Paso({required this.emoji, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto,
                style: AppTypography.body.copyWith(fontSize: 15.5)),
          ),
        ],
      ),
    );
  }
}
