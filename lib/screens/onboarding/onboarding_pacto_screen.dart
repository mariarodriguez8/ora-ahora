import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'onboarding_sellado_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../services/prefs_service.dart';
import '../../theme/app_typography.dart';
import 'funnel_base.dart';

/// El acta del pacto, con firma a dedo.
///
/// Al firmar se guarda el acta completa como imagen y queda entre las
/// estampas. No es un souvenir: es lo que va a volver a mirar el dia malo.
class OnboardingPactoScreen extends StatefulWidget {
  final VoidCallback onContinuar;
  const OnboardingPactoScreen({super.key, required this.onContinuar});

  @override
  State<OnboardingPactoScreen> createState() => _OnboardingPactoScreenState();
}

class _OnboardingPactoScreenState extends State<OnboardingPactoScreen> {
  final GlobalKey _actaKey = GlobalKey();
  final List<List<Offset>> _trazos = [];
  bool _guardando = false;

  bool get _hayFirma => _trazos.any((t) => t.length > 1);

  String _fechaHoy() {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final h = DateTime.now();
    return '${h.day} de ${meses[h.month - 1]} de ${h.year}';
  }

  Future<void> _sellar() async {
    if (!_hayFirma || _guardando) return;
    setState(() => _guardando = true);
    try {
      final limite =
          _actaKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final imagen = await limite.toImage(pixelRatio: 3);
      final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        final dir = await getApplicationDocumentsDirectory();
        final ruta = '${dir.path}/pacto_con_dios.png';
        await File(ruta).writeAsBytes(bytes.buffer.asUint8List());
        if (mounted) {
          await context.read<PrefsService>().setPactoImagenRuta(ruta);
        }
      }
    } catch (_) {
      // Si falla el guardado no bloqueamos: el pacto ya se hizo.
    }
    if (!mounted) return;
    setState(() => _guardando = false);
    // Primero la celebracion: acaba de firmar y el gesto necesita existir
    // antes de que aparezca nada mas.
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OnboardingSelladoScreen(),
      ),
    );
    if (!mounted) return;
    // Y ahi, en el pico emocional, se pide la resena. Nunca dos veces.
    await _pedirResena();
    if (!mounted) return;
    widget.onContinuar();
  }

  Future<void> _pedirResena() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getBool('resena_pedida') == true) return;
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      await p.setBool('resena_pedida', true);
      await review.requestReview();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final nombre = context.read<PrefsService>().userName ?? '';
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
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: RepaintBoundary(
                      key: _actaKey,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F3EA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text('MI PACTO CON DIOS',
                                  style: AppTypography.body.copyWith(
                                      fontSize: 12,
                                      letterSpacing: 3,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF8A5F27))),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'Dios,\n'
                              'dejé de hablarte y ni me di cuenta cuándo.\n\n'
                              'Hoy vuelvo.\n'
                              'Un minuto al día. Eso sí puedo.\n'
                              'Va a haber días que no quiera. Igual vengo.\n\n'
                              'Y cuando no me salgan las palabras,\n'
                              'guíame para no irme otra vez.\n\n'
                              'Hoy me comprometo a volver a ti. Te amo, Padre.',
                              style: AppTypography.body.copyWith(
                                  fontSize: 15.5,
                                  height: 1.55,
                                  color: const Color(0xFF241F10)),
                            ),
                            const SizedBox(height: 26),
                            // Tablero de firma: es el compromiso fisico.
                            GestureDetector(
                              onPanStart: (d) => setState(
                                  () => _trazos.add([d.localPosition])),
                              onPanUpdate: (d) => setState(
                                  () => _trazos.last.add(d.localPosition)),
                              child: Container(
                                height: 110,
                                width: double.infinity,
                                color: Colors.transparent,
                                child: CustomPaint(
                                  painter: _FirmaPainter(_trazos),
                                  child: _hayFirma
                                      ? null
                                      : Center(
                                          child: Text('Firma aquí con tu dedo',
                                              style: AppTypography.body
                                                  .copyWith(
                                                      fontSize: 13,
                                                      color: const Color(
                                                          0xFF8A5F27))),
                                        ),
                                ),
                              ),
                            ),
                            Container(
                                height: 1, color: const Color(0xFF241F10)),
                            const SizedBox(height: 8),
                            Text(_fechaHoy(),
                                style: AppTypography.body.copyWith(
                                    fontSize: 12,
                                    color: const Color(0xFF6B6357))),
                            if (nombre.isNotEmpty)
                              Text(nombre,
                                  style: AppTypography.body.copyWith(
                                      fontSize: 12,
                                      color: const Color(0xFF6B6357))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _hayFirma ? kFunnelDorado : kFunnelMarfil.withValues(alpha: 0.22),
                      foregroundColor: const Color(0xFF241F10),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _hayFirma ? _sellar : null,
                    child: Text(_guardando ? 'Guardando...' : 'Sellar mi pacto'),
                  ),
                ),
                if (_hayFirma)
                  TextButton(
                    onPressed: () => setState(() => _trazos.clear()),
                    child: Text('borrar y firmar de nuevo',
                        style: AppTypography.body.copyWith(
                            fontSize: 13,
                            color: kFunnelMarfil.withValues(alpha: 0.6))),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FirmaPainter extends CustomPainter {
  final List<List<Offset>> trazos;
  _FirmaPainter(this.trazos);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF241F10)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final t in trazos) {
      for (var i = 0; i < t.length - 1; i++) {
        canvas.drawLine(t[i], t[i + 1], p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FirmaPainter old) => true;
}
