import 'package:flutter/material.dart';

import 'onboarding_anim.dart';

import '../../theme/app_typography.dart';

/// Respuestas del embudo emocional (viven solo durante el onboarding).
class FunnelAnswers {
  static String nombre = '';
  static String horasCelular = '';
  static String tiempoDios = '';
}

const kFunnelIndigo = Color(0xFF18163A);
const kFunnelEsmeralda = Color(0xFF0A3A30);
const kFunnelDorado = Color(0xFFFFD18C);
const kFunnelMarfil = Color(0xFFF7F3EA);

/// Pantalla del embudo: UNA frase, la ovejita actuando la frase, y
/// opciones grandes. Cero adornos compitiendo con la emocion.
class FunnelScreen extends StatelessWidget {
  final String frase;
  final String? subtitulo;
  final String mascota; // ruta del asset de la ovejita
  final List<(String, VoidCallback)> opciones;
  final bool amanecer; // true = el fondo amanece (momento de gracia)
  /// Cuanto ocupa la ovejita. Grande en las pantallas de golpe,
  /// pequena donde el texto es el protagonista.
  final double alturaMascota;
  /// Posicion dentro del embudo (0-7) para la barra de avance.
  final int? pasoEmbudo;
  /// Contenido opcional entre el subtitulo y los botones.
  final Widget? extra;

  const FunnelScreen({
    super.key,
    required this.frase,
    this.subtitulo,
    required this.mascota,
    required this.opciones,
    this.amanecer = false,
    this.alturaMascota = 170,
    this.pasoEmbudo,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: amanecer
                ? [const Color(0xFF2E3A2F), const Color(0xFFB98352)]
                : [kFunnelIndigo, kFunnelEsmeralda],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pasoEmbudo != null) ...[
                  const SizedBox(height: 6),
                  _BarraEmbudo(paso: pasoEmbudo!),
                ],
                const Spacer(),
                AparicionSuave(orden: 0, child: Center(
                  child: Image.asset(mascota, height: alturaMascota,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium),
                )),
                const Spacer(),
                AparicionSuave(orden: 1, child: Text(frase,
                    style: AppTypography.display
                        .copyWith(fontSize: 30, color: kFunnelMarfil))),
                if (subtitulo != null) ...[
                  const SizedBox(height: 8),
                  AparicionSuave(orden: 2, child: Text(subtitulo!,
                      style: AppTypography.body.copyWith(
                          color: kFunnelMarfil.withValues(alpha: 0.6)))),
                ],
                if (extra != null) ...[
                  const SizedBox(height: 18),
                  AparicionSuave(orden: 3, child: extra!),
                ],
                const SizedBox(height: 24),
                for (final (i, (texto, onTap)) in opciones.indexed) ...[
                  AparicionSuave(orden: 4 + i, child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            opciones.first.$1 == texto && opciones.length == 1
                                ? kFunnelDorado
                                : kFunnelMarfil.withValues(alpha: 0.94),
                        foregroundColor: const Color(0xFF241F10),
                      ),
                      onPressed: onTap,
                      child: Text(texto, textAlign: TextAlign.center),
                    ),
                  )),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tres tarjetas de canciones, en el estilo de la app.
///
/// A proposito NO usamos las portadas reales de los discos: son material con
/// derechos de sus sellos y ademas chocan con el trazo ilustrado de la
/// ovejita. Estas se ven propias y sirven despues para el home.
class TarjetasCanciones extends StatelessWidget {
  const TarjetasCanciones({super.key});

  static const _lista = <(String, String)>[
    ('Vuelvo a Ti', 'Un Corazón'),
    ('Océanos', 'Hillsong United'),
    ('Todo Va a Estar Bien', 'Redimi2'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (idx, (titulo, artista)) in _lista.indexed) ...[
          if (idx > 0) const SizedBox(width: 10),
          Expanded(child: _Tarjeta(titulo: titulo, artista: artista)),
        ],
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final String titulo;
  final String artista;
  const _Tarjeta({required this.titulo, required this.artista});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kFunnelMarfil.withValues(alpha: 0.18)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kFunnelMarfil.withValues(alpha: 0.17),
            kFunnelMarfil.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
                color: kFunnelDorado, shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded,
                size: 18, color: Color(0xFF241F10)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                      fontSize: 12,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      color: kFunnelMarfil)),
              const SizedBox(height: 2),
              Text(artista,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                      fontSize: 10,
                      color: kFunnelMarfil.withValues(alpha: 0.6))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Avance dentro del embudo. Son ocho pantallas antes del onboarding con
/// formulario y no habia ninguna señal de cuanto falta.
class _BarraEmbudo extends StatelessWidget {
  final int paso;
  const _BarraEmbudo({required this.paso});

  @override
  Widget build(BuildContext context) {
    const total = 8;
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 110,
        height: 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            children: [
              Container(color: kFunnelMarfil.withValues(alpha: 0.22)),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOut,
                widthFactor: ((paso + 1) / total).clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(color: kFunnelDorado),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
