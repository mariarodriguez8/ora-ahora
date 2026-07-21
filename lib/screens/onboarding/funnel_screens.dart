import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';
import 'funnel_base.dart';
import 'onboarding_name_screen.dart';

void _go(BuildContext c, Widget s) =>
    Navigator.of(c).push(MaterialPageRoute(builder: (_) => s));

/// 1. "ahorita oro..."
class FunnelQ1 extends StatelessWidget {
  const FunnelQ1({super.key});
  @override
  Widget build(BuildContext context) => FunnelScreen(
        frase: '¿te ha pasado?\ndices "ahorita oro"...\ny se te va el día.',
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
        frase: '¿cuánto tiempo pasaste\nayer en el celular?',
        subtitulo: 'sé honesta',
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
        frase: '¿y cuánto tiempo\nle diste a Dios?',
        mascota: 'assets/mascot/ovejita_orando.png',
        opciones: [
          ('nada 💔', () => _pick(context, 'nada')),
          ('unos minutitos', () => _pick(context, 'unos minutitos')),
          ('media hora o más', () => _pick(context, 'media hora o más')),
        ],
      );
}

/// 4. el espejo: gamificado segun las respuestas. No repite numeros secos,
/// va al corazon y cambia el tono (y la ovejita) segun cuanto tiempo le
/// dio a Dios.
class FunnelMirror extends StatelessWidget {
  const FunnelMirror({super.key});

  String get _horas =>
      FunnelAnswers.horasCelular.isEmpty ? 'horas' : FunnelAnswers.horasCelular;

  String _frase() {
    switch (FunnelAnswers.tiempoDios) {
      case 'nada':
        return '$_horas en el celular.\n\ny para Dios... nada.\n'
            'no es que no te importe —\nes que nunca le llega el turno.';
      case 'unos minutitos':
        return '$_horas en el celular.\n\ny para Dios, unos minutitos.\n'
            'tu corazón siente esa diferencia.';
      default: // media hora o más
        return '$_horas en el celular,\n\ny un buen rato con Dios.\n'
            'vas por buen camino —\nÉl quiere seguir cerca de ti.';
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
      frase: _frase(),
      mascota: _mascota(),
      opciones: [
        ('continuar', () => _go(context, const FunnelWins())),
      ],
    );
  }
}

/// 5. la validacion
class FunnelWins extends StatelessWidget {
  const FunnelWins({super.key});
  @override
  Widget build(BuildContext context) => FunnelScreen(
        frase: 'y no es que no ames a Dios.\n\nes que el celular grita...\n'
            'y Él te habla bajito.\npor eso casi siempre gana la pantalla.',
        mascota: 'assets/mascot/ovejita_pensativa.png',
        opciones: [
          ('así me siento 😔', () => _go(context, const FunnelGrace())),
        ],
      );
}

/// 6. la gracia (el fondo amanece)
class FunnelGrace extends StatelessWidget {
  const FunnelGrace({super.key});
  @override
  Widget build(BuildContext context) => FunnelScreen(
        amanecer: true,
        frase: 'la buena noticia:\n\nDios no está enojado contigo.\nestá esperándote.',
        mascota: 'assets/mascot/ovejita_celebrando.png',
        opciones: [
          ('quiero volver a Él 🤍', () => _go(context, const FunnelMinute())),
        ],
      );
}

/// 7. 1 minuto
class FunnelMinute extends StatelessWidget {
  const FunnelMinute({super.key});
  @override
  Widget build(BuildContext context) => FunnelScreen(
        frase: '¿y si empezamos\ncon 1 minuto al día?',
        mascota: 'assets/mascot/ovejita_esperando.png',
        opciones: [
          ('sí, con 1 minuto sí puedo 🙏',
              () => _go(context, const FunnelShame())),
        ],
      );
}

/// 8. la pena de orar en voz alta
class FunnelShame extends StatelessWidget {
  const FunnelShame({super.key});
  void _answer(BuildContext c, bool pena) {
    if (pena) {
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(
        content: Text('tranquila. empieza en susurro. Dios escucha igual 🤍',
            style: AppTypography.body),
        duration: const Duration(seconds: 3),
      ));
    }
    _go(c, const OnboardingNameScreen());
  }

  @override
  Widget build(BuildContext context) => FunnelScreen(
        frase: '¿te da pena orar\nen voz alta?',
        mascota: 'assets/mascot/ovejita_escuchando.png',
        opciones: [
          ('un poquito 🙈', () => _answer(context, true)),
          ('no, para nada', () => _answer(context, false)),
        ],
      );
}
