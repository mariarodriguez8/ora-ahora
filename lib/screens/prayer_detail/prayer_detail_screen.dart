import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../services/prefs_service.dart';
import '../../services/purchase_service.dart';
import '../../services/streak_service.dart';
import '../../services/voice_prayer_service.dart';
import '../../widgets/amen_celebration.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Muestra el texto completo de una oracion, la referencia biblica y el
/// boton para marcarla como orada hoy (actualiza la racha).
///
/// Si en Ajustes > Voz se activo "Detectar cuando termino de orar (con
/// micrófono)" Y el reconocimiento de voz en el dispositivo esta
/// disponible en este telefono, tambien se muestra un boton opcional
/// "Escuchar mi oración" (ver [_VoicePrayerSection] mas abajo) que usa
/// `VoicePrayerService` (paquete `speech_to_text`, SIEMPRE con
/// `onDevice: true`) para confirmar automaticamente la misma accion que
/// el boton manual, sin reemplazarlo nunca: el boton manual sigue siempre
/// visible y funcional, incluso si el interruptor de voz esta activo.
class PrayerDetailScreen extends StatefulWidget {
  final Prayer prayer;

  const PrayerDetailScreen({super.key, required this.prayer});

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen>
    with TickerProviderStateMixin {
  bool _markedNow = false;

  final VoicePrayerService _voiceService = VoicePrayerService();
  late final AnimationController _pulseController;

  /// Entrada suave de toda la pantalla (fundido, sin desplazamiento) al
  /// abrir una oracion, para que se sienta consistente con el mismo
  /// patron de entrada usado en el inicio (`Curves.easeOutCubic` sobre la
  /// opacidad, ver `home_screen.dart` -> `_staggeredSection`). Aqui es una
  /// unica seccion (no escalonada) porque toda la pantalla es, en esencia,
  /// un solo "momento" (la tarjeta de oracion), a diferencia del inicio
  /// que tiene varias secciones con distinta jerarquia.
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;

  bool _listening = false;
  String _partialText = '';
  Timer? _progressTimer;

  /// Palabras significativas (4+ letras, sin tildes) del texto de la
  /// oracion: la confirmacion por voz exige que la persona diga una
  /// parte real de ESTA oracion, no cualquier cosa.
  late final Set<String> _prayerTokens;
  final Set<String> _matchedTokens = {};

  double get _coverage => _prayerTokens.isEmpty
      ? 0
      : _matchedTokens.length / _prayerTokens.length;

  /// Cobertura minima de la oracion dicha en voz alta para confirmarla.
  static const double _coverageToConfirm = 0.55;

  /// Si la persona cierra con "amen", basta con esta cobertura.
  static const double _coverageWithAmen = 0.30;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _prayerTokens = _tokenize(widget.prayer.texto);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pulseController.dispose();
    _entranceController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  static Set<String> _tokenize(String text) {
    final normalized = _stripDiacritics(text.toLowerCase());
    return RegExp(r'[a-zñ]{4,}')
        .allMatches(normalized)
        .map((m) => m.group(0)!)
        .toSet();
  }

  /// Nunca se pide el microfono "en frio": la primera vez se muestra la
  /// pantalla que explica con calma para que sirve y que la voz se
  /// procesa 100% en el telefono. Solo despues se inicia la escucha.
  Future<void> _ensureVoiceReadyAndStart() async {
    final prefs = context.read<PrefsService>();
    // Si el sistema YA dio el permiso, cero preguntas: a orar directo.
    final yaTienePermiso = await _voiceService.hasMicPermission;
    if (!mounted) return;
    if (yaTienePermiso) {
      await _startListening();
      return;
    }
    // Sin permiso: UNA sola pantalla de contexto y luego el dialogo del
    // sistema. Nunca doble pregunta.
    if (true) {
      final acepta = await showModalBottomSheet<bool>(
        context: context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎙️🙏', style: TextStyle(fontSize: 34)),
              const SizedBox(height: 12),
              Text('Oremos juntos, en voz alta',
                  style: AppTypography.headline.copyWith(fontSize: 21)),
              const SizedBox(height: 10),
              Text(
                'Si me lo permites, te escucho mientras oras y marco la '
                'oración por ti cuando la termines. Para eso necesito '
                'acceso a tu micrófono. Tu voz se queda en tu teléfono: '
                'nunca se graba ni se envía a ningún lado.',
                style: AppTypography.body.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sí, escúchame orar 🙏'),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Ahora no'),
                ),
              ),
            ],
          ),
        ),
      );
      if (acepta != true || !mounted) return;
      await prefs.setMicPrimingDone(true);
      await prefs.setVoiceDisclosureSeen(true);
      if (!mounted) return;
    }
    final available = await _voiceService.checkAvailability();
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('No pudimos activar el micrófono en este teléfono 😔'),
      ));
      return;
    }
    await _startListening();
  }

  static String _stripDiacritics(String input) {
    const from = 'áéíóúÁÉÍÓÚñÑ';
    const to = 'aeiouAEIOUnN';
    var result = input;
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }

  bool _containsAmen(String text) {
    final normalized = _stripDiacritics(text.toLowerCase());
    return RegExp(r'\bamen\b').hasMatch(normalized);
  }

  /// Llamada por AMBOS caminos de confirmacion (el boton manual y la
  /// deteccion por voz): actualiza la racha con exactamente la misma
  /// funcion (`StreakService.markPrayedToday`) para que el resultado sea
  /// identico sin importar como se confirmo la oracion.
  Future<void> _confirmPrayed() async {
    final streak = context.read<StreakService>();
    final isPlus = context.read<PurchaseService>().isPlusUser;
    if (streak.prayedToday) {
      // Orar mas de una vez al dia SIEMPRE se puede: la racha no cambia,
      // pero el arbol de fe sigue sumando minutos.
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
      // Primera oracion del dia: momento Amen a pantalla completa.
      await showAmenCelebration(
        context,
        streak: streak.currentStreak,
        referencia: widget.prayer.referenciaBiblica,
      );
    }
  }

  Future<void> _startListening() async {
    if (_listening || _markedNow) return;

    setState(() {
      _listening = true;
      _partialText = '';
      _matchedTokens.clear();
    });

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted && _listening) setState(() {});
      },
    );

    final started = await _voiceService.startListening(
      onPartialResult: _onPartialResult,
      onDone: _onListeningDone,
    );

    if (!started && mounted) {
      // No disponible en este intento (permiso revocado, sin modelo
      // on-device, etc.): degradarse en silencio, sin dialogos de error.
      _progressTimer?.cancel();
      setState(() => _listening = false);
    }
  }

  void _onPartialResult(String recognizedWords) {
    if (!mounted || !_listening) return;
    _matchedTokens.addAll(
      _tokenize(recognizedWords).where(_prayerTokens.contains),
    );
    setState(() => _partialText = recognizedWords);

    // Solo cuenta como orada si de verdad se dijo (buena parte de) ESTA
    // oracion: cobertura alta por si sola, o cierre con "amen" cuando ya
    // se dijo al menos un tercio.
    if (_coverage >= _coverageToConfirm ||
        (_containsAmen(recognizedWords) && _coverage >= _coverageWithAmen)) {
      _handleAutoConfirm();
    }
  }

  Future<void> _handleAutoConfirm() async {
    if (_markedNow) return;
    _progressTimer?.cancel();
    await _voiceService.stopListening();
    if (!mounted) return;
    setState(() => _listening = false);

    final streak = context.read<StreakService>();
    final yaHabiaOrado = streak.prayedToday;
    await _confirmPrayed();
    if (!mounted) return;
    if (yaHabiaOrado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Amén! Te escuchamos orar 🙏 Tu árbol sigue '
              'creciendo 🌱'),
        ),
      );
    } else {
      await showAmenCelebration(
        context,
        streak: streak.currentStreak,
        referencia: widget.prayer.referenciaBiblica,
      );
    }
  }

  /// Se llama cuando `speech_to_text` deja de escuchar sin que la
  /// pantalla lo haya pedido (silencio prolongado detectado por el
  /// propio motor, error, o limite maximo de tiempo alcanzado). Nunca
  /// muestra dialogos de error: solo vuelve al estado inicial para que
  /// la persona pueda tocar de nuevo "Escuchar mi oración" o usar el
  /// boton manual.
  void _onListeningDone({required bool success}) {
    if (!mounted) return;
    _progressTimer?.cancel();
    setState(() => _listening = false);
  }

  Future<void> _cancelListening() async {
    _progressTimer?.cancel();
    await _voiceService.stopListening();
    if (!mounted) return;
    setState(() {
      _listening = false;
      _partialText = '';
    });
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
                const SizedBox(height: 28),
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
                if (!_markedNow) ...[
                  const SizedBox(height: 14),
                  _VoicePrayerSection(
                    listening: _listening,
                    partialText: _partialText,
                    coverage: _coverage,
                    pulseController: _pulseController,
                    onStart: _ensureVoiceReadyAndStart,
                    onCancel: _cancelListening,
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

/// Pagina devocional de la oracion: se lee como la pagina de un libro,
/// no como una tarjeta de UI. Overline dorada centrada, titulo serif
/// centrado, texto de oracion en serif con interlineado generoso y la
/// referencia biblica como cita con filete dorado.
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
          // Pequeño ornamento tipografico como separador, en vez de una
          // linea dura.
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

/// Boton "Orar en voz alta" + indicador de escucha con barra de progreso
/// de la propia oracion (que porcentaje del texto ya se dijo). Todo el
/// estado vive en `_PrayerDetailScreenState`.
class _VoicePrayerSection extends StatelessWidget {
  final bool listening;
  final String partialText;
  final double coverage;
  final AnimationController pulseController;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  const _VoicePrayerSection({
    required this.listening,
    required this.partialText,
    required this.coverage,
    required this.pulseController,
    required this.onStart,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!listening) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.mic_none_rounded),
            label: const Text('Orar en voz alta 🎙️'),
          ),
          const SizedBox(height: 6),
          Text(
            'Si oras en voz alta, te escuchamos y marcamos la oración por '
            'ti. Tu voz nunca sale de tu teléfono.',
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSoft,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final pct = (coverage * 100).clamp(0, 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18163A), Color(0xFF0A3A30)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          // MIC GIGANTE con ondas que respiran (hecho para grabarse)
          SizedBox(
            width: 190,
            height: 190,
            child: AnimatedBuilder(
              animation: pulseController,
              builder: (context, _) {
                final v = pulseController.value;
                Widget onda(double base, double alpha) => Container(
                      width: base + 46 * v,
                      height: base + 46 * v,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD18C)
                              .withValues(alpha: alpha * (1 - v * 0.6)),
                          width: 2.5,
                        ),
                      ),
                    );
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    onda(150, 0.35),
                    onda(118, 0.55),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD18C),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD18C)
                                .withValues(alpha: 0.45 + 0.3 * v),
                            blurRadius: 34 + 18 * v,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.mic_rounded,
                          size: 48, color: Color(0xFF241F10)),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text('Te escucho… sigue orando 🙏',
              style: AppTypography.headline.copyWith(
                  fontSize: 20, color: const Color(0xFFF7F3EA))),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: coverage.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFFFD18C)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pct == 0
                ? 'Lee la oración en voz alta, con calma'
                : 'Ya llevas el $pct% · cierra con "Amén"',
            style: AppTypography.caption.copyWith(
                color: const Color(0xFFF7F3EA).withValues(alpha: 0.7),
                letterSpacing: 0.4),
            textAlign: TextAlign.center,
          ),
          if (partialText.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              partialText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.quote.copyWith(
                fontSize: 13.5,
                color: const Color(0xFFF7F3EA).withValues(alpha: 0.75),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 4),
          TextButton(
            onPressed: onCancel,
            child: Text('Cancelar',
                style: TextStyle(
                    color: const Color(0xFFF7F3EA)
                        .withValues(alpha: 0.6))),
          ),
        ],
      ),
    );
  }
}
