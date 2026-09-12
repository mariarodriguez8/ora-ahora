import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_typography.dart';
import 'funnel_base.dart';

/// El giro del embudo, en dos pantallas: Ten y Ketsu.
///
/// Kishotenketsu: el Ten no es un conflicto ni una revelacion sobre lo
/// anterior, es algo que irrumpe sin tener nada que ver. La persona acaba
/// de confesar cuantas horas le da al telefono y de golpe le cuentan una
/// historia de pastores. Ese desconcierto es el giro.
///
/// El Ketsu no explica la conexion: pone la imagen y deja que la haga
/// ella. Por eso el telefono aparece ANTES que la ultima frase.
const _fondoParabola = Color(0xFF0C1C16);
const _marfil = Color(0xFFF5F0E4);
const _dorado = Color(0xFFD9A93C);

/// --- TEN: la parabola ---
///
/// Avanza al tocar, no con un boton. El ritmo lo marca la persona, que es
/// lo que convierte una pantalla de leer en una de hacer.
class FunnelParabola extends StatefulWidget {
  const FunnelParabola({super.key, required this.onContinuar});

  final VoidCallback onContinuar;

  @override
  State<FunnelParabola> createState() => _FunnelParabolaState();
}

class _FunnelParabolaState extends State<FunnelParabola> {
  static const _lineas = <String>[
    'Jesús contó esto\nhace dos mil años.\n\nUn pastor tenía\ncien ovejas.',
    'Una se perdió\nen el monte.',
    'Dejó las noventa\ny nueve.',
    'No esperó\na que volviera.\nFue hasta donde\nestaba la oveja.',
  ];

