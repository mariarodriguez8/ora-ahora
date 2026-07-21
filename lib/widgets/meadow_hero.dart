import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_typography.dart';
import 'faith_tree_widget.dart';

/// v11 — "Tu caminar con el Pastor".
///
/// Hero del inicio: la pradera del Salmo 23 pintada a mano (cielo de
/// amanecer, colinas, arroyo y flores que van floreciendo con los minutos
/// orados), con el numero GIGANTE de racha como protagonista y el anillo
/// de minutos del dia. El arbol de fe vive dentro de la pradera (misma
/// logica de etapas de siempre, ver `FaithTreeStages`) y la ovejita — que
/// eres tu (Juan 10:27), siempre feliz — camina junto al arroyo.
///
/// Estilo "Santuario energizado": TODOS los colores derivan del
/// `ColorScheme` activo, asi la pradera se ve coherente en las 4 paletas
/// (incluida "Vigilia" oscura, donde el amanecer es mas tenue). No se
/// agrega ningun asset nuevo: la escena es un `CustomPainter` + los SVG
/// del arbol y el PNG de la mascota que ya existen.
class MeadowHero extends StatelessWidget {
  final int streak;
  final bool atRisk;
  final bool prayedToday;
  final int minutesToday;
  final int cumulativeMinutes;

  /// `true` cuando pasaron 2+ dias sin orar (la "oveja perdida" de
  /// Lucas 15): la pradera recibe con gracia, nunca con culpa.
  final bool sheepLost;

  /// Fichas de congelacion visibles (solo usuarios Plus con fichas > 0),
  /// o `null` para no mostrar nada.
  final int? freezeTokens;

  const MeadowHero({
    super.key,
    required this.streak,
    required this.atRisk,
    required this.prayedToday,
    required this.minutesToday,
    required this.cumulativeMinutes,
    this.sheepLost = false,
    this.freezeTokens,
  });

  /// Meta suave de minutos diarios para el anillo. No es un castigo: al
  /// llegar, el anillo simplemente se completa; nunca se muestra en rojo
  /// ni genera culpa (racha rota = oveja perdida que se celebra al volver,
  /// nunca se regana).
  static const int dailyGoalMinutes = 10;

  String get _statusMessage {
    if (prayedToday) return 'Hoy ya caminaste con Él ✨';
    if (sheepLost) return 'Él deja las 99 y viene por ti 💛';
    if (atRisk && streak > 0) return 'El Pastor te espera hoy 🌿';
    return '«En verdes pastos me hace descansar»';
  }

