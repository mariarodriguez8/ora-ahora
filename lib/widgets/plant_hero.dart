import 'package:flutter/material.dart';

import '../screens/paywall/paywall_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Hero del inicio "Sequía → Avivamiento" (v26).
///
/// La ovejita sostiene una plantita que ES la fe de la persona. Empieza
/// SECA (marchita, gris) cuando lleva días sin orar, y con cada oración
/// (racha) reverdece: brote → flor → fruto. La regla psicológica clave:
/// la plantita crece por ORAR y se marchita por NO orar — NUNCA por no
/// pagar. Plus solo protege/da extras (eso lo vende el paywall).
///
/// Reemplaza a `MeadowHero` conservando las mismas entradas para que el
/// resto del inicio no cambie.
class PlantHero extends StatelessWidget {
  final int streak;
  final bool prayedToday;
  final int daysSinceLastPrayed;
  final bool isPlus;

  const PlantHero({
    super.key,
    required this.streak,
    required this.prayedToday,
    required this.daysSinceLastPrayed,
    required this.isPlus,
  });

  /// Etapa 0=seca, 1=brote, 2=flor, 3=fruto según la racha.
  /// Cuantos de los siete cuadros van llenos. La semana se repite: al
  /// llegar a siete, vuelve a empezar. El total de siempre va aparte.
  int get _cuadrosLlenos => streak <= 0 ? 0 : ((streak - 1) % 7) + 1;

  int get _stage {
    if (streak <= 0) return 0;
    if (streak <= 2) return 1;
    if (streak <= 6) return 2;
    return 3;
  }

  String get _asset {
    switch (_stage) {
      case 1:
        return 'assets/mascot/ovejita_planta_brote.png';
      case 2:
        return 'assets/mascot/ovejita_planta_flor.png';
      case 3:
        return 'assets/mascot/ovejita_planta_fruto.png';
      default:
        return 'assets/mascot/ovejita_planta_seca.png';
    }
  }

  String get _palabra {
    switch (_stage) {
      case 1:
        return 'Brotando';
      case 2:
        return 'Floreciendo';
      case 3:
        return 'Con fruto';
      default:
        return 'Seca';
    }
  }

  /// Frase-espejo, en la voz del ICP.
  String get _frase {
    if (_stage == 0) {
      if (daysSinceLastPrayed >= 1) {
        return 'hace $daysSinceLastPrayed '
            '${daysSinceLastPrayed == 1 ? 'día' : 'días'} que no la riegas';
      }
      return 'riégala hoy con una oración';
    }
    if (prayedToday) {
      if (streak >= 14) {
        return 'Van $streak días con Él. Y apenas vamos por la mitad.';
      }
      if (streak >= 7) {
        return '$streak veces le hablaste. $streak veces te escuchó.';
      }
      if (streak >= 2 && _stage < 3) {
        return '$streak días seguidos.\nTu árbol está a un riego de florecer.';
      }
      if (streak >= 2) return '$streak días seguidos. Se nota.';
      return 'Hoy le hablaste. Y Él te escuchó.';
    }
    return 'tu plantita tiene sed hoy 💧';
  }

  Color get _acento => _stage == 0 ? AppColors.inkSoft : AppColors.tealDeep;

  @override
  Widget build(BuildContext context) {
    final seca = _stage == 0;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: seca
                ? const Color(0xFFF1EFE8)
                : AppColors.tealLight.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: seca ? const Color(0xFFD3D1C7) : AppColors.tealLight,
            ),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('tu fe hoy',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.inkSoft)),
              ),
              const SizedBox(height: 4),
              // La ovejita con su plantita: el estado se lee de un vistazo.
              Image.asset(
                _asset,
                height: 180,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
              // UNA palabra grande = comprensión instantánea.
              Text(
                _palabra,
                style: AppTypography.display.copyWith(
                  fontSize: 34,
                  color: seca ? const Color(0xFF2C2C2A) : AppColors.tealDeep,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _frase,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 14),
              // Medidor tipo "riego" — bucle abierto que pide llenarse.
              // Siete cuadros, uno por dia. El progreso se ve de un vistazo y se
              // siente: cada dia cumplido rellena uno. Al septimo, la semana entera.
              Row(
                children: List.generate(7, (i) {
                  final hecho = i < _cuadrosLlenos;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        height: 22,
                        decoration: BoxDecoration(
                          color: hecho
                              ? (seca ? const Color(0xFFD3D1C7) : AppColors.tealDeep)
                              : AppColors.inkSoft.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.inkSoft
                                .withValues(alpha: hecho ? 0.0 : 0.20),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Text(
                '"como árbol plantado junto a corrientes de agua" — Salmo 1:3',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSoft,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        // Tarjeta de deseo (solo si aún no es Plus): muestra a dónde puede
        // llegar y abre el viaje de 7 días. Vende el acompañamiento, no la fe.
        if (!isPlus) ...[
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.tealLight.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.tealLight),
              ),
              child: Row(
                children: [
                  Image.asset('assets/mascot/ovejita_planta_fruto.png',
                      height: 44, fit: BoxFit.contain),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('así puede verse tu fe',
                            style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.tealDeep)),
                        Flexible(
                          child: Text('el viaje de 7 días para reverdecer',
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.tealDeep)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.tealDeep),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
