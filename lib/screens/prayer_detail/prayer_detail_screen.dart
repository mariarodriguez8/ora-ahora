import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../services/purchase_service.dart';
import '../../services/streak_service.dart';
import '../../widgets/amen_celebration.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Muestra el texto completo de una oracion, la referencia biblica, un
/// boton para escucharla en voz alta (lectura por la voz del propio
/// telefono, sin microfono ni permisos) y el boton para marcarla como
/// orada hoy (actualiza la racha).
///
/// v31: se elimino la deteccion por microfono (paquete speech_to_text) por
/// pedido de la clienta. Ya no se pide RECORD_AUDIO. La unica funcion de
/// "voz" que queda es LEER la oracion en voz alta con `flutter_tts`, que
/// no necesita ningun permiso.
class PrayerDetailScreen extends StatefulWidget {
  final Prayer prayer;

  const PrayerDetailScreen({super.key, required this.prayer});

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen>
    with TickerProviderStateMixin {
  bool _markedNow = false;
  bool _speaking = false;

  final FlutterTts _tts = FlutterTts();

  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.44);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setErrorHandler((_) {
        if (mounted) setState(() => _speaking = false);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleSpeak() async {
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    try {
      await _tts.stop();
      await _tts.speak(widget.prayer.texto);
    } catch (_) {
      if (mounted) setState(() => _speaking = false);
    }
  }

  /// Actualiza la racha con la misma funcion (`StreakService`) sin importar
  /// como se confirmo la oracion.
  Future<void> _confirmPrayed() async {
    final streak = context.read<StreakService>();
    final isPlus = context.read<PurchaseService>().isPlusUser;
    if (streak.prayedToday) {
      await streak.addExtraMinutes(widget.prayer.duracionEstimadaMin);
    } else {
      await streak.markPrayedToday(
        isPlusUser: isPlus,
        minutes: widget.prayer.duracionEstimadaMin,
      );
    }
    if (!mounted) return;
    setState(() => _markedNow = true);
  }

  Future<void> _onManualMarkPressed() async {
    await _tts.stop();
    if (mounted) setState(() => _speaking = false);
    final streak = context.read<StreakService>();
    final yaHabiaOrado = streak.prayedToday;
    await _confirmPrayed();
    if (!mounted) return;
    if (yaHabiaOrado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Amén! Tu árbol de fe sigue creciendo 🌱 '
            '(+${widget.prayer.duracionEstimadaMin} min)',
          ),
        ),
      );
    } else {
      await showAmenCelebration(
        context,
        streak: streak.currentStreak,
        referencia: widget.prayer.referenciaBiblica,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakService>();
    final yaOradaHoy = streak.prayedToday;

    return Scaffold(
      appBar: AppBar(
        title: Text(PrayerCategories.displayName(widget.prayer.categoria)),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _entranceFade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PrayerHeroCard(prayer: widget.prayer),
                const SizedBox(height: 16),
                // "Leer en voz alta": la voz del propio telefono lee la
                // oracion. Sin microfono, sin permisos.
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _toggleSpeak,
                    icon: Icon(_speaking
                        ? Icons.stop_rounded
                        : Icons.volume_up_rounded),
                    label: Text(
                      _speaking ? 'Detener' : 'Escuchar la oración 🔊',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _markedNow ? null : _onManualMarkPressed,
                    icon: Icon(
                      _markedNow
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                    ),
                    label: Text(
                      _markedNow
                          ? 'Oración registrada ✅'
                          : yaOradaHoy
                              ? 'Orar esta también 🙏'
                              : 'Amén — ya oré 🙏',
                    ),
                  ),
                ),
                if (_markedNow) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Continuar 🌿'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pagina devocional de la oracion: se lee como la pagina de un libro.
class _PrayerHeroCard extends StatelessWidget {
  final Prayer prayer;

  const _PrayerHeroCard({required this.prayer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.brightness == Brightness.dark
            ? scheme.surfaceContainerHighest
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(26, 32, 26, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ORACIÓN · ${prayer.duracionEstimadaMin} MIN',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: scheme.secondary),
          ),
          const SizedBox(height: 14),
          Text(
            prayer.titulo,
            textAlign: TextAlign.center,
            style: AppTypography.display.copyWith(
              fontSize: 27,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '✦',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: scheme.secondary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            prayer.texto,
            style: AppTypography.prayerText.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: scheme.secondary, width: 2),
              ),
            ),
            child: Text(
              prayer.referenciaBiblica,
              style: AppTypography.quote.copyWith(color: scheme.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
