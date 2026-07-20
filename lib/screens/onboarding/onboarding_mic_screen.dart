import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/prefs_service.dart';
import '../../services/voice_prayer_service.dart';
import '../../theme/app_typography.dart';
import 'onboarding_reminders_screen.dart';
import 'onboarding_progress_dots.dart';

/// Contexto del microfono DENTRO del onboarding, justo despues de la
/// primera oracion: primero se explica con calma y diseno, y solo si la
/// persona acepta se dispara el dialogo del sistema. Nunca en frio.
class OnboardingMicScreen extends StatefulWidget {
  const OnboardingMicScreen({super.key});

  @override
  State<OnboardingMicScreen> createState() => _OnboardingMicScreenState();
}

class _OnboardingMicScreenState extends State<OnboardingMicScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat(reverse: true);
  bool _pidiendo = false;

  static const _dorado = Color(0xFFFFD18C);
  static const _marfil = Color(0xFFF7F3EA);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _next() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingRemindersScreen()),
    );
  }

  Future<void> _pedir() async {
    setState(() => _pidiendo = true);
    final prefs = context.read<PrefsService>();
    final voice = VoicePrayerService();
    final ok = await voice.checkAvailability();
    voice.dispose();
    await prefs.setMicPrimingDone(true);
    await prefs.setVoiceDisclosureSeen(true);
    if (!mounted) return;
    setState(() => _pidiendo = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? '¡Listo! Cuando ores en voz alta, te escucho 🙏'
          : 'Sin problema, puedes activarlo luego desde una oración.'),
    ));
    _next();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF18163A), Color(0xFF0A3A30)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const OnboardingTopBar(step: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¿Y si la próxima\nla oramos en voz alta?',
                          style: AppTypography.display
                              .copyWith(fontSize: 28, color: _marfil)),
                      const SizedBox(height: 12),
                      Text(
                        'Cuando ores en voz alta, te escucho y marco la '
                        'oración por ti al terminar. Tu voz se queda en tu '
                        'teléfono: nunca se graba ni se envía a ningún lado.',
                        style: AppTypography.bodyLarge.copyWith(
                            color: _marfil.withValues(alpha: 0.75)),
                      ),
                      const Spacer(),
                      Center(
                        child: AnimatedBuilder(
                          animation: _pulse,
                          builder: (context, _) {
                            final v = _pulse.value;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                for (final (base, a) in [
                                  (196.0, 0.25),
                                  (156.0, 0.45)
                                ])
                                  Container(
                                    width: base + 34 * v,
                                    height: base + 34 * v,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _dorado.withValues(
                                            alpha: a * (1 - v * 0.55)),
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                Container(
                                  width: 116,
                                  height: 116,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFFFFE7C2),
                                        Color(0xFFFFD18C),
                                        Color(0xFFE2A85B),
                                      ],
                                      stops: [0.0, 0.6, 1.0],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _dorado.withValues(
                                            alpha: 0.45 + 0.3 * v),
                                        blurRadius: 38 + 16 * v,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.mic_rounded,
                                      size: 56, color: Color(0xFF241F10)),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dorado,
                            foregroundColor: const Color(0xFF241F10),
                          ),
                          onPressed: _pidiendo ? null : _pedir,
                          child: Text(_pidiendo
                              ? 'Activando…'
                              : 'Sí, escúchame orar 🎙️'),
                        ),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: _next,
                          child: Text('Ahora no',
                              style: TextStyle(
                                  color:
                                      _marfil.withValues(alpha: 0.55))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
