#!/usr/bin/env bash
# apply_v11c.sh — ORA AHORA v11c: la ovejita en TODA la app (pedido Maria).
#  - Bienvenida: CRUZ DE LUZ restaurada en el halo (se deshace la ovejita
#    dentro del circulo con fondo verde); la ovejita asoma desde la
#    esquina inferior derecha con recorte transparente.
#  - Onboarding COMPLETO: la ovejita camina sobre los puntos de progreso
#    y avanza contigo en cada una de las pantallas.
#  - Orar con microfono: la ovejita GRANDE y AL CENTRO (no en esquina),
#    halo dorado respirando detras, mic como insignia.
#  - Diario: ovejita en estado vacio y en el encabezado de la lista.
#  - Ajustes: ovejita en el encabezado.
#  - assets/mascot/ovejita.png REEMPLAZADA por recorte SIN FONDO real
#    (arregla tambien el avatar del inicio y el gate explainer).
# Autocontenido e idempotente.
set -euo pipefail
cd "$(dirname "$0")"
if [ ! -f pubspec.yaml ]; then
  echo "ERROR: ejecuta este script desde la raiz del repo" >&2
  exit 1
fi

mkdir -p assets/mascot
# Recorte transparente oficial de la ovejita (reemplaza SIEMPRE, es la
# correccion del fondo verde).
wget -q "https://d8j0ntlcm91z4.cloudfront.net/user_357fcxDIqY9TMqfewNOAYaGunxR/hf_20260716_051916_f79c8e47-5975-4984-bc82-af3ac77e0be5.png" -O assets/mascot/ovejita.png
echo "ovejita.png reemplazada (recorte sin fondo)"

mkdir -p "$(dirname lib/screens/onboarding/onboarding_welcome_screen.dart)"
cat > lib/screens/onboarding/onboarding_welcome_screen.dart <<'EOF_LIB_SCREENS_ONBOARDING_ONBOARDING_WELCOME_SCREEN_DART'
import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';
import 'onboarding_name_screen.dart';

