import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/prefs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'onboarding_progress_dots.dart';
import 'onboarding_reminders_screen.dart';

/// Compromiso explicito: una promesa declarada aumenta el seguimiento
/// (compromiso psicologico), dicha en lenguaje de fe, sin presion.
class OnboardingCommitmentScreen extends StatefulWidget {
  const OnboardingCommitmentScreen({super.key});

  @override
  State<OnboardingCommitmentScreen> createState() =>
      _OnboardingCommitmentScreenState();
}

class _OnboardingCommitmentScreenState
    extends State<OnboardingCommitmentScreen> {
  bool _prometido = false;

  @override
  Widget build(BuildContext context) {
    final nombre = context.read<PrefsService>().userName;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const OnboardingTopBar(step: 7),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Un pacto pequeño,\nde corazón 🤍',
                  style: AppTypography.display.copyWith(fontSize: 28)),
              const SizedBox(height: 12),
              Text(
                'No es una obligación: es una decisión. Los hábitos que '
                'permanecen empiezan con una promesa dicha en serio.',
                style:
                    AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _prometido = true);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _prometido ? AppColors.tealDeep : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          _prometido ? AppColors.tealDeep : AppColors.tealLight,
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(_prometido ? '🙏' : '🤝',
                          style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        _prometido
                            ? 'Pacto hecho${nombre.isEmpty ? '' : ', $nombre'}. '
                                'Dios y tú, cada día.'
                            : '"Decido buscar a Dios cada día,\naunque sea '
                                'un minuto."',
                        textAlign: TextAlign.center,
                        style: AppTypography.headline.copyWith(
                          fontSize: 19,
                          color:
                              _prometido ? Colors.white : AppColors.ink,
                        ),
                      ),
                      if (!_prometido) ...[
                        const SizedBox(height: 10),
                        Text('Toca para hacer el pacto',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.inkSoft)),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _prometido
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const OnboardingRemindersScreen()),
                          );
                        }
                      : null,
                  child: Text(
                      _prometido ? 'Continuar' : 'Primero haz tu pacto 🤍'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
