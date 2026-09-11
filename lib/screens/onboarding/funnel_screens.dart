import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';
import 'funnel_base.dart';
import '../../widgets/tarjeta_cancion_semana.dart';
import 'funnel_parabola.dart';
import 'onboarding_categories_screen.dart';

void _go(BuildContext c, Widget s) =>
    Navigator.of(c).push(MaterialPageRoute(builder: (_) => s));

/// 1. "mas tarde oro..."
class FunnelQ1 extends StatelessWidget {
  const FunnelQ1({super.key});
  @override
  Widget build(BuildContext context) => FunnelScreen(
        pasoEmbudo: 0,
        alturaMascota: 150,
        frase: '¿Te ha pasado?\nDices "más tarde oro"...\n*y se te va el* día.',
        mascota: 'assets/mascot/ovejita_pensativa.png',
        opciones: [
          ('todos los días 😔', () => _go(context, const FunnelQ2())),
          ('a veces', () => _go(context, const FunnelQ2())),
          ('casi nunca', () => _go(context, const FunnelQ2())),
        ],
      );
}

/// 2. horas de celular
class FunnelQ2 extends StatelessWidget {
  const FunnelQ2({super.key});
  void _pick(BuildContext c, String v) {
    FunnelAnswers.horasCelular = v;
    _go(c, const FunnelQ3());
  }

  @override
  Widget build(BuildContext context) => FunnelScreen(
        pasoEmbudo: 1,
        alturaMascota: 185,
        frase: '¿Cuánto tiempo pasaste\n*ayer en el celular?*',
        subtitulo: 'con toda sinceridad',
        mascota: 'assets/mascot/ovejita_esperando.png',
        opciones: [
          ('1 o 2 horas', () => _pick(context, '1 o 2 horas')),
          ('3 o 4 horas', () => _pick(context, '3 o 4 horas')),
          ('5 horas o más', () => _pick(context, '5 horas o más')),
        ],
      );
}

/// 3. tiempo a Dios
class FunnelQ3 extends StatelessWidget {
  const FunnelQ3({super.key});
  void _pick(BuildContext c, String v) {
    FunnelAnswers.tiempoDios = v;
    _go(c, const FunnelMirror());
  }

  @override
  Widget build(BuildContext context) => FunnelScreen(
        pasoEmbudo: 2,
        alturaMascota: 155,
        frase: '¿Y cuánto tiempo\n*le diste a Dios?*',
        mascota: 'assets/mascot/ovejita_orando.png',
        opciones: [
          ('nada 💔', () => _pick(context, 'nada')),
          ('unos minutitos', () => _pick(context, 'unos minutitos')),
          ('media hora o más', () => _pick(context, 'media hora o más')),
        ],
      );
}

/// 4. el espejo: gamificado segun las respuestas.
class FunnelMirror extends StatelessWidget {
  const FunnelMirror({super.key});

  /// El nombre delante hace que la frase deje de ser un dato y pase a
  /// ser algo dicho a ella.
  String get _saludo =>
      FunnelAnswers.nombre.isEmpty ? '' : '${FunnelAnswers.nombre}, ';

  String get _horas =>
      FunnelAnswers.horasCelular.isEmpty ? 'horas' : FunnelAnswers.horasCelular;

  String _frase() {
    switch (FunnelAnswers.tiempoDios) {
      case 'nada':
        return '$_saludo$_horas en el celular.\n\nY para Dios... nada.\n'
            '';
      case 'unos minutitos':
        return '$_horas en el celular.\n\ny para Dios, unos minutitos.\n'
            '';
      default: // media hora o más
        return '$_horas en el celular,\n\ny un buen rato\ncon Dios.\n'
            '';
    }
  }

