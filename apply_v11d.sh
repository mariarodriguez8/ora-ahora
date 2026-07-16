#!/usr/bin/env bash
# apply_v11d.sh — ORA AHORA v11d: feedback de prueba de Maria (16-jul).
#  - Ajustes > Mis intereses: emojis por categoria (mismos del onboarding).
#  - Onboarding: ovejita COMPLETA (nunca recortada) en la esquina superior,
#    alternando lado y pose por pantalla (pensativa con "?" al pedir el
#    nombre, orando antes de la primera oracion, celebrando en el pacto...).
#  - Bienvenida: mascota OFICIAL completa (no la variante) + copy mas claro
#    de que hace la app, en lenguaje simple.
#  - Voz: ovejita completa orando al centro; confirmacion al 90% de la
#    oracion (antes 55%); con "amen" requiere 75% (antes 30%); boton
#    "Continuar" al terminar (ya no hay que usar atras).
#  - Inicio: tarjeta-guia "Tu paso de hoy".
#  - version 1.0.1+2 (listo para subir como actualizacion a Play).
#  - Limpieza: .aab y zips fuera de git.
set -euo pipefail
cd "$(dirname "$0")"
if [ ! -f pubspec.yaml ]; then
  echo "ERROR: ejecuta este script desde la raiz del repo" >&2
  exit 1
fi

mkdir -p assets/mascot
dl() { if [ ! -s "$2" ]; then wget -q "$1" -O "$2"; echo "descargado: $2"; else echo "ya existe: $2"; fi; }
dl "https://d8j0ntlcm91z4.cloudfront.net/user_357fcxDIqY9TMqfewNOAYaGunxR/hf_20260716_163401_3758706d-d244-40bf-a5d7-100129837074.png" "assets/mascot/ovejita_pensativa.png"
dl "https://d8j0ntlcm91z4.cloudfront.net/user_357fcxDIqY9TMqfewNOAYaGunxR/hf_20260716_163447_9040cd32-871f-45a8-9d39-230308dc90e1.png" "assets/mascot/ovejita_orando.png"

# Limpieza de binarios que se colaron a git
grep -q "ora-ahora-release.aab" .gitignore 2>/dev/null || printf "\n# binarios de entrega\n*.aab\nficha_play.zip\nora-ahora.apk.zip\n" >> .gitignore
git rm --cached ora-ahora-release.aab ficha_play.zip 2>/dev/null || true

mkdir -p "$(dirname pubspec.yaml)"
cat > pubspec.yaml <<'EOF_PUBSPEC_YAML'
name: ora_ahora
description: "Ora Ahora - pausa, ora y enfoca. App de oracion cristiana interdenominacional en espanol con pausa de oracion antes de abrir apps que distraen."
publish_to: 'none'
version: 1.0.1+2

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2
  shared_preferences: ^2.2.3
  flutter_local_notifications: ^17.2.2
  timezone: ^0.9.4
  flutter_timezone: ^5.1.0
  path_provider: ^2.1.4
  intl: ^0.20.2
  device_apps: ^2.2.0
  uuid: ^4.4.0
  speech_to_text: ^7.0.0
  flutter_svg: ^2.0.10+1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/data/prayers_es.json
    # v11b: carpeta completa de la mascota (ovejita.png + expresiones
    # celebrando / esperando / escuchando / perdida, derivadas del
    # personaje oficial).
    - assets/mascot/
    - assets/illustrations/onboarding_hero.svg
    - assets/illustrations/tree_semilla.svg
    - assets/illustrations/tree_brote.svg
    - assets/illustrations/tree_planta_joven.svg
    - assets/illustrations/tree_arbol.svg
    - assets/illustrations/journal_empty.svg
    - assets/illustrations/paywall_hero.svg

  fonts:
    - family: Fraunces
      fonts:
        - asset: assets/fonts/Fraunces9pt-Regular.ttf
          weight: 400
        - asset: assets/fonts/Fraunces9pt-Italic.ttf
          weight: 400
          style: italic
        - asset: assets/fonts/Fraunces72ptSoft-SemiBold.ttf
          weight: 600
    - family: Figtree
      fonts:
        - asset: assets/fonts/Figtree-Regular.ttf
          weight: 400
        - asset: assets/fonts/Figtree-Medium.ttf
          weight: 500
        - asset: assets/fonts/Figtree-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Figtree-Bold.ttf
          weight: 700
        - asset: assets/fonts/Figtree-ExtraBold.ttf
          weight: 800
