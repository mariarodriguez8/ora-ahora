import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/estampas.dart';
import '../../services/prefs_service.dart';
import '../../services/streak_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Galería de estampas: las desbloqueadas por racha se ven completas y se
/// pueden compartir; las que faltan salen bloqueadas con el día en que
/// llegan. Al abrir la galería se marca todo lo desbloqueado como "visto".
class EstampasScreen extends StatefulWidget {
  const EstampasScreen({super.key});

  @override
  State<EstampasScreen> createState() => _EstampasScreenState();
}

class _EstampasScreenState extends State<EstampasScreen> {
  @override
  void initState() {
    super.initState();
    // Marca como vistas las estampas desbloqueadas (apaga el aviso "nueva").
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final racha = context.read<StreakService>().currentStreak;
      context.read<PrefsService>().setEstampasSeenStreak(racha);
    });
  }

  @override
  Widget build(BuildContext context) {
    final racha = context.watch<StreakService>().currentStreak;
    final desbloqueadas = estampasDesbloqueadas(racha);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Tus estampas'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
              child: Text(
                desbloqueadas == 0
                    ? 'Ora cada día y ve desbloqueando estampas para guardar y compartir 🌱'
                    : 'Llevas $desbloqueadas de ${kEstampas.length}. Compártelas con quien quieras.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.inkSoft),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.62,
                ),
                itemCount: kEstampas.length,
                itemBuilder: (context, i) {
                  final e = kEstampas[i];
                  final abierta = racha >= e.dia;
                  return _EstampaTile(
                    estampa: e,
                    desbloqueada: abierta,
                    onTap: abierta
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _EstampaDetalle(estampa: e),
                              ),
                            )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstampaTile extends StatelessWidget {
  final Estampa estampa;
  final bool desbloqueada;
  final VoidCallback? onTap;

  const _EstampaTile({
    required this.estampa,
    required this.desbloqueada,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: desbloqueada
            ? Image.asset(estampa.asset, fit: BoxFit.cover)
            : Container(
                color: AppColors.tealLight.withValues(alpha: 0.35),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        color: AppColors.tealDeep, size: 30),
                    const SizedBox(height: 10),
                    Text('Día ${estampa.dia}',
                        style: AppTypography.title
                            .copyWith(color: AppColors.tealDeep)),
                    const SizedBox(height: 4),
                    Text('sigue orando',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.inkSoft)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _EstampaDetalle extends StatelessWidget {
  final Estampa estampa;

  const _EstampaDetalle({required this.estampa});

  Future<void> _compartir(BuildContext context) async {
    try {
      final data = await rootBundle.load(estampa.asset);
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/${estampa.asset.split('/').last}');
      await f.writeAsBytes(data.buffer.asUint8List(), flush: true);
      await Share.shareXFiles(
        [XFile(f.path)],
        text: '${estampa.versiculo} · Ora Ahora 🌱',
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos compartir la estampa 😔')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(estampa.asset, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _compartir(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealDeep,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Compartir 📤'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de entrada en el Inicio hacia la galería de estampas.
class EstampasCard extends StatelessWidget {
  final int racha;
  final int vistaHasta;
  final VoidCallback onTap;

  const EstampasCard({
    super.key,
    required this.racha,
    required this.vistaHasta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final desbloqueadas = estampasDesbloqueadas(racha);
    final nueva = hayEstampaNueva(racha, vistaHasta);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: nueva ? AppColors.amber : AppColors.tealLight,
            width: nueva ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tealLight.withValues(alpha: 0.5),
              ),
              child: const Text('🌿', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Tus estampas',
                          style: AppTypography.body
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      if (nueva)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.amber,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('¡nueva! 🎉',
                              style: AppTypography.caption.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('$desbloqueadas de ${kEstampas.length} desbloqueadas',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.inkSoft)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}