  String _mascota() {
    switch (FunnelAnswers.tiempoDios) {
      case 'nada':
        return 'assets/mascot/ovejita_perdida.png';
      case 'unos minutitos':
        return 'assets/mascot/ovejita_pensativa.png';
      default:
        return 'assets/mascot/ovejita_esperando.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FunnelScreen(
      pasoEmbudo: 3,
      alturaMascota: 235,
      frase: _frase(),
      mascota: _mascota(),
      opciones: [
        (
          'continuar',
          () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FunnelParabola(
                    onContinuar: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => FunnelKetsu(
                          onContinuar: () =>
                              Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const FunnelMinute(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
        ),
      ],
    );
  }
}

/// 5. la gracia (el fondo amanece)
class FunnelGrace extends StatelessWidget {
  const FunnelGrace({super.key});
  @override
  Widget build(BuildContext context) => FunnelScreen(
        pasoEmbudo: 4,
        alturaMascota: 225,
        amanecer: true,
        frase: FunnelAnswers.tiempoDios == 'media hora o más'
            ? 'No vienes de cero.\n\nYa lo buscas.\nLo que se pierde\nno es el tiempo:\n'
                '*son los días\nque se saltan sin querer.*'
            : 'La buena noticia:\n\nDios no está\nenojado contigo.\n*Está esperándote.*',
        mascota: 'assets/mascot/ovejita_celebrando.png',
        opciones: [
          ('quiero volver a Él 🤍', () => _go(context, const FunnelMinute())),
        ],
      );
}

/// 6. 1 minuto
class FunnelMinute extends StatelessWidget {
  const FunnelMinute({super.key});
  @override
  Widget build(BuildContext context) => FunnelScreen(
        pasoEmbudo: 5,
        alturaMascota: 165,
        frase: 'Él te espera hoy.\n*¿le das 1 minuto?*',
        mascota: 'assets/mascot/ovejita_esperando.png',
        opciones: [
          (
            'sí, con 1 minuto sí puedo 🙏',
            () => _go(context, const FunnelCancion())
          ),
        ],
      );
}

/// 7. regalo de bienvenida: una estampa apenas entra (se guarda en su
/// colección; cada racha desbloquea una nueva para compartir).
class FunnelRegalo extends StatelessWidget {
  const FunnelRegalo({super.key});

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
          child: LayoutBuilder(
            builder: (context, cons) {
              // La estampa medía 300 fijos y empujaba el texto fuera de
              // la pantalla en moviles cortos. Ahora se ajusta al alto
              // disponible y la pantalla se desliza si hace falta.
              final altoEstampa = (cons.maxHeight * 0.42).clamp(150.0, 300.0);
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: cons.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          const Spacer(),
                          Text('Un regalo de bienvenida',
                              textAlign: TextAlign.center,
                              style: AppTypography.display.copyWith(
                                  fontSize: 26, color: kFunnelMarfil)),
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'store_assets/estampas/estampa_01.png',
                              height: altoEstampa,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Guárdala en tu teléfono. Cuando te sientas lejos, '
                            'mírala y acuérdate de hoy.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                                color: kFunnelMarfil.withValues(alpha: 0.75)),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kFunnelDorado,
                                foregroundColor: const Color(0xFF241F10),
                              ),
                              onPressed: () =>
                                  _go(context, const FunnelCancion()),
                              child: const Text('Gracias, guardar 🤍'),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 8. la canción de la semana (deleite + gancho a una función Plus).
class FunnelCancion extends StatelessWidget {
  const FunnelCancion({super.key});
  @override
  Widget build(BuildContext context) => FunnelScreen(
        pasoEmbudo: 7,
        alturaMascota: 195,
        frase: 'Te desbloqueé\n*la canción de esta semana.*',
        subtitulo: 'Para cuando no te salgan las palabras.',
        extra: const TarjetaCancionSemana(),
        mascota: 'assets/mascot/ovejita_musica.png',
        opciones: [
          (
            'la voy a necesitar 🎧',
            () => _go(context, const OnboardingCategoriesScreen())
          ),
        ],
      );
}
