import 'dart:async';
import 'package:flutter/material.dart';

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
    'Hace dos mil años,\nun hombre contó esto:\n\nUn pastor tenía\ncien ovejas.',
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
                    AnimatedOpacity(
                      opacity: 0.55,
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        _completa ? 'Toca para seguir' : 'Lucas 15  ·  toca',
                        style: AppTypography.caption.copyWith(color: _marfil),
                      ),
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
                    onPressed: _fase >= 3 ? widget.onContinuar : null,
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
class _TelefonoFalso extends StatelessWidget {
  const _TelefonoFalso();

  @override
  Widget build(BuildContext context) {
    final ahora = TimeOfDay.now();
    final hora = ahora.hour.toString().padLeft(2, '0');
    final minuto = ahora.minute.toString().padLeft(2, '0');

    return Container(
      width: 176,
      height: 264,
      padding: const EdgeInsets.fromLTRB(14, 26, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1712),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _marfil.withValues(alpha: 0.28), width: 2),
      ),
      child: Column(
        children: [
          Text(
            '$hora:$minuto',
            style: AppTypography.display.copyWith(
              fontSize: 46,
              height: 1,
              color: _marfil,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'hoy',
            style: AppTypography.caption.copyWith(
              color: _marfil.withValues(alpha: 0.55),
            ),
          ),
          const Spacer(),
          // Cuatro apps cualquiera, sin marca ninguna: son cuadrados.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final c in const [
                Color(0xFFE8833A),
                Color(0xFF4A8FE7),
                Color(0xFFD94F6E),
                Color(0xFF43B36B),
              ])
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