  /// Expresion de la ovejita segun el momento: celebrando si ya oro,
  /// "oveja perdida" (mirando hacia atras, esperanzada) si pasaron 2+
  /// dias, esperando si la racha esta en riesgo, y caminando feliz el
  /// resto del tiempo. Todas derivan del personaje oficial.
  String get _mascotAsset {
    if (prayedToday) return 'assets/mascot/ovejita_celebrando.png';
    if (sheepLost) return 'assets/mascot/ovejita_perdida.png';
    if (atRisk && streak > 0) return 'assets/mascot/ovejita_esperando.png';
    return 'assets/mascot/ovejita.png';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stage = FaithTreeStages.stageFor(cumulativeMinutes);
    final double treeSize;
    switch (stage) {
      case FaithTreeStage.semilla:
        treeSize = 34;
        break;
      case FaithTreeStage.brote:
        treeSize = 46;
        break;
      case FaithTreeStage.plantaJoven:
        treeSize = 62;
        break;
      case FaithTreeStage.arbol:
        treeSize = 82;
        break;
    }

    return Semantics(
      label: 'Racha: $streak dias caminando con el Pastor. '
          '$minutesToday minutos orados hoy.',
      child: Container(
        height: 330,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _MeadowPainter(
                scheme: scheme,
                cumulativeMinutes: cumulativeMinutes,
              ),
            ),
            // Arbol de fe sobre la colina derecha: crece con los minutos
            // acumulados, igual que siempre, pero ahora vive en la pradera.
            Positioned(
              right: 26,
              bottom: 96,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 520),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: SvgPicture.asset(
                  FaithTreeStages.illustrationFor(stage),
                  key: ValueKey(stage),
                  width: treeSize,
                  height: treeSize,
                ),
              ),
            ),
            // La ovejita (eres tu, siempre feliz) junto al arroyo, con
            // la expresion del momento (celebrando / esperando / perdida
            // que vuelve / caminando). El cambio se anima suave.
            Positioned(
              left: 20,
              bottom: 12,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Image.asset(
                  _mascotAsset,
                  key: ValueKey(_mascotAsset),
                  height: 66,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Contenido principal: overline + numero gigante + etiqueta +
            // mensaje de estado (sin culpa, siempre invitacion).
            Positioned(
              top: 18,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Text(
                    'TU CAMINAR CON EL PASTOR',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: scheme.secondary,
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Text(
                      '$streak',
                      style: AppTypography.display.copyWith(
                        fontSize: 96,
                        height: 1.05,
                        color: scheme.primary,
                        shadows: [
                          Shadow(
                            color: scheme.surface.withValues(alpha: 0.65),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    streak == 0
                        ? 'Hoy puede ser tu primer paso'
                        : streak == 1
                            ? 'día caminando con el Pastor'
                            : 'días caminando con el Pastor',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: AppTypography.quote.copyWith(
                        fontSize: 13.5,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Anillo de minutos del dia (abajo a la derecha, sobre la
            // pradera, sin competir con el numero gigante).
            Positioned(
              right: 18,
              bottom: 14,
              child: _MinutesRing(
                minutes: minutesToday,
                goal: dailyGoalMinutes,
              ),
            ),
            if (freezeTokens != null)
              Positioned(
                right: 14,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.ac_unit, size: 14, color: scheme.primary),
                      const SizedBox(width: 3),
                      Text(
                        '$freezeTokens',
                        style: AppTypography.caption.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Anillo de minutos orados hoy: progreso dorado sobre una pastilla
/// circular semitransparente, con el numero al centro.
class _MinutesRing extends StatelessWidget {
  final int minutes;
  final int goal;

  const _MinutesRing({required this.minutes, required this.goal});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = goal <= 0 ? 0.0 : (minutes / goal).clamp(0.0, 1.0);
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          trackColor: scheme.primary.withValues(alpha: 0.14),
          progressColor: scheme.secondary,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$minutes',
                style: AppTypography.title.copyWith(
                  fontSize: 21,
                  height: 1.0,
                  color: scheme.primary,
                ),
              ),
              Text(
                'min hoy',
                style: AppTypography.caption.copyWith(
                  fontSize: 8.5,
                  letterSpacing: 0.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);
    if (progress > 0) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = progressColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}

/// Pinta la escena de la pradera del Salmo 23: cielo de amanecer, sol
/// suave, colinas, arroyo ("junto a aguas de reposo") y flores/pasto que
/// florecen de forma determinista con los minutos acumulados de oracion.
class _MeadowPainter extends CustomPainter {
  final ColorScheme scheme;
  final int cumulativeMinutes;

  _MeadowPainter({required this.scheme, required this.cumulativeMinutes});

  bool get _isDark => scheme.brightness == Brightness.dark;

  /// Pseudoaleatorio determinista (misma pradera en cada frame, sin
  /// necesidad de estado): fraccion de un seno escalado, patron clasico.
  double _rand(int i, int salt) {
    final v = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  /// X aproximada del centro del arroyo a una altura dada (para no pintar
  /// flores ni pasto encima del agua).
  double _streamXAt(double y, double w, double h, double horizonY) {
    final t = ((y - horizonY) / (h - horizonY)).clamp(0.0, 1.0);
    return w * (0.60 - 0.46 * t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizonY = h * 0.46;

    // 1. Cielo de amanecer (en "Vigilia" oscura, un alba tenue).
    final skyTop = _isDark
        ? scheme.surface
        : Color.lerp(scheme.surface, scheme.primaryContainer, 0.30)!;
    final skyHorizon = _isDark
        ? Color.lerp(scheme.surface, scheme.secondaryContainer, 0.45)!
        : Color.lerp(scheme.surface, scheme.tertiaryContainer, 0.75)!;
    final skyRect = Rect.fromLTWH(0, 0, w, horizonY + h * 0.08);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyHorizon],
        ).createShader(skyRect),
    );

    // 2. Sol de amanecer con halo dorado suave.
    final sunCenter = Offset(w * 0.78, horizonY * 0.60);
    canvas.drawCircle(
      sunCenter,
      w * 0.22,
      Paint()
        ..shader = RadialGradient(
          colors: [
            scheme.secondary.withValues(alpha: _isDark ? 0.32 : 0.42),
            scheme.secondary.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: w * 0.22)),
    );
    canvas.drawCircle(
      sunCenter,
      w * 0.05,
      Paint()
        ..color = Color.lerp(
          scheme.secondary,
          scheme.surface,
          _isDark ? 0.15 : 0.55,
        )!,
    );

    // 3. Colina lejana.
    final farHill = Path()
      ..moveTo(0, horizonY + h * 0.02)
      ..quadraticBezierTo(w * 0.30, horizonY - h * 0.075, w * 0.62, horizonY)
      ..quadraticBezierTo(w * 0.85, horizonY + h * 0.04, w, horizonY + h * 0.01)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      farHill,
      Paint()
        ..color = Color.lerp(
          scheme.primaryContainer,
          scheme.tertiary,
          _isDark ? 0.35 : 0.30,
        )!
            .withValues(alpha: 0.85),
    );

    // 4. Pradera principal.
    final meadowColor = _isDark
        ? Color.lerp(scheme.primaryContainer, scheme.surface, 0.25)!
        : Color.lerp(scheme.primaryContainer, scheme.tertiary, 0.45)!;
    final meadow = Path()
      ..moveTo(0, horizonY + h * 0.10)
      ..quadraticBezierTo(
        w * 0.42,
        horizonY + h * 0.015,
        w,
        horizonY + h * 0.085,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(meadow, Paint()..color = meadowColor);

    // 5. Arroyo: "junto a aguas de reposo me pastoreara".
    final streamBase = Color.lerp(
      scheme.primaryContainer,
      _isDark ? scheme.surface : Colors.white,
      _isDark ? 0.10 : 0.45,
    )!;
    final streamColor = Color.alphaBlend(const Color(0x3D2E6F86), streamBase);
    final streamPath = Path()
      ..moveTo(w * 0.60, horizonY + h * 0.055)
      ..cubicTo(w * 0.50, h * 0.66, w * 0.44, h * 0.72, w * 0.30, h * 0.82)
      ..cubicTo(w * 0.22, h * 0.88, w * 0.16, h * 0.93, w * 0.12, h);
    canvas.drawPath(
      streamPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.085
        ..strokeCap = StrokeCap.round
        ..color = streamColor,
    );
    canvas.drawPath(
      streamPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.028
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: _isDark ? 0.18 : 0.50),
    );

    // 5b. v17: CAMINO DE LUZ + el PASTOR que guia (Salmo 23 / Juan 10).
    // Un sendero calido de luz sube desde abajo (donde esta la ovejita)
    // hacia el amanecer, y el Pastor camina ADELANTE en ese camino con su
    // cayado. La ovejita (PNG, encima) lo sigue: "mis ovejas oyen mi voz...
    // y me siguen".
    final pathLight = Path()
      ..moveTo(w * 0.16, h * 0.98)
      ..quadraticBezierTo(w * 0.42, h * 0.86, w * 0.56, h * 0.72)
      ..quadraticBezierTo(
          w * 0.70, h * 0.58, sunCenter.dx, sunCenter.dy + h * 0.14);
    canvas.drawPath(
      pathLight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.11
        ..strokeCap = StrokeCap.round
        ..color = scheme.secondary.withValues(alpha: _isDark ? 0.14 : 0.26)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawPath(
      pathLight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round
        ..color = scheme.secondary.withValues(alpha: _isDark ? 0.22 : 0.44),
    );
    _drawShepherd(canvas, Offset(w * 0.55, h * 0.71), h * 0.20);

    // 6. Flores: la pradera FLORECE con los minutos orados (cada ~12 min
    // acumulados brota una flor nueva, hasta un maximo sereno).
    final flowerCount = (3 + cumulativeMinutes ~/ 12).clamp(3, 44);
    final petalGold = scheme.secondary;
    final petalLight = _isDark
        ? scheme.onSurface.withValues(alpha: 0.85)
        : Colors.white;
    for (var i = 0; i < flowerCount; i++) {
      final fx = _rand(i, 1) * w;
      final fy = h * (0.62 + _rand(i, 2) * 0.34);
      if ((fx - _streamXAt(fy, w, h, horizonY)).abs() < w * 0.07) continue;
      final r = 1.6 + _rand(i, 3) * 1.8;
      final color = i.isEven ? petalGold : petalLight;
      final center = Offset(fx, fy);
      for (var p = 0; p < 5; p++) {
        final ang = p * 2 * math.pi / 5;
        canvas.drawCircle(
          center + Offset(math.cos(ang), math.sin(ang)) * r,
          r * 0.62,
          Paint()..color = color.withValues(alpha: 0.9),
        );
      }
      canvas.drawCircle(
        center,
        r * 0.55,
        Paint()..color = i.isEven ? petalLight : petalGold,
      );
    }

    // 7. Matitas de pasto para dar textura a la pradera.
    final grassPaint = Paint()
      ..color = Color.lerp(meadowColor, scheme.primary, 0.35)!
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 26; i++) {
      final gx = _rand(i, 7) * w;
      final gy = h * (0.60 + _rand(i, 8) * 0.36);
      if ((gx - _streamXAt(gy, w, h, horizonY)).abs() < w * 0.06) continue;
      final blade = 4.0 + _rand(i, 9) * 5.0;
      canvas.drawLine(
        Offset(gx, gy),
        Offset(gx - blade * 0.35, gy - blade),
        grassPaint,
      );
      canvas.drawLine(
        Offset(gx, gy),
        Offset(gx + blade * 0.40, gy - blade * 0.8),
        grassPaint,
      );
    }
  }

  /// Dibuja al Pastor como una silueta calida caminando hacia el amanecer,
  /// con su cayado. [feet] es el punto donde apoya los pies y [height] su
  /// altura total. En modo oscuro se aclara para seguir siendo visible.
  void _drawShepherd(Canvas canvas, Offset feet, double height) {
    final h = height;
    final fx = feet.dx;
    final fy = feet.dy;
    final color = _isDark
        ? scheme.primary.withValues(alpha: 0.62)
        : Color.lerp(scheme.primary, Colors.black, 0.22)!
            .withValues(alpha: 0.92);
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shoulderY = fy - h * 0.66;
    final shoulderHalf = h * 0.15;
    final hemHalf = h * 0.24;

    // Manto / tunica.
    final robe = Path()
      ..moveTo(fx - shoulderHalf, shoulderY)
      ..quadraticBezierTo(fx - hemHalf * 1.15, fy - h * 0.28, fx - hemHalf, fy)
      ..quadraticBezierTo(fx, fy - h * 0.06, fx + hemHalf, fy)
      ..quadraticBezierTo(
          fx + hemHalf * 1.15, fy - h * 0.28, fx + shoulderHalf, shoulderY)
      ..quadraticBezierTo(
          fx, shoulderY - h * 0.10, fx - shoulderHalf, shoulderY)
      ..close();
    canvas.drawPath(robe, fill);

    // Cabeza.
    final headR = h * 0.11;
    canvas.drawCircle(
        Offset(fx, shoulderY - h * 0.08 - headR * 0.5), headR, fill);

    // Cayado con gancho, un poco adelante (hacia el amanecer).
    final staffPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.045
      ..strokeCap = StrokeCap.round;
    final staffX = fx + hemHalf + h * 0.12;
    final staffTop = fy - h * 1.02;
    canvas.drawLine(Offset(staffX, fy), Offset(staffX, staffTop), staffPaint);
    final crook = Path()
      ..moveTo(staffX, staffTop)
      ..quadraticBezierTo(
          staffX - h * 0.02, staffTop - h * 0.11, staffX - h * 0.13,
          staffTop - h * 0.02);
    canvas.drawPath(crook, staffPaint);
  }

  @override
  bool shouldRepaint(_MeadowPainter oldDelegate) =>
      oldDelegate.scheme != scheme ||
      oldDelegate.cumulativeMinutes != cumulativeMinutes;
}