/// Bienvenida "WOW" 2026: fondo degradado profundo (como el logo), halo
/// de luz dorado que respira con una CRUZ LUMINOSA (restaurada en v11c),
/// y la ovejita — que eres tu (Juan 10:27) — asomandose desde la esquina
/// inferior derecha de la pantalla, mirando hacia la cruz.
///
/// v11c: se deshace el experimento de v11a de meter a la ovejita DENTRO
/// del halo (el recorte tenia fondo y se veia un rectangulo verde dentro
/// del circulo). La cruz vuelve a ser la protagonista del halo, como
/// estaba antes, y la mascota entra por la esquina con su recorte
/// transparente real (assets/mascot/ovejita_esperando.png, mirando hacia
/// arriba), sin tocar el resto de la composicion.
class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _entrance;

  static const _indigo = Color(0xFF18163A);
  static const _esmeralda = Color(0xFF0A3A30);
  static const _dorado = Color(0xFFFFD18C);
  static const _marfil = Color(0xFFF7F3EA);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..forward();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Widget _luz(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _dorado.withValues(alpha: opacity),
              blurRadius: size * 0.45,
              spreadRadius: size * 0.08,
            ),
          ],
        ),
      );

  /// Barra redondeada y luminosa (marfil→dorado) para armar la cruz de
  /// luz. [glow] varia con el pulso para que la cruz "respire" junto con
  /// el halo.
  Widget _barraDeLuz({
    required double width,
    required double height,
    required double glow,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_marfil, _dorado],
        ),
        boxShadow: [
          BoxShadow(
            color: _dorado.withValues(alpha: glow),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fadeIn = CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic));
    // La ovejita entra deslizandose desde la esquina, con la misma curva
    // de entrada del resto de la pantalla.
    final sheepIn = CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic));
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_indigo, _esmeralda],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    // Halo con cruz de luz que respira (como antes de v11a)
                    Center(
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final v = 0.92 + 0.08 * _pulse.value;
                          final glow = 0.55 + 0.25 * _pulse.value;
                          return Transform.scale(
                            scale: v,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _luz(210, 0.22 + 0.12 * _pulse.value),
                                Container(
                                  width: 190,
                                  height: 190,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: _marfil, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            _dorado.withValues(alpha: 0.55),
                                        blurRadius: 26,
                                      ),
                                    ],
                                  ),
                                ),
                                // Cruz de luz: brazo vertical + brazo
                                // horizontal un poco por encima del centro.
                                SizedBox(
                                  width: 160,
                                  height: 160,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      _barraDeLuz(
                                        width: 13,
                                        height: 96,
                                        glow: glow,
                                      ),
                                      Transform.translate(
                                        offset: const Offset(0, -16),
                                        child: _barraDeLuz(
                                          width: 64,
                                          height: 13,
                                          glow: glow,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    FadeTransition(
                      opacity: fadeIn,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tu momento\ncon Dios,\ntodos los días',
                            style: AppTypography.display
                                .copyWith(fontSize: 38, color: _marfil),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Esta ovejita eres tú: "Mis ovejas oyen mi voz, '
                            'y me siguen" (Juan 10:27). Oraciones que se '
                            'sienten tuyas, una pausa antes de las apps que '
                            'te roban la paz, y una fe que crece día a día 🌱',
                            style: AppTypography.bodyLarge.copyWith(
                                color: _marfil.withValues(alpha: 0.78)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    // El boton deja aire a la derecha para que la ovejita
                    // de la esquina no lo tape.
                    Padding(
                      padding: const EdgeInsets.only(right: 96),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dorado,
                            foregroundColor: const Color(0xFF241F10),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const OnboardingNameScreen()),
                            );
                          },
                          child: const Text('Comenzar mi camino 🙏'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 96),
                      child: Center(
                        child: Text(
                          'Gratis · Menos de 2 minutos',
                          style: AppTypography.caption.copyWith(
                              color: _marfil.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // La ovejita asoma desde la esquina inferior derecha de la
            // PANTALLA (recorte transparente, mirando hacia la cruz),
            // entrando con un deslizamiento suave.
            Positioned(
              right: -34,
              bottom: -26,
              child: AnimatedBuilder(
                animation: sheepIn,
                builder: (context, child) {
                  final t = sheepIn.value;
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(60 * (1 - t), 60 * (1 - t)),
                      child: child,
                    ),
                  );
                },
                child: Transform.rotate(
                  angle: -0.18,
                  child: Image.asset(
                    'assets/mascot/ovejita_esperando.png',
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
EOF_LIB_SCREENS_ONBOARDING_ONBOARDING_WELCOME_SCREEN_DART

mkdir -p "$(dirname lib/screens/onboarding/onboarding_progress_dots.dart)"
cat > lib/screens/onboarding/onboarding_progress_dots.dart <<'EOF_LIB_SCREENS_ONBOARDING_ONBOARDING_PROGRESS_DOTS_DART'
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Barra superior compartida por TODAS las pantallas del onboarding:
/// boton de volver + puntos de progreso. v11c: la ovejita (que eres tu,
/// Juan 10:27) CAMINA sobre los puntos y avanza contigo en cada paso —
/// asi la mascota acompana todo el onboarding de forma coherente con la
/// narrativa "tu caminar con el Pastor".
class OnboardingTopBar extends StatelessWidget implements PreferredSizeWidget {
  final int step; // 0-indexado
  final int totalSteps;
  final VoidCallback? onBack;

  const OnboardingTopBar({
    super.key,
    required this.step,
    this.totalSteps = 10,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    // Ancho fijo de la fila de puntos: (totalSteps) puntos de 7px con
    // 6px de margen + 13px extra del punto activo (que mide 20px).
    final dotsWidth = totalSteps * 13.0 + 13.0;
    final sheepX = totalSteps <= 1
        ? 0.0
        : -1.0 + 2.0 * (step.clamp(0, totalSteps - 1)) / (totalSteps - 1);

    return SizedBox(
      height: preferredSize.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _BackCircle(onTap: onBack ?? () => Navigator.of(context).maybePop()),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // La ovejita avanza hasta quedar sobre el punto activo.
                SizedBox(
                  width: dotsWidth,
                  height: 26,
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment(sheepX, 1),
                    child: Image.asset(
                      'assets/mascot/ovejita.png',
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(totalSteps, (i) {
                    final active = i == step;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active ? AppColors.tealDeep : AppColors.tealLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

class _BackCircle extends StatelessWidget {
  final VoidCallback onTap;
  const _BackCircle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tealLight.withOpacity(0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_rounded, color: AppColors.tealDeep, size: 20),
        ),
      ),
    );
  }
}
EOF_LIB_SCREENS_ONBOARDING_ONBOARDING_PROGRESS_DOTS_DART

mkdir -p "$(dirname lib/screens/prayer_detail/prayer_detail_screen.dart)"
cat > lib/screens/prayer_detail/prayer_detail_screen.dart <<'EOF_LIB_SCREENS_PRAYER_DETAIL_PRAYER_DETAIL_SCREEN_DART'
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
      final listo = await _voiceService.checkAvailability();
      if (!mounted) return;
      if (!listo) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('No pudimos iniciar el micrófono en este teléfono 😔'),
        ));
        return;
      }
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
                if (_listening)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 150),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        widget.prayer.texto,
                        style: AppTypography.prayerText.copyWith(
                          fontSize: 14.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  )
                else
                  _PrayerHeroCard(prayer: widget.prayer),
                SizedBox(height: _listening ? 14 : 28),
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
///
/// v11c (pedido de Maria): mientras se escucha, la ovejita esta en
/// GRANDE y AL CENTRO del panel, orando contigo — el halo dorado respira
/// detras de ella y el microfono queda como una insignia pequena a su
/// lado. Nada de esquinas: ella es la protagonista de este momento.
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18163A), Color(0xFF0A3A30)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 26, 18, 14),
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
                          // Halo dorado que respira DETRAS de la ovejita.
                          Container(
                            width: 126,
                            height: 126,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFFFFE7C2),
                                  Color(0xFFFFD18C),
                                  Color(0xFFE2A85B),
                                ],
                                stops: [0.0, 0.6, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD18C)
                                      .withValues(alpha: 0.45 + 0.3 * v),
                                  blurRadius: 34 + 18 * v,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          // La ovejita, grande y al centro, ora contigo.
                          Image.asset(
                            'assets/mascot/ovejita_escuchando.png',
                            height: 154,
                            fit: BoxFit.contain,
                          ),
                          // El microfono queda como insignia pequena.
                          Positioned(
                            bottom: 6,
                            right: 24,
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFD18C),
                              ),
                              child: const Icon(Icons.mic_rounded,
                                  size: 22, color: Color(0xFF241F10)),
                            ),
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
          ),
        ],
      ),
    );
  }
}
EOF_LIB_SCREENS_PRAYER_DETAIL_PRAYER_DETAIL_SCREEN_DART

