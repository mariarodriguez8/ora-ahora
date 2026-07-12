import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../services/prefs_service.dart';
import '../../services/purchase_service.dart';
import '../../services/streak_service.dart';
import '../../services/voice_prayer_service.dart';
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

  /// `true` solo si el interruptor de Ajustes esta activo Y el
  /// reconocimiento de voz en el dispositivo esta disponible en este
  /// telefono; controla si se muestra el boton "Escuchar mi oración".
  bool _voiceFeatureAvailable = false;
  bool _listening = false;
  String _partialText = '';

  DateTime? _listenStartedAt;
  DateTime? _lastSpeechAt;
  Timer? _progressTimer;

  /// No mas de esta cantidad de silencio (sin actualizaciones de texto
  /// reconocido) al momento de alcanzar el umbral de duracion, para
  /// contar la oracion como "hablada de forma continua" (ver
  /// [_checkAutoConfirmByDuration]).
  static const Duration _maxSilenceGap = Duration(seconds: 6);

  /// Fraccion de `duracion_estimada_min` de la oracion que se exige de
  /// habla continua para auto-confirmar por duracion (ver brief de
  /// producto: "~70% del tiempo estimado").
  static const double _durationConfirmFraction = 0.7;

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
    _checkVoiceFeature();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pulseController.dispose();
    _entranceController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _checkVoiceFeature() async {
    final prefs = context.read<PrefsService>();
    if (!prefs.voiceDetectionEnabled) {
      if (mounted) setState(() => _voiceFeatureAvailable = false);
      return;
    }
    final available = await _voiceService.checkAvailability();
    if (!mounted) return;
    setState(() => _voiceFeatureAvailable = available);
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
    await streak.markPrayedToday(
      isPlusUser: isPlus,
      minutes: widget.prayer.duracionEstimadaMin,
    );
    if (!mounted) return;
    setState(() => _markedNow = true);
  }

  Future<void> _onManualMarkPressed() async {
    final streak = context.read<StreakService>();
    await _confirmPrayed();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Racha actualizada: ${streak.currentStreak} '
          '${streak.currentStreak == 1 ? "día" : "días"} seguidos 🙏',
        ),
      ),
    );
  }

  Future<void> _startListening() async {
    if (_listening || _markedNow) return;

    setState(() {
      _listening = true;
      _partialText = '';
    });
    _listenStartedAt = DateTime.now();
    _lastSpeechAt = null;

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkAutoConfirmByDuration(),
    );

    final started = await _voiceService.startListening(
      onPartialResult: _onPartialResult,
      onDone: _onListeningDone,
    );

    if (!started && mounted) {
      // No disponible en este intento (permiso revocado, sin modelo
      // on-device, etc.): degradarse en silencio, sin dialogos de error.
      _progressTimer?.cancel();
      setState(() {
        _listening = false;
        _voiceFeatureAvailable = false;
      });
    }
  }

  void _onPartialResult(String recognizedWords) {
    if (!mounted || !_listening) return;
    setState(() => _partialText = recognizedWords);
    if (recognizedWords.trim().isNotEmpty) {
      _lastSpeechAt = DateTime.now();
    }
    if (_containsAmen(recognizedWords)) {
      _handleAutoConfirm();
    }
  }

  void _checkAutoConfirmByDuration() {
    if (!_listening || _markedNow) return;
    final startedAt = _listenStartedAt;
    if (startedAt == null) return;

    final now = DateTime.now();
    final elapsedSeconds = now.difference(startedAt).inSeconds;
    final thresholdSeconds =
        widget.prayer.duracionEstimadaMin * 60 * _durationConfirmFraction;
    final lastSpeech = _lastSpeechAt;
    final silenceGap = lastSpeech == null
        ? now.difference(startedAt)
        : now.difference(lastSpeech);

    if (elapsedSeconds >= thresholdSeconds && silenceGap <= _maxSilenceGap) {
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
    await _confirmPrayed();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '¡Detectado! Oración completada. Racha actualizada: '
          '${streak.currentStreak} '
          '${streak.currentStreak == 1 ? "día" : "días"} seguidos 🙏',
        ),
      ),
    );
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
    final yaCompletada = yaOradaHoy || _markedNow;

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
                    onPressed: (yaOradaHoy && !_markedNow)
                        ? null
                        : _onManualMarkPressed,
                    icon: Icon(
                      yaCompletada
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                    ),
                    label: Text(
                      yaCompletada ? 'Ya oraste hoy' : 'Marcar como orada hoy',
                    ),
                  ),
                ),
                if (_voiceFeatureAvailable && !yaCompletada) ...[
                  const SizedBox(height: 14),
                  _VoicePrayerSection(
                    listening: _listening,
                    partialText: _partialText,
                    pulseController: _pulseController,
                    onStart: _startListening,
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

/// Tarjeta "sagrada" que agrupa titulo, duracion, texto completo y
/// referencia biblica de la oracion sobre un fondo tonal propio, con el
/// mismo lenguaje visual que la seccion hero del inicio
/// (`_HeroPrayerSection` en `home_screen.dart`): fondo con
/// `primaryContainer`/`onPrimaryContainer` del `ColorScheme` activo (se
/// adapta automaticamente a cualquiera de las 4 paletas de Ajustes >
/// Apariencia) y un par de circulos translucidos del mismo tono como
/// unica decoracion, sin gradientes ni imagenes.
class _PrayerHeroCard extends StatelessWidget {
  final Prayer prayer;

  const _PrayerHeroCard({required this.prayer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: _softCircle(scheme.primary, 130, 0.10),
          ),
          Positioned(
            top: -6,
            right: 24,
            child: _softCircle(scheme.primary, 64, 0.16),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORACIÓN',
                  style: AppTypography.caption.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  prayer.titulo,
                  style: AppTypography.display.copyWith(
                    fontSize: 27,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${prayer.duracionEstimadaMin} min aprox.',
                      style: AppTypography.caption.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  prayer.texto,
                  style: AppTypography.bodyLarge.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.menu_book,
                        color: scheme.onSecondaryContainer,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          prayer.referenciaBiblica,
                          style: AppTypography.body.copyWith(
                            fontStyle: FontStyle.italic,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _softCircle(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// UI del boton opcional "Escuchar mi oración" y su indicador de
/// escucha (icono de microfono pulsante + texto parcial reconocido).
/// Widget sin estado propio: todo el estado vive en
/// `_PrayerDetailScreenState` para que la logica de auto-confirmacion se
/// mantenga en un solo lugar.
class _VoicePrayerSection extends StatelessWidget {
  final bool listening;
  final String partialText;
  final AnimationController pulseController;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  const _VoicePrayerSection({
    required this.listening,
    required this.partialText,
    required this.pulseController,
    required this.onStart,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (!listening) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.mic_none),
            label: const Text('Escuchar mi oración'),
          ),
          const SizedBox(height: 6),
          Text(
            'Opcional: procesa tu voz 100% en este teléfono, nunca la envía a un servidor.',
            style: AppTypography.caption.copyWith(color: AppColors.inkSoft),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tealLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.15).animate(
              CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
            ),
            child: const Icon(Icons.mic, color: AppColors.tealDeep, size: 40),
          ),
          const SizedBox(height: 10),
          Text('Escuchando tu oración...', style: AppTypography.title),
          const SizedBox(height: 6),
          if (partialText.trim().isNotEmpty)
            Text(
              partialText,
              style: AppTypography.body.copyWith(
                color: AppColors.inkSoft,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
