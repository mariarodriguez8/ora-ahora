import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';
import 'funnel_base.dart';
import 'onboarding_anim.dart';

/// "Tu cuenta del año".
///
/// Toma lo que la persona respondio en el embudo y hace la multiplicacion
/// que nunca hizo. No es una frase bonita: es su propio dato.
class OnboardingCuentaScreen extends StatefulWidget {
  final VoidCallback onContinuar;
  const OnboardingCuentaScreen({super.key, required this.onContinuar});

  @override
  State<OnboardingCuentaScreen> createState() => _OnboardingCuentaScreenState();
}

class _OnboardingCuentaScreenState extends State<OnboardingCuentaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final Animation<double> _curva =
      CurvedAnimation(parent: _c, curve: Curves.easeOutExpo);

  /// Horas al dia en el celular, segun lo que contesto.
  double get _horasDia {
    final r = FunnelAnswers.horasCelular;
    if (r.contains('1 o 2')) return 1.5;
    if (r.contains('3 o 4')) return 3.5;
    if (r.contains('5 horas')) return 5.5;
    return 3.5;
  }

  /// Minutos al dia con Dios, segun lo que contesto.
  double get _minutosDia {
    final r = FunnelAnswers.tiempoDios;
    if (r.contains('media hora')) return 30;
    return 5;
  }

  int get _diasAlAno => (_horasDia * 365 / 24).round();
  int get _horasConDios => (_minutosDia * 365 / 60).round();

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kFunnelIndigo, kFunnelEsmeralda],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                AparicionSuave(
                  orden: 0,
                  child: Center(
                    child: Image.asset('assets/mascot/ovejita_pensativa.png',
                        height: 110, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 28),
                // El numero es el golpe. Sube contando para que se sienta.
                AnimatedBuilder(
                  animation: _curva,
                  builder: (context, _) {
                    final n = (_diasAlAno * _curva.value).round();
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$n',
                            style: AppTypography.display.copyWith(
                                fontSize: 82,
                                height: 1,
                                color: kFunnelDorado)),
                        const SizedBox(width: 10),
                        Text('días',
                            style: AppTypography.display.copyWith(
                                fontSize: 30, color: kFunnelDorado)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                AparicionSuave(
                  orden: 4,
                  child: Text(
                    'Eso es lo que te va a llevar el celular este año.',
                    style: AppTypography.display
                        .copyWith(fontSize: 24, color: kFunnelMarfil),
                  ),
                ),
                const SizedBox(height: 18),
                AparicionSuave(
                  orden: 6,
                  child: Text(
                    'Con Dios vas a estar $_horasConDios horas.',
                    style: AppTypography.body.copyWith(
                        fontSize: 16,
                        color: kFunnelMarfil.withValues(alpha: 0.62)),
                  ),
                ),
                const Spacer(),
                AparicionSuave(
                  orden: 8,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kFunnelDorado,
                        foregroundColor: const Color(0xFF241F10),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: widget.onContinuar,
                      child: const Text('No quiero que sea así'),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