mkdir -p "$(dirname lib/screens/journal/journal_screen.dart)"
cat > lib/screens/journal/journal_screen.dart <<'EOF_LIB_SCREENS_JOURNAL_JOURNAL_SCREEN_DART'
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/journal_entry.dart';
import '../../services/journal_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'journal_entry_editor_screen.dart';

/// Diario de oracion: lista de intenciones/peticiones escritas por el
/// usuario, agrupadas por fecha, con opcion de marcar como "Respondida".
/// v11c: la ovejita acompana el diario — en el estado vacio mira el libro
/// abierto contigo, y con entradas te saluda desde el encabezado.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late Future<Map<String, List<JournalEntry>>> _future;
  final _newEntryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _newEntryController.dispose();
    super.dispose();
  }

  void _reload() {
    _future = context.read<JournalRepository>().groupedByDate();
  }

  Future<void> _openNewEntrySheet() async {
    _newEntryController.clear();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nueva intención de oración', style: AppTypography.title),
              const SizedBox(height: 12),
              TextField(
                controller: _newEntryController,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Por ejemplo: "Por la salud de mi mamá..."',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final text = _newEntryController.text.trim();
                    if (text.isEmpty) return;
                    await context.read<JournalRepository>().add(text);
                    if (context.mounted) Navigator.of(context).pop(true);
                  },
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (saved == true) {
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diario de oración')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewEntrySheet,
        icon: const Icon(Icons.add),
        label: const Text('Nueva intención'),
      ),
      body: FutureBuilder<Map<String, List<JournalEntry>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final grouped = snapshot.data!;
          if (grouped.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Libro abierto + la ovejita mirandolo contigo (v11c).
                  SizedBox(
                    width: 220,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        SvgPicture.asset(
                          'assets/illustrations/journal_empty.svg',
                          width: 168,
                        ),
                        Positioned(
                          right: -6,
                          bottom: -8,
                          child: Image.asset(
                            'assets/mascot/ovejita_esperando.png',
                            height: 86,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Tu diario está en blanco, listo para tu primera intención',
                    textAlign: TextAlign.center,
                    style: AppTypography.title.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Todavía no has escrito ninguna intención de oración. '
                    'Toca "Nueva intención" para empezar tu diario.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(color: AppColors.inkSoft),
                  ),
                ],
              ),
            );
          }

          final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: dateKeys.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Encabezado con la ovejita (v11c): el diario tambien es
                // parte del caminar con el Pastor.
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/mascot/ovejita.png',
                        height: 34,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Él escucha cada una de tus intenciones 🌿',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.inkSoft),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final key = dateKeys[index - 1];
              final entries = grouped[key]!;
              final label =
                  DateFormat("d 'de' MMMM, y", 'es').format(entries.first.fecha);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      label,
                      style: AppTypography.caption.copyWith(color: AppColors.inkSoft),
                    ),
                  ),
                  ...entries.map((e) => _JournalTile(
                        entry: e,
                        onTap: () async {
                          final changed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => JournalEntryEditorScreen(entry: e),
                            ),
                          );
                          if (changed == true) setState(_reload);
                        },
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _JournalTile extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;

  const _JournalTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        title: Text(
          entry.texto,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body,
        ),
        trailing: entry.respondida
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : const Icon(Icons.hourglass_bottom, color: AppColors.inkSoft),
      ),
    );
  }
}
EOF_LIB_SCREENS_JOURNAL_JOURNAL_SCREEN_DART