EOF_PUBSPEC_YAML

mkdir -p "$(dirname lib/models/prayer.dart)"
cat > lib/models/prayer.dart <<'EOF_LIB_MODELS_PRAYER_DART'
/// Representa una oracion / devocional corto del catalogo local de Ora Ahora.
///
/// Las categorias usan claves internas en ASCII (sin tildes) para que el
/// filtrado sea identico y sin ambiguedad tanto en Dart como en el codigo
/// nativo Kotlin (ver [PrayerCategories]). Los textos que se muestran al
/// usuario si usan tildes y enye normales en espanol.
class Prayer {
  final String id;
  final String categoria;
  final String titulo;
  final String texto;
  final String referenciaBiblica;
  final int duracionEstimadaMin;

  const Prayer({
    required this.id,
    required this.categoria,
    required this.titulo,
    required this.texto,
    required this.referenciaBiblica,
    required this.duracionEstimadaMin,
  });

  factory Prayer.fromJson(Map<String, dynamic> json) {
    return Prayer(
      id: json['id'] as String,
      categoria: json['categoria'] as String,
      titulo: json['titulo'] as String,
      texto: json['texto'] as String,
      referenciaBiblica: json['referencia_biblica'] as String,
      duracionEstimadaMin: (json['duracion_estimada_min'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoria': categoria,
      'titulo': titulo,
      'texto': texto,
      'referencia_biblica': referenciaBiblica,
      'duracion_estimada_min': duracionEstimadaMin,
    };
  }
}

/// Claves de categoria (ASCII, estables) usadas en todo el proyecto
/// (JSON de datos, preferencias de onboarding, filtro nativo del gate).
class PrayerCategories {
  static const manana = 'manana';
  static const noche = 'noche';
  static const ansiedad = 'ansiedad';
  static const gratitud = 'gratitud';
  static const familia = 'familia';
  static const trabajo = 'trabajo';
  static const tentacionEnfoque = 'tentacion_enfoque';
  static const sanidad = 'sanidad';
  static const perdon = 'perdon';
  static const duelo = 'duelo';
  static const soledad = 'soledad';
  static const matrimonio = 'matrimonio';
  static const finanzas = 'finanzas';
  static const paz = 'paz';

  static const List<String> all = [
    manana,
    noche,
    ansiedad,
    gratitud,
    familia,
    trabajo,
    tentacionEnfoque,
    sanidad,
    perdon,
    duelo,
    soledad,
    matrimonio,
    finanzas,
    paz,
  ];

  /// Nombre legible en espanol para mostrar en la interfaz.
  static String displayName(String categoria) {
    switch (categoria) {
      case manana:
        return 'Mañana';
      case noche:
        return 'Noche';
      case ansiedad:
        return 'Ansiedad';
      case gratitud:
        return 'Gratitud';
      case familia:
        return 'Familia';
      case trabajo:
        return 'Trabajo';
      case tentacionEnfoque:
        return 'Tentación y enfoque';
      case sanidad:
        return 'Sanidad';
      case perdon:
        return 'Perdón';
      case duelo:
        return 'Duelo';
      case soledad:
        return 'Soledad';
      case matrimonio:
        return 'Matrimonio y pareja';
      case finanzas:
        return 'Finanzas y provisión';
      case paz:
        return 'Paz interior';
      default:
        return categoria;
    }
  }

  /// Emoji de cada categoria (v11d): los MISMOS que usa el onboarding,
  /// para que toda la app hable igual (Ajustes > Mis intereses incluido).
  static String emojiFor(String categoria) {
    switch (categoria) {
      case manana:
        return '🌅';
      case noche:
        return '😴';
      case ansiedad:
        return '😟';
      case gratitud:
        return '🙌';
      case familia:
        return '👨‍👩‍👧';
      case trabajo:
        return '💼';
      case tentacionEnfoque:
        return '📵';
      case sanidad:
        return '🌿';
      case perdon:
        return '🤝';
      case duelo:
        return '🕯️';
      case soledad:
        return '🫂';
      case matrimonio:
        return '💛';
      case finanzas:
        return '🪙';
      case paz:
        return '🕊️';
      default:
        return '🙏';
    }
  }
}
EOF_LIB_MODELS_PRAYER_DART

mkdir -p "$(dirname lib/widgets/category_chip.dart)"
cat > lib/widgets/category_chip.dart <<'EOF_LIB_WIDGETS_CATEGORY_CHIP_DART'
import 'package:flutter/material.dart';

import '../models/prayer.dart';

/// Chip seleccionable para elegir categorias (onboarding y ajustes).
/// v11d: muestra el emoji de cada categoria (los mismos del onboarding),
/// para que "Mis intereses" en Ajustes se sienta igual de calido.
class CategoryChip extends StatelessWidget {
  final String categoria;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const CategoryChip({
    super.key,
    required this.categoria,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        '${PrayerCategories.emojiFor(categoria)} '
        '${PrayerCategories.displayName(categoria)}',
      ),
      selected: selected,
      onSelected: onChanged,
      showCheckmark: false,
    );
  }
}
EOF_LIB_WIDGETS_CATEGORY_CHIP_DART

mkdir -p "$(dirname lib/screens/onboarding/onboarding_progress_dots.dart)"
cat > lib/screens/onboarding/onboarding_progress_dots.dart <<'EOF_LIB_SCREENS_ONBOARDING_ONBOARDING_PROGRESS_DOTS_DART'
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Barra superior compartida por TODAS las pantallas del onboarding:
/// boton de volver + puntos de progreso + la ovejita.
///
/// v11d (pedido de Maria): la ovejita aparece COMPLETA (nunca recortada)
/// en la esquina superior, alternando lado y POSE segun la pantalla —
/// pensativa con signo de interrogacion cuando se pregunta el nombre,
/// orando antes de la primera oracion, celebrando en el pacto, etc.
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
  Size get preferredSize => const Size.fromHeight(76);

