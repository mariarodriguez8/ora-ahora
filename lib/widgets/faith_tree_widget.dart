import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Etapas visuales del widget "Semilla/Árbol de fe".
enum FaithTreeStage { semilla, brote, plantaJoven, arbol }

/// Logica pura (sin estado, sin backend) para derivar la etapa de
/// crecimiento a partir de los minutos acumulados de oración marcada
/// (`StreakService.cumulativeMinutes`).
class FaithTreeStages {
  FaithTreeStages._();

  /// Minutos acumulados requeridos para llegar a cada etapa (indice 0 =
  /// semilla, ... , ultimo = arbol).
  static const List<int> thresholds = [0, 30, 120, 360];

  static FaithTreeStage stageFor(int minutes) {
    if (minutes >= thresholds[3]) return FaithTreeStage.arbol;
    if (minutes >= thresholds[2]) return FaithTreeStage.plantaJoven;
    if (minutes >= thresholds[1]) return FaithTreeStage.brote;
    return FaithTreeStage.semilla;
  }

  static String labelFor(FaithTreeStage stage) {
    switch (stage) {
      case FaithTreeStage.semilla:
        return 'Semilla';
      case FaithTreeStage.brote:
        return 'Brote';
      case FaithTreeStage.plantaJoven:
        return 'Planta joven';
      case FaithTreeStage.arbol:
        return 'Árbol de fe';
    }
  }

  /// Ilustracion SVG original (dibujada a mano, ver `assets/illustrations/`)
  /// para cada etapa, en reemplazo del icono generico de Material que se
  /// usaba antes (`Icons.grain`/`Icons.spa`/`Icons.local_florist`/
  /// `Icons.park`).
  static String illustrationFor(FaithTreeStage stage) {
    switch (stage) {
      case FaithTreeStage.semilla:
        return 'assets/illustrations/tree_semilla.svg';
      case FaithTreeStage.brote:
        return 'assets/illustrations/tree_brote.svg';
      case FaithTreeStage.plantaJoven:
        return 'assets/illustrations/tree_planta_joven.svg';
      case FaithTreeStage.arbol:
        return 'assets/illustrations/tree_arbol.svg';
    }
  }

  /// Minutos que faltan para la siguiente etapa, o `null` si ya se
  /// alcanzo la etapa maxima ("Árbol de fe").
  static int? minutesToNextStage(int minutes) {
    for (final threshold in thresholds) {
      if (minutes < threshold) return threshold - minutes;
    }
    return null;
  }

  /// Progreso (0.0 a 1.0) dentro de la etapa actual, para la barra visual.
  static double progressWithinStage(int minutes) {
    final stage = stageFor(minutes);
    final index = FaithTreeStage.values.indexOf(stage);
    final lower = thresholds[index];
    final hasNext = index + 1 < thresholds.length;
    if (!hasNext) return 1.0;
    final upper = thresholds[index + 1];
    final span = upper - lower;
    if (span <= 0) return 1.0;
    final progress = (minutes - lower) / span;
    if (progress < 0) return 0.0;
    if (progress > 1) return 1.0;
    return progress;
  }
}

/// Widget visual de "Semilla / Árbol de fe": una metáfora de crecimiento
/// alternativa (y complementaria) a la racha numérica, pensada para no
/// sentirse punitiva si un día se pierde la racha (los minutos acumulados
/// nunca bajan). Crece en 4 etapas discretas segun los minutos totales de
/// oración marcada, usando solo datos que ya existen en `StreakState`
/// (`cumulativeMinutes`), sin necesidad de ningun backend nuevo.
///
/// Sigue siendo `StatelessWidget`: el cambio de etapa se anima con
/// `AnimatedSwitcher` (curva organica `Curves.easeOutBack`, no un salto
/// seco) y la barra de progreso con `TweenAnimationBuilder`, ambos widgets
/// que administran su propia animacion interna sin necesitar que este
/// widget mantenga estado propio.
class FaithTreeWidget extends StatelessWidget {
  final int cumulativeMinutes;

  const FaithTreeWidget({super.key, required this.cumulativeMinutes});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stage = FaithTreeStages.stageFor(cumulativeMinutes);
    final progress = FaithTreeStages.progressWithinStage(cumulativeMinutes);
    final remaining = FaithTreeStages.minutesToNextStage(cumulativeMinutes);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            label: 'Etapa actual: ${FaithTreeStages.labelFor(stage)}',
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
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
                  width: 40,
                  height: 40,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FaithTreeStages.labelFor(stage),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$cumulativeMinutes min de oración acumulados',
                  style: TextStyle(fontSize: 13, color: scheme.onSecondaryContainer),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: scheme.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remaining != null
                      ? 'Te faltan $remaining min para la próxima etapa'
                      : '¡Alcanzaste la etapa máxima!',
                  style: TextStyle(fontSize: 11, color: scheme.onSecondaryContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
