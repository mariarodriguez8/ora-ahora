import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'onboarding_progress_dots.dart';
import 'onboarding_social_screen.dart';

/// "Preparando tu plan": pantalla breve con verificaciones animadas que
/// hace tangible la personalizacion (patron probado de Cal AI/Headspace).
class OnboardingPlanScreen extends StatefulWidget {
  const OnboardingPlanScreen({super.key});

  @override
  State<OnboardingPlanScreen> createState() => _OnboardingPlanScreenState();
}

class _OnboardingPlanScreenState extends State<OnboardingPlanScreen> {
  static const _pasos = [
    'Eligiendo tus oraciones 🙏',
    'Ajustando tus horarios ⏰',
    'Plantando tu semilla de fe 🌱',
  ];
  int _done = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 850), (t) {
      if (!mounted) return;
      setState(() => _done++);
      if (_done > _pasos.length) {
        t.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingSocialScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const OnboardingTopBar(step: 3),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text('Preparando tu plan\nde oración…',
                  style: AppTypography.display.copyWith(fontSize: 28)),
              const SizedBox(height: 28),
              for (var i = 0; i < _pasos.length; i++)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: _done > i ? 1 : 0.25,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _done > i
                                ? AppColors.success
                                : AppColors.tealLight,
                            shape: BoxShape.circle,
                          ),
                          child: _done > i
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(_pasos[i], style: AppTypography.bodyLarge),
                      ],
                    ),
                  ),
                ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