mkdir -p "$(dirname lib/screens/settings/settings_screen.dart)"
cat > lib/screens/settings/settings_screen.dart <<'EOF_LIB_SCREENS_SETTINGS_SETTINGS_SCREEN_DART'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/prefs_service.dart';
import '../../services/purchase_service.dart';
import '../../services/voice_prayer_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../paywall/paywall_screen.dart';
import '../voice_explainer/voice_explainer_screen.dart';
import 'about_screen.dart';
import 'appearance_screen.dart';
import 'battery_optimization_screen.dart';
import 'categories_screen.dart';
import 'gated_apps_screen.dart';
import 'privacy_screen.dart';
import 'reminders_screen.dart';

/// Pantalla de Ajustes: punto de entrada a recordatorios, "Pausa y Ora",
/// intereses, plan Plus, privacidad y acerca de. v11c: la ovejita
/// acompana tambien esta pantalla desde el encabezado.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPlus = context.watch<PurchaseService>().isPlusUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/mascot/ovejita.png',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text('Ajustes'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SectionLabel('Tu experiencia'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Recordatorios diarios',
            subtitle: 'Elige hasta 3 horarios para recibir avisos',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RemindersScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.favorite_outline,
            title: 'Mis intereses',
            subtitle: 'Personaliza las categorías de tu inicio',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Apariencia',
            subtitle: 'Paleta de color y Modo Simple',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppearanceScreen()),
            ),
          ),
          const Divider(height: 32),
          _SectionLabel('Pausa y Ora'),
          _SettingsTile(
            icon: Icons.lock_clock_outlined,
            title: 'Apps con pausa de oración',
            subtitle: 'Elige qué apps requieren una pausa antes de abrirse',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GatedAppsScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.battery_saver_outlined,
            title: 'Optimización de batería',
            subtitle: 'Evita que Android silencie la Pausa y Ora',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BatteryOptimizationScreen()),
            ),
          ),
          const Divider(height: 32),
          _SectionLabel('Voz'),
          const _VoiceDetectionTile(),
          const Divider(height: 32),
          _SectionLabel('Tu cuenta'),
          _SettingsTile(
            icon: Icons.workspace_premium_outlined,
            title: isPlus ? 'Eres miembro Ora Ahora Plus' : 'Obtener Ora Ahora Plus',
            subtitle: isPlus
                ? 'Gracias por apoyar Ora Ahora'
                : 'Apps ilimitadas en Pausa y Ora, y más',
            iconColor: AppColors.amber,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
          ),
          const Divider(height: 32),
          _SectionLabel('Información'),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Política de privacidad',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Acerca de Ora Ahora',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: AppColors.inkSoft,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.tealDeep;
    return ListTile(
      // Icono dentro de un circulo tonal (en vez de un icono "suelto"),
      // para que cada fila de Ajustes se sienta como una fila consistente
      // de una app pulida, no una lista generica de texto.
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.caption.copyWith(color: AppColors.inkSoft),
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Interruptor (opt-in, apagado por defecto) de la deteccion automatica
/// de fin de oracion por voz (ver `VoicePrayerService`, `PrayerDetailScreen`
/// y `VoiceExplainerScreen`).
///
/// Comprueba la disponibilidad de reconocimiento de voz en este telefono
/// UNA sola vez al abrir Ajustes: si no hay reconocimiento disponible en
/// este dispositivo, el interruptor se muestra deshabilitado (gris) con
/// el subtitulo "No disponible en este dispositivo", sin dialogos de
/// error ni insistencia, tal como pide el diseño de la función.
class _VoiceDetectionTile extends StatefulWidget {
  const _VoiceDetectionTile();

  @override
  State<_VoiceDetectionTile> createState() => _VoiceDetectionTileState();
}

class _VoiceDetectionTileState extends State<_VoiceDetectionTile> {
  final VoicePrayerService _voiceService = VoicePrayerService();

  bool _checkingAvailability = true;
  bool _available = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _voiceService.checkAvailability();
    if (!mounted) return;
    setState(() {
      _available = available;
      _checkingAvailability = false;
    });
  }

  Future<void> _onChanged(bool value) async {
    final prefs = context.read<PrefsService>();

    if (!value) {
      await prefs.setVoiceDetectionEnabled(false);
      setState(() {});
      return;
    }

    if (!_available) return; // el interruptor deberia estar deshabilitado

    if (!prefs.voiceDisclosureSeen) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const VoiceExplainerScreen()),
      );
      if (result != true) return;
    } else {
      // Ya se vio el aviso antes, pero el permiso de microfono pudo
      // haberse revocado manualmente desde los ajustes del sistema desde
      // entonces: se vuelve a comprobar sin mostrar la pantalla de aviso
      // de nuevo (ya se explico una vez), y simplemente no se activa el
      // interruptor si ya no esta disponible.
      final granted = await _voiceService.checkAvailability();
      if (!granted) return;
    }

    await prefs.setVoiceDetectionEnabled(true);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PrefsService>();
    final enabled = prefs.voiceDetectionEnabled;

    final voiceColor = _available ? AppColors.tealDeep : AppColors.inkSoft;
    return SwitchListTile(
      secondary: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: voiceColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.mic_none, color: voiceColor, size: 20),
      ),
      value: enabled && _available,
      onChanged: _checkingAvailability || !_available ? null : _onChanged,
      title: const Text('Detectar cuando termino de orar (con micrófono)'),
      subtitle: Text(
        _checkingAvailability
            ? 'Comprobando disponibilidad...'
            : _available
                ? 'Opcional. Escucha en tu propio teléfono para confirmar tu '
                    'oración; nunca se envía a un servidor.'
                : 'No disponible en este dispositivo',
      ),
    );
  }
}
EOF_LIB_SCREENS_SETTINGS_SETTINGS_SCREEN_DART

# --- Verificacion estatica ---
python3 - <<'EOF_CHECK'
import os, sys
ok = True
for f in ['lib/screens/onboarding/onboarding_welcome_screen.dart', 'lib/screens/onboarding/onboarding_progress_dots.dart', 'lib/screens/prayer_detail/prayer_detail_screen.dart', 'lib/screens/journal/journal_screen.dart', 'lib/screens/settings/settings_screen.dart']:
    low = open(f, encoding='utf-8').read().lower()
    for p in ['la paz sea contigo', 'rosario', 'avemaria', 'ave maria']:
        if p in low:
            print(f'{f}: FRASE PROHIBIDA: {p}'); ok = False
p = 'assets/mascot/ovejita.png'
if not os.path.exists(p) or os.path.getsize(p) < 1000:
    print(f'FALTA O VACIA: {p}'); ok = False
if not ok:
    sys.exit(1)
print('Verificacion estatica: OK')
EOF_CHECK

echo ""
echo "apply_v11c.sh aplicado: la ovejita acompana toda la app."
echo "Siguiente: flutter analyze && flutter build apk --debug"
