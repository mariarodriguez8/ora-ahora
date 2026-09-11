import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/prefs_service.dart';
import 'funnel_base.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'funnel_screens.dart';
import 'onboarding_progress_dots.dart';
import '../../widgets/titular_escalonado.dart';

class OnboardingNameScreen extends StatefulWidget {
  const OnboardingNameScreen({super.key});

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void dispose() {
    _shake.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next({bool permitirVacio = false}) async {
    if (_controller.text.trim().isEmpty && !permitirVacio) {
      HapticFeedback.vibrate();
      _shake.forward(from: 0);
      return;
    }
    final prefs = context.read<PrefsService>();
    await prefs.setUserName(_controller.text);
    FunnelAnswers.nombre = _controller.text.trim();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FunnelQ1()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const OnboardingTopBar(step: 0),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          // desplazable-ok
          builder: (context, cons) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: cons.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TitularEscalonado(
                  frase: '¿Cómo\n*te llamas?*',
                  color: const Color(0xFF17251F),
                  acento: const Color(0xFF8A6A22),
                  base: 30,
                ),
                      const SizedBox(height: 28),
                      AnimatedBuilder(
                        animation: _shake,
                        builder: (context, child) {
                          final t = _shake.value;
                          final dx = t == 0
                              ? 0.0
                              : (12 *
                                  (1 - t) *
                                  ((t * 40).floor().isEven ? 1 : -1));
                          return Transform.translate(
                              offset: Offset(dx, 0), child: child);
                        },
                        child: TextField(
                          controller: _controller,
                          textCapitalization: TextCapitalization.words,
                          style: AppTypography.headline.copyWith(fontSize: 22),
                          decoration: const InputDecoration(
                            hintText: 'Tu nombre',
                          ),
                          onSubmitted: (_) => _next(),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _next,
                          child: const Text('Continuar'),
                        ),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            _controller.clear();
                            _next(permitirVacio: true);
                          },
                          child: Text('Prefiero no decirlo',
                              style: AppTypography.body
                                  .copyWith(color: AppColors.inkSoft)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