  /// Pose de la ovejita y lado (true = derecha) por paso del onboarding.
  /// 0 nombre · 1 temas · 2 horarios · 3 plan · 4 testimonio ·
  /// 5 primera oracion · 6 pacto · 7 recordatorios · 8 permisos · 9 final
  static (String, bool) _poseFor(int step) {
    switch (step) {
      case 0:
        return ('assets/mascot/ovejita_pensativa.png', true);
      case 1:
        return ('assets/mascot/ovejita_esperando.png', false);
      case 2:
        return ('assets/mascot/ovejita.png', true);
      case 3:
        return ('assets/mascot/ovejita_pensativa.png', false);
      case 4:
        return ('assets/mascot/ovejita_celebrando.png', true);
      case 5:
        return ('assets/mascot/ovejita_orando.png', false);
      case 6:
        return ('assets/mascot/ovejita_celebrando.png', true);
      case 7:
        return ('assets/mascot/ovejita_esperando.png', false);
      case 8:
        return ('assets/mascot/ovejita.png', true);
      default:
        return ('assets/mascot/ovejita_celebrando.png', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (asset, right) = _poseFor(step);

    // La ovejita entra con un pequeno "pop" suave, completa y visible.
    final sheep = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Image.asset(
        asset,
        height: 56,
        fit: BoxFit.contain,
      ),
    );

    return SizedBox(
      height: preferredSize.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _BackCircle(onTap: onBack ?? () => Navigator.of(context).maybePop()),
            if (!right) ...[const SizedBox(width: 10), sheep],
            const Spacer(),
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
            const Spacer(),
            if (right)
              sheep
            else
              const SizedBox(width: 56),
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
                            'Una oración corta cada día, a tu hora. Y una '
                            'pausa para orar antes de abrir las apps que '
                            'más te distraen. La ovejita eres tú: "Mis '
                            'ovejas oyen mi voz, y me siguen" (Juan 10:27).',
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
              right: 16,
              bottom: 10,
              child: AnimatedBuilder(
                animation: sheepIn,
                builder: (context, child) {
                  final t = sheepIn.value;
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(40 * (1 - t), 0),
                      child: child,
                    ),
                  );
                },
                // v11d: la mascota OFICIAL, completa y sin recortar.
                child: Image.asset(
                  'assets/mascot/ovejita.png',
                  height: 124,
                  fit: BoxFit.contain,
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
  /// v11d (pedido de Maria): 90% — antes se confirmaba a mitad de la
  /// oracion, ahora hay que decirla casi completa.
  static const double _coverageToConfirm = 0.90;

  /// Si la persona cierra con "amen", basta con esta cobertura.
  static const double _coverageWithAmen = 0.75;

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
                // v11d: al terminar (por voz o manual) aparece un boton
                // claro para continuar, sin tener que usar "atras".
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
                          // La ovejita COMPLETA (no cortada), grande y
                          // al centro, orando contigo (v11d).
                          Image.asset(
                            'assets/mascot/ovejita_orando.png',
                            height: 158,
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

mkdir -p "$(dirname lib/screens/home/home_screen.dart)"
cat > lib/screens/home/home_screen.dart <<'EOF_LIB_SCREENS_HOME_HOME_SCREEN_DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../services/community_stats_service.dart';
import '../../services/prayer_repository.dart';
import '../../services/prefs_service.dart';
import '../../services/purchase_service.dart';
import '../../services/route_observer.dart';
import '../../services/streak_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/meadow_hero.dart';
import '../../widgets/prayer_card.dart';
import '../journal/journal_screen.dart';
import '../paywall/paywall_screen.dart';
import '../prayer_detail/prayer_detail_screen.dart';
import '../settings/settings_screen.dart';

/// Contenedor principal de la app despues del onboarding: pestañas de
/// Inicio, Diario y Ajustes con una barra de navegacion inferior.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // El paywall se muestra UNA sola vez, justo despues de terminar el
    // onboarding (el momento "aha" del usuario): ver
    // `PrefsService.paywallShownAfterOnboarding`. Es un paywall "suave":
    // se puede cerrar libremente (boton atras del AppBar) y no vuelve a
    // aparecer automaticamente ni bloquea ninguna funcion gratuita.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboardingPaywall());
  }

  Future<void> _maybeShowOnboardingPaywall() async {
    final prefs = context.read<PrefsService>();
    if (prefs.paywallShownAfterOnboarding) return;
    await prefs.setPaywallShownAfterOnboarding(true);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      _HomeFeedTab(),
      JournalScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Diario',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

class _HomeFeedTab extends StatefulWidget {
  const _HomeFeedTab();

  @override
  State<_HomeFeedTab> createState() => _HomeFeedTabState();
}

/// `SingleTickerProviderStateMixin` se agrega unicamente para poder animar
/// la entrada escalonada ("staggered") de las secciones del inicio la
/// primera vez que se construyen (ver `_entranceController`/
/// `_staggeredSection`), con una curva organica en vez del aparecer seco
/// de antes.
class _HomeFeedTabState extends State<_HomeFeedTab>
    with RouteAware, SingleTickerProviderStateMixin {
  late Future<_FeedData> _future;
  PageRoute<dynamic>? _subscribedRoute;
  int? _celebratingMilestone;

  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entranceController.forward();
    // Se aprovecha para refrescar el cupo mensual de fichas de
    // congelación (solo aplica si el usuario es Plus), asi la pradera
    // muestra el conteo correcto sin que el usuario tenga que orar
    // primero.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isPlus = context.read<PurchaseService>().isPlusUser;
      context.read<StreakService>().refreshFreezeTokens(isPlusUser: isPlus);
      // Cubre el caso (poco comun) de que ya hubiera un hito pendiente de
      // celebrar apenas se construye esta pantalla por primera vez.
      _maybeCelebrateMilestone();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se suscribe al `RouteObserver` compartido para detectar cuando el
    // usuario *vuelve* a esta pantalla (p. ej. al cerrar
    // `PrayerDetailScreen` despues de marcar una oracion como orada), que
    // es el momento correcto para mostrar la celebracion de hito de racha
    // (ver `didPopNext`).
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _subscribedRoute) {
      if (_subscribedRoute != null) {
        appRouteObserver.unsubscribe(this);
      }
      appRouteObserver.subscribe(this, route);
      _subscribedRoute = route;
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _entranceController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Se volvio a esta pantalla desde otra que se acaba de cerrar (ver
    // `PrayerDetailScreen`): buen momento para mostrar una celebracion de
    // hito si `markPrayedToday` dejo una pendiente.
    _maybeCelebrateMilestone();
  }

  void _maybeCelebrateMilestone() {
    if (!mounted) return;
    final streak = context.read<StreakService>();
    final milestone = streak.pendingMilestone;
    if (milestone == null) return;
    streak.acknowledgeMilestoneShown();
    HapticFeedback.mediumImpact();
    setState(() => _celebratingMilestone = milestone);
  }

  Future<_FeedData> _load() async {
    final repo = context.read<PrayerRepository>();
    final prefs = context.read<PrefsService>();
    final categories = prefs.preferredCategories;
    final oracionDelDia = await repo.prayerOfTheDay(
      preferredCategories: categories,
    );
    final feed = await repo.byCategories(categories);
    feed.removeWhere((p) => p.id == oracionDelDia.id);
    // Coherencia: primero las oraciones del primer tema elegido, luego el
    // segundo, etc.
    feed.sort((a, b) => categories
        .indexOf(a.categoria)
        .compareTo(categories.indexOf(b.categoria)));

    // Prueba social honesta (ver `CommunityStatsService`): hoy siempre
    // devuelve `null` porque no existe un backend real que agregue
    // usuarios activos, asi que el widget de inicio cae de forma segura al
    // copy no cuantificado. Queda listo para mostrar un numero en vivo el
    // dia que se conecte un backend real, sin volver a tocar esta pantalla.
    const communityStats = StubCommunityStatsService();
    final prayingNowEstimate = await communityStats.getPrayingNowEstimate();

    return _FeedData(
      oracionDelDia: oracionDelDia,
      feed: feed,
      prayingNowEstimate: prayingNowEstimate,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  /// Envuelve [child] en una entrada escalonada de fundido+desplazamiento:
  /// el fundido usa una curva suave sin overshoot (`Curves.easeOutCubic`,
  /// segura para valores de opacidad entre 0.0 y 1.0), mientras que el
  /// desplazamiento vertical usa una curva organica con "rebote"
  /// (`Curves.easeOutBack`, segura para un `Offset` aunque exceda
  /// momentaneamente el rango 0..1). [start]/[end] ubican el tramo de
  /// [_entranceController] (0.0 a 1.0) que le corresponde a esta seccion,
  /// para que las secciones aparezcan una tras otra en vez de todas a la
  /// vez.
  Widget _staggeredSection(
    Widget child, {
    required double start,
    required double end,
  }) {
    final fade = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    ));
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakService>();
    final isPlus = context.watch<PurchaseService>().isPlusUser;

    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<_FeedData>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    // 0. Encabezado calido: saludo segun la hora del dia,
                    // ahora mas liviano (la racha y el arbol viven en la
                    // pradera de abajo, no aqui).
                    _staggeredSection(
                      SafeArea(
                        bottom: false,
                        child: _GreetingHeader(
                          nombre: context.read<PrefsService>().userName,
                        ),
                      ),
                      start: 0.0,
                      end: 0.45,
                    ),
                    const SizedBox(height: 16),
                    // 1. HERO v11: la pradera del Salmo 23 — numero
                    // gigante de racha ("dias caminando con el Pastor"),
                    // anillo de minutos del dia, arbol de fe, arroyo,
                    // flores que crecen con los minutos orados y la
                    // ovejita (que eres tu).
                    _staggeredSection(
                      MeadowHero(
                        streak: streak.currentStreak,
                        atRisk: streak.streakAtRisk,
                        prayedToday: streak.prayedToday,
                        minutesToday: streak.minutesToday,
                        cumulativeMinutes: streak.cumulativeMinutes,
                        sheepLost: (streak.daysSinceLastPrayed ?? 0) >= 2,
                        freezeTokens: (isPlus && streak.freezeTokens > 0)
                            ? streak.freezeTokens
                            : null,
                      ),
                      start: 0.05,
                      end: 0.6,
                    ),
                    const SizedBox(height: 14),
                    // 1b. v11d: guia clara de que hacer hoy (pedido de
                    // Maria: "no queda claro que tengo que hacer").
                    _staggeredSection(
                      _NextStepCard(
                        prayedToday: streak.prayedToday,
                        onOrar: () => _openDetail(data.oracionDelDia),
                      ),
                      start: 0.1,
                      end: 0.65,
                    ),
                    const SizedBox(height: 24),
                    // 2. La oracion del dia, ahora segunda en jerarquia
                    // visual despues de la pradera (sigue siendo la
                    // accion principal del dia).
                    _staggeredSection(
                      _HeroPrayerSection(
                        prayer: data.oracionDelDia,
                        onTap: () => _openDetail(data.oracionDelDia),
                      ),
                      start: 0.15,
                      end: 0.75,
                    ),
                    const SizedBox(height: 16),
                    // 3. Prueba social honesta.
                    _staggeredSection(
                      _SocialProofBanner(
                        prayingNowEstimate: data.prayingNowEstimate,
                      ),
                      start: 0.3,
                      end: 0.85,
                    ),
                    const SizedBox(height: 28),
                    // 4. Feed personalizado + banner Plus.
                    _staggeredSection(
                      _ParaTiSection(
                        feed: data.feed,
                        isPlus: isPlus,
                        onOpenPrayer: _openDetail,
                        onOpenPaywall: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PaywallScreen()),
                          );
                        },
                      ),
                      start: 0.4,
                      end: 1.0,
                    ),
                  ],
                ),
              );
            },
          ),
          if (_celebratingMilestone != null)
            _MilestoneCelebrationOverlay(
              milestone: _celebratingMilestone!,
              onDismiss: () => setState(() => _celebratingMilestone = null),
            ),
        ],
      ),
    );
  }

  void _openDetail(Prayer prayer) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PrayerDetailScreen(prayer: prayer)),
    );
  }
}