  int _visibles = 1;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(milliseconds: 2200), (t) {
      if (!mounted || _completa) {
        t.cancel();
        return;
      }
      setState(() => _visibles++);
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  bool get _completa => _visibles >= _lineas.length;

  void _tocar() {
    if (_completa) {
      widget.onContinuar();
      return;
    }
    setState(() => _visibles++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondoParabola,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tocar,
        child: SafeArea(
          child: Stack(
            children: [
              // El pastor entra cuando la historia ya empezó, nunca antes.
              if (true)
                Positioned(
                  right: -40,
                  bottom: 0,
                  child: AnimatedOpacity(
                    opacity: _visibles >= 3 ? 1 : (_visibles >= 2 ? 0.7 : 0.28),
                    duration: const Duration(milliseconds: 900),
                    child: Image.asset(
                      'assets/mascot/pastor_buscando.png',
                      height: MediaQuery.of(context).size.height * 0.52,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _lineas.length; i++)
                      AnimatedOpacity(
                        opacity: i < _visibles ? 1 : 0,
                        duration: const Duration(milliseconds: 700),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: i * 10.0,
                            bottom: 18,
                          ),
                          child: Text(
                            _lineas[i],
                            style: AppTypography.display.copyWith(
                              fontSize: i == _lineas.length - 1 ? 24 : 25,
                              height: 1.2,
                              fontStyle: i == _lineas.length - 1
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              color:
                                  i == _lineas.length - 1 ? _dorado : _marfil,
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (_completa)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _marfil,
                            foregroundColor: _fondoParabola,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            widget.onContinuar();
                          },
                          child: const Text('Seguir'),
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lucas 15  ·  toca para seguir',
                            style: AppTypography.caption
                                .copyWith(color: _marfil.withValues(alpha: 0.55)),
                          ),
                          const SizedBox(width: 7),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: _marfil.withValues(alpha: 0.55),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// --- KETSU: la conexion ---
///
/// Primero la imagen, despues la frase. Si la frase llega antes, explica;
/// si llega despues, confirma lo que la persona ya pensó. Y nunca se dice
/// "tu te perdiste": eso acusa, y en todo el flujo no hay un reproche.
class FunnelKetsu extends StatefulWidget {
  const FunnelKetsu({super.key, required this.onContinuar});

  final VoidCallback onContinuar;

  @override
  State<FunnelKetsu> createState() => _FunnelKetsuState();
}

class _FunnelKetsuState extends State<FunnelKetsu> {
  int _fase = 0;

  @override
  void initState() {
    super.initState();
    // La pantalla se cuenta sola: dos frases, el telefono, y el remate.
    for (final t in const [900, 2100, 3600]) {
      Future.delayed(Duration(milliseconds: t), () {
        if (mounted) setState(() => _fase++);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFunnelIndigo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mismo rotulo, misma esquina que en la parabola: asi el
              // salto de epoca se lee como una decision y no como un fallo.
              AnimatedOpacity(
                opacity: _fase >= 0 ? 1 : 0,
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'HOY',
                  style: AppTypography.caption.copyWith(
                    color: _dorado,
                    letterSpacing: 2.2,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const SizedBox(height: 10),
              _linea('Ya no nos perdemos\nen el monte.', 0, 26, false),
              const Spacer(),
              AnimatedOpacity(
                opacity: _fase >= 2 ? 1 : 0,
                duration: const Duration(milliseconds: 800),
                child: const Center(child: _TelefonoFalso()),
              ),
              const Spacer(),
              // La flecha ata la frase al movil de arriba: sin ella hay que adivinarlo.
              AnimatedOpacity(
                opacity: _fase >= 3 ? 1 : 0,
                duration: const Duration(milliseconds: 600),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 2),
                  child: Transform.rotate(
                    angle: -0.32,
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 30,
                      color: _dorado.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
              _linea('Nos perdemos aquí.', 3, 26, true),
              const SizedBox(height: 18),
              AnimatedOpacity(
                opacity: _fase >= 3 ? 1 : 0,
                duration: const Duration(milliseconds: 600),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _dorado,
                      foregroundColor: const Color(0xFF241F10),
                    ),
                    onPressed: _fase >= 3
                        ? () {
                            HapticFeedback.mediumImpact();
                            widget.onContinuar();
                          }
                        : null,
                    child: const Text('Quiero volver con mi pastor',
                      textAlign: TextAlign.center),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linea(String texto, int desde, double tamano, bool acento) {
    return AnimatedOpacity(
      opacity: _fase >= desde ? 1 : 0,
      duration: const Duration(milliseconds: 700),
      child: Padding(
        padding: EdgeInsets.only(left: desde * 12.0, bottom: 6),
        child: Text(
          texto,
          style: AppTypography.display.copyWith(
            fontSize: tamano,
            height: 1.18,
            fontStyle: acento ? FontStyle.italic : FontStyle.normal,
            color: acento ? _dorado : _marfil,
          ),
        ),
      ),
    );
  }
}

/// La pantalla de bloqueo del telefono de cualquiera.
///
/// Antes eran ocho cuadrados de colores y no se entendia nada: la gente
/// veia cuadros, no su movil. Con la hora en grande se reconoce al
/// instante y sin pensar, que es lo unico que importa aqui: esta pantalla
/// solo tiene que decir "esto es tu telefono" en medio segundo.
///
/// Y es mas fiel al producto: la pausa no llega al abrir una app concreta,
/// llega cuando desbloqueas.
/// Un movil creible, no un juguete. Los iconos son nuestros: simbolos
/// genericos de categoria (video, mensajes, feed) en nuestra paleta.
/// Ninguna marca ajena, y aun asi se lee al instante como "mis apps".
class _TelefonoFalso extends StatelessWidget {
  const _TelefonoFalso();

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final hora = ahora.hour.toString().padLeft(2, '0');
    final minuto = ahora.minute.toString().padLeft(2, '0');

    return Container(
      width: 190,
      height: 306,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF14161B),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _marfil.withValues(alpha: 0.20), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          color: const Color(0xFF0A0E14),
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
          child: Column(
            children: [
              _BarraEstado(hora: hora, minuto: minuto),
              const SizedBox(height: 18),
              Text(
                '$hora:$minuto',
                style: AppTypography.display.copyWith(
                  fontSize: 44,
                  height: 1,
                  color: _marfil,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'hoy',
                style: AppTypography.caption.copyWith(
                  color: _marfil.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _IconoApp(Icons.play_arrow_rounded, Color(0xFFB3574F)),
                  _IconoApp(Icons.chat_bubble_rounded, Color(0xFF4A6E8A)),
                  _IconoApp(Icons.favorite_rounded, Color(0xFF8A5A72)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: 56,
                height: 4,
                decoration: BoxDecoration(
                  color: _marfil.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarraEstado extends StatelessWidget {
  final String hora;
  final String minuto;
  const _BarraEstado({required this.hora, required this.minuto});

  @override
  Widget build(BuildContext context) {
    final tenue = _marfil.withValues(alpha: 0.55);
    return Row(
      children: [
        Text(
          '$hora:$minuto',
          style: AppTypography.caption.copyWith(fontSize: 9, color: tenue),
        ),
        const Spacer(),
        Icon(Icons.signal_cellular_alt_rounded, size: 11, color: tenue),
        const SizedBox(width: 3),
        Icon(Icons.wifi_rounded, size: 11, color: tenue),
        const SizedBox(width: 3),
        Icon(Icons.battery_full_rounded, size: 12, color: tenue),
      ],
    );
  }
}

class _IconoApp extends StatelessWidget {
  final IconData glifo;
  final Color tono;
  const _IconoApp(this.glifo, this.tono);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [tono, Color.lerp(tono, Colors.black, 0.35)!],
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(glifo, size: 19, color: _marfil.withValues(alpha: 0.92)),
        ),
        const SizedBox(height: 5),
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: _marfil.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
