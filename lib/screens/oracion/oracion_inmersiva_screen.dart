import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// La oración larga, en pantalla completa y a oscuras.
///
/// La pausa corta se salta en cuatro segundos porque no pasa nada: aparece
/// un texto, se lee, se cierra. Aquí sí pasa algo. La pantalla se apaga, la
/// oración llega línea a línea al ritmo al que respirarías, y no está toda
/// puesta: por eso no se puede leer de un vistazo y salir.
///
/// Es la misma pantalla que después servirá para el audio, cuando lo haya.
class OracionInmersivaScreen extends StatefulWidget {
  final List<String> lineas;
  final String? referencia;

  const OracionInmersivaScreen({
    super.key,
    required this.lineas,
    this.referencia,
  });

  /// Parte un texto en líneas respirables por sus frases.
  static List<String> partir(String texto) {
    final crudo = texto
        .replaceAll('\n', ' ')
        .split(RegExp(r'(?<=[.:;?!])\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return crudo.isEmpty ? [texto.trim()] : crudo;
  }

  @override
  State<OracionInmersivaScreen> createState() => _OracionInmersivaScreenState();
}

class _OracionInmersivaScreenState extends State<OracionInmersivaScreen> {
  int _i = 0;
  bool _terminada = false;
  Timer? _timer;

  /// Cuánto se queda cada línea: las frases largas necesitan más aire.
  Duration _duracionDe(String linea) {
    final ms = 2600 + linea.length * 55;
    return Duration(milliseconds: ms.clamp(2600, 7000));
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _programar();
  }

  void _programar() {
    _timer?.cancel();
    _timer = Timer(_duracionDe(widget.lineas[_i]), _avanzar);
  }

  void _avanzar() {
    if (!mounted) return;
    if (_i < widget.lineas.length - 1) {
      setState(() => _i++);
      _programar();
    } else {
      setState(() => _terminada = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tealDeep,
      body: GestureDetector(
        onTap: () {
          if (_terminada) return;
          _timer?.cancel();
          _avanzar();
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(34, 24, 34, 30),
            child: Column(
              children: [
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 900),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Text(
                    widget.lineas[_i],
                    key: ValueKey(_i),
                    textAlign: TextAlign.center,
                    style: AppTypography.prayerText.copyWith(
                      color: AppColors.cream,
                      fontSize: 23,
                      height: 1.55,
                    ),
                  ),
                ),
                if (_terminada && widget.referencia != null) ...[
                  const SizedBox(height: 22),
                  Text(widget.referencia!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.amberLight,
                        fontStyle: FontStyle.italic,
                      )),
                ],
                const Spacer(),
                AnimatedOpacity(
                  opacity: _terminada ? 1 : 0,
                  duration: const Duration(milliseconds: 700),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _terminada
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cream,
                        foregroundColor: AppColors.tealDeep,
                        disabledBackgroundColor: Colors.transparent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Amén',
                          style: AppTypography.title.copyWith(
                            color: AppColors.tealDeep,
                            fontSize: 16,
                          )),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.lineas.length, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= _i
                            ? AppColors.amberLight
                            : AppColors.cream.withValues(alpha: 0.22),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