/// Tarjeta-guia del dia (v11d): le dice a la persona exactamente cual es
/// su siguiente paso. Si aun no oro hoy, invita a la oracion del dia (y
/// tocarla la abre); si ya oro, sugiere el diario o el feed, sin presion.
class _NextStepCard extends StatelessWidget {
  final bool prayedToday;
  final VoidCallback onOrar;

  const _NextStepCard({required this.prayedToday, required this.onOrar});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: prayedToday ? null : onOrar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Text(
                prayedToday ? '✨' : '👉',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  prayedToday
                      ? 'Ya oraste hoy. Si quieres más, escribe una '
                          'intención en tu Diario o explora "Para ti".'
                      : 'Tu paso de hoy: ora la oración del día. '
                          'Toma 2 minutos — toca aquí.',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (!prayedToday)
                Icon(Icons.chevron_right, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado calido del inicio: avatar de la ovejita, fecha en español y
/// saludo serif segun la hora del dia. Desde v11 es deliberadamente
/// liviano: la racha, el arbol y los minutos viven en la pradera
/// (`MeadowHero`), no aqui.
class _GreetingHeader extends StatelessWidget {
  final String nombre;

  const _GreetingHeader({required this.nombre});

  String get _saludo {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hoy = DateTime.now();
    const dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final fecha =
        '${dias[hoy.weekday - 1]}, ${hoy.day} de ${meses[hoy.month - 1]}';

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ClipOval(
              child: Container(
                width: 48,
                height: 48,
                color: scheme.primaryContainer,
                padding: const EdgeInsets.all(5),
                child: Image.asset(
                  'assets/mascot/ovejita.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fecha.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nombre.isEmpty ? _saludo : '$_saludo, $nombre 🌅',
                  style: AppTypography.display.copyWith(
                    fontSize: 24,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Seccion de la oracion del dia: overline dorada + titulo serif + la
/// tarjeta destacada (fondo primario profundo, ver
/// `PrayerCard(destacada: true)`).
class _HeroPrayerSection extends StatelessWidget {
  final Prayer prayer;
  final VoidCallback onTap;

  const _HeroPrayerSection({required this.prayer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 2,
              color: scheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'PARA HOY',
              style: AppTypography.caption.copyWith(color: scheme.secondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Oración del día',
          style: AppTypography.headline.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 14),
        PrayerCard(prayer: prayer, destacada: true, onTap: onTap),
      ],
    );
  }
}

/// Feed personalizado ("Para ti") y banner de Plus: tercer nivel de
/// jerarquia, debajo de la pradera y de la oracion del dia.
class _ParaTiSection extends StatelessWidget {
  final List<Prayer> feed;
  final bool isPlus;
  final ValueChanged<Prayer> onOpenPrayer;
  final VoidCallback onOpenPaywall;

  const _ParaTiSection({
    required this.feed,
    required this.isPlus,
    required this.onOpenPrayer,
    required this.onOpenPaywall,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Para ti', style: AppTypography.headline),
        const SizedBox(height: 4),
        Text(
          'Según los temas que elegiste en tu perfil.',
          style: AppTypography.body.copyWith(color: AppColors.inkSoft),
        ),
        const SizedBox(height: 12),
        if (feed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Aún no elegiste temas de interés. Ve a Ajustes > '
              'Mis intereses para personalizar tu inicio.',
              style: AppTypography.body.copyWith(color: AppColors.inkSoft),
            ),
          )
        else
          ...List.generate(feed.length, (i) {
            final p = feed[i];
            final bloqueada = !isPlus && i >= 2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PrayerCard(
                prayer: p,
                bloqueada: bloqueada,
                insignia: (!isPlus && i == 1) ? '🎙️ Órala en voz alta' : null,
                onTap: bloqueada ? onOpenPaywall : () => onOpenPrayer(p),
              ),
            );
          }),
        const SizedBox(height: 12),
        if (!isPlus) _PlusBanner(onTap: onOpenPaywall),
      ],
    );
  }
}

/// Banner de "prueba social" honesta en el inicio: si [prayingNowEstimate]
/// es `null` (todavia no hay backend real que agregue usuarios activos, ver
/// `CommunityStatsService`), muestra un copy generico y verdadero en vez de
/// inventar un numero (evita el patron oscuro de prueba social falsa).
class _SocialProofBanner extends StatelessWidget {
  final int? prayingNowEstimate;

  const _SocialProofBanner({required this.prayingNowEstimate});

  @override
  Widget build(BuildContext context) {
    final estimate = prayingNowEstimate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.tealLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_outlined, size: 18, color: AppColors.tealDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              estimate != null
                  ? '$estimate personas orando en este momento'
                  : 'Cada día, muchas personas usan Ora Ahora para hacer una '
                      'pausa y orar.',
              style: AppTypography.caption.copyWith(color: AppColors.tealDeep),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlusBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _PlusBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.amberLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium, color: AppColors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Conoce Ora Ahora Plus', style: AppTypography.title),
                  Text(
                    'Apps ilimitadas en Pausa y Ora, fichas de congelación y más.',
                    style: AppTypography.caption.copyWith(color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _FeedData {
  final Prayer oracionDelDia;
  final List<Prayer> feed;
  final int? prayingNowEstimate;

  const _FeedData({
    required this.oracionDelDia,
    required this.feed,
    required this.prayingNowEstimate,
  });
}

/// Overlay breve mostrado al alcanzar un nuevo hito de racha (ver
/// `StreakService.milestones`/`pendingMilestone`). Se descarta al tocar en
/// cualquier parte de la pantalla. Entra con una animacion organica
/// de "rebote" (`Curves.elasticOut` en la escala) en vez de aparecer sin
/// transicion.
class _MilestoneCelebrationOverlay extends StatefulWidget {
  final int milestone;
  final VoidCallback onDismiss;

  const _MilestoneCelebrationOverlay({
    required this.milestone,
    required this.onDismiss,
  });

  @override
  State<_MilestoneCelebrationOverlay> createState() =>
      _MilestoneCelebrationOverlayState();
}

class _MilestoneCelebrationOverlayState
    extends State<_MilestoneCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // La escala usa `elasticOut` (rebote organico) para que la celebracion
    // se sienta como un pequeño festejo, no como un dialogo mas.
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    // El fundido del velo oscuro usa una curva sin rebote, y solo ocupa el
    // primer 40% de la duracion (aparece rapido, luego el rebote de la
    // tarjeta sigue un poco mas).
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: FadeTransition(
          opacity: _fade,
          child: Container(
            color: Colors.black54,
            alignment: Alignment.center,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // v11b: la ovejita celebra el hito contigo (antes era
                    // un icono generico de Material).
                    Image.asset(
                      'assets/mascot/ovejita_celebrando.png',
                      height: 96,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      StreakService.milestoneMessage(widget.milestone),
                      textAlign: TextAlign.center,
                      style: AppTypography.title,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: widget.onDismiss,
                      child: const Text('¡Gracias, Dios!'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
EOF_LIB_SCREENS_HOME_HOME_SCREEN_DART

# --- Verificacion estatica ---
python3 - <<'EOF_CHECK'
import os, sys
ok = True
for f in ['lib/models/prayer.dart', 'lib/widgets/category_chip.dart', 'lib/screens/onboarding/onboarding_progress_dots.dart', 'lib/screens/onboarding/onboarding_welcome_screen.dart', 'lib/screens/prayer_detail/prayer_detail_screen.dart', 'lib/screens/home/home_screen.dart']:
    low = open(f, encoding='utf-8').read().lower()
    for p in ['la paz sea contigo', 'rosario', 'avemaria', 'ave maria']:
        if p in low:
            print(f'{f}: FRASE PROHIBIDA: {p}'); ok = False
for n in ['ovejita_pensativa', 'ovejita_orando']:
    p = f'assets/mascot/{n}.png'
    if not os.path.exists(p) or os.path.getsize(p) < 1000:
        print(f'FALTA O VACIA: {p}'); ok = False
v = open('pubspec.yaml').read()
if 'version: 1.0.1+2' not in v:
    print('VERSION NO ACTUALIZADA'); ok = False
if not ok:
    sys.exit(1)
print('Verificacion estatica: OK')
EOF_CHECK

echo ""
echo "apply_v11d.sh aplicado (version 1.0.1+2)."
echo "Siguiente: flutter analyze && flutter build apk --debug (y appbundle --release para Play)"
