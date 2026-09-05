import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/prefs_service.dart';
import '../../theme/app_typography.dart';
import 'funnel_base.dart';
import 'onboarding_anim.dart';

/// "Tus próximos 30 días".
///
/// No muestra lo que se gana, muestra lo que le va a pasar. El dia 14 cambia
/// segun lo que la persona eligio, para que el camino se sienta suyo.
class OnboardingCaminoScreen extends StatelessWidget {
  final VoidCallback onContinuar;
  const OnboardingCaminoScreen({super.key, required this.onContinuar});

  static const _porTema = {
    'ansiedad': 'Cuando llegue la ansiedad, vas a saber a dónde ir.',
    'paz': 'El ruido sigue afuera, pero ya no manda adentro.',
    'gratitud': 'Empiezas a ver lo que antes pasabas por alto.',
    'familia': 'Oras por ellos antes de reclamarles.',
    'trabajo': 'Entras al día sin que el día te empiece ganando.',
    'tentacion_enfoque': 'Dices que no, y por primera vez no cuesta tanto.',
    'sanidad': 'El dolor sigue, pero ya no lo cargas solo.',
    'perdon': 'Piensas en esa persona y duele un poco menos.',
    'duelo': 'Te acuerdas, y por primera vez sonríes.',
    'soledad': 'La casa sigue igual de callada. Tú no.',
    'matrimonio': 'Cedes primero sin que nadie te lo pida.',
    'finanzas': 'La cuenta sigue igual, pero duermes.',
    'manana': 'Te despiertas y lo buscas antes que al celular.',
    'noche': 'Cierras el día sin ese vacío.',
  };

  String _dia14(BuildContext context) {
    final cats = context.read<PrefsService>().preferredCategories;
    for (final c in cats) {
      final t = _porTema[c];
      if (t != null) return t;
    }
    return 'Empiezas a notar la diferencia.';
  }


  /// El dia exacto en que va a llevar treinta dias. Una fecha concreta
  /// compromete mas que un numero abstracto.
  String _fechaMeta() {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final d = DateTime.now().add(const Duration(days: 30));
    return 'El ${d.day} de ${meses[d.month - 1]} vas a llevar\n'
        '30 días hablando con Él.';
  }

  @override
  Widget build(BuildContext context) {
    final hitos = <(String, String)>[
      ('Día 1', 'Le hablas después de mucho tiempo.'),
      ('Día 7', 'Ya no se te olvida. Lo empiezas a extrañar.'),
      ('Día 14', _dia14(context)),
      ('Día 30', 'Ya no eres la persona que abría el celular sin pensar.'),
    ];

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
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AparicionSuave(
                  orden: 0,
                  child: Center(
                    child: Image.asset('assets/mascot/ovejita_esperando.png',
                        height: 92, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 18),
                AparicionSuave(
                  orden: 1,
                  child: Text('Tus próximos 30 días',
                      style: AppTypography.display
                          .copyWith(fontSize: 28, color: kFunnelMarfil)),
                ),
                const SizedBox(height: 8),
                // Una fecha en el calendario se siente real; "30 dias" no.
                AparicionSuave(
                  orden: 1,
                  child: Text(_fechaMeta(),
                      style: AppTypography.body.copyWith(
                        color: kFunnelDorado,
                        height: 1.35,
                      )),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: hitos.length,
                    itemBuilder: (context, i) => AparicionSuave(
                      orden: 2 + i,
                      child: _Hito(
                        dia: hitos[i].$1,
                        texto: hitos[i].$2,
                        ultimo: i == hitos.length - 1,
                      ),
                    ),
                  ),
                ),
                AparicionSuave(
                  orden: 7,
                  child: Text(
                    'Nada de esto pasa en un día.\nPor eso son treinta.',
                    style: AppTypography.display
                        .copyWith(fontSize: 20, color: kFunnelDorado),
                  ),
                ),
                const SizedBox(height: 18),
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
                      onPressed: onContinuar,
                      child: const Text('Quiero esos 30 días'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un hito del camino: punto, linea vertical y el texto al lado.
class _Hito extends StatelessWidget {
  final String dia;
  final String texto;
  final bool ultimo;
  const _Hito({required this.dia, required this.texto, required this.ultimo});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ultimo ? kFunnelDorado : Colors.transparent,
                  border: Border.all(color: kFunnelDorado, width: 2),
                ),
              ),
              if (!ultimo)
                Expanded(
                  child: Container(
                    width: 2,
                    color: kFunnelDorado.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ultimo ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dia,
                      style: AppTypography.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kFunnelDorado)),
                  const SizedBox(height: 3),
                  Text(texto,
                      style: AppTypography.body.copyWith(
                          fontSize: 15,
                          height: 1.3,
                          color: kFunnelMarfil.withValues(alpha: 0.88))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
