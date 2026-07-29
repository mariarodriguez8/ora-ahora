import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../services/prayer_repository.dart';
import '../../services/prefs_service.dart';
import '../../services/purchase_service.dart';
import '../../services/streak_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/amen_celebration.dart';
import 'onboarding_progress_dots.dart';
import 'onboarding_reminders_screen.dart';

/// El momento "aha" del onboarding: la persona ora AQUI MISMO su primera
/// oracion (corta, elegida segun sus intereses) y arranca su racha en el
/// dia 1, antes de ver cualquier otra cosa de la app.
class OnboardingFirstPrayerScreen extends StatefulWidget {
  const OnboardingFirstPrayerScreen({super.key});

  @override
  State<OnboardingFirstPrayerScreen> createState() =>
      _OnboardingFirstPrayerScreenState();
}

class _OnboardingFirstPrayerScreenState
    extends State<OnboardingFirstPrayerScreen> {
  Prayer? _prayer;
  bool _amen = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<PrayerRepository>();
    final prefs = context.read<PrefsService>();
    // Coherencia total: la primera oracion sale del PRIMER tema que la
    // persona eligio (si escogio "duelo", la oracion ES de duelo).
    final cats = prefs.preferredCategories;
    List pool = cats.isEmpty ? [] : await repo.byCategory(cats.first);
    if (pool.isEmpty) pool = await repo.byCategories(cats);
    if (pool.isEmpty) pool = await repo.all();
    pool.sort((a, b) =>
        a.duracionEstimadaMin.compareTo(b.duracionEstimadaMin));
    if (!mounted) return;
    setState(() => _prayer = pool.first);
  }

  Future<void> _onAmen() async {
    final streak = context.read<StreakService>();
    final isPlus = context.read<PurchaseService>().isPlusUser;
    await streak.markPrayedToday(
      isPlusUser: isPlus,
      minutes: _prayer?.duracionEstimadaMin ?? 1,
    );
    if (!mounted) return;
    setState(() => _amen = true);
    await showAmenCelebration(
      context,
      streak: 1,
      referencia: _prayer?.referenciaBiblica ?? '',
    );
    // Al cerrar el momento Amen, avanza SOLO (sin segundo boton).
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingRemindersScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prayer = _prayer;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const OnboardingTopBar(step: 5),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: prayer == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _amen
                          ? '¡Día 1 de tu racha! 🔥'
                          : 'Empecemos ahora mismo',
                      style: AppTypography.display.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _amen
                          ? 'Tu primera oración ya cuenta. Así de simple '
                              'va a ser cada día.'
                          : 'no tienes que decirlo bien ni sentir algo raro. '
                              'solo léela y háblale a Dios:',
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.tealLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(prayer.titulo,
                                  style: AppTypography.headline
                                      .copyWith(fontSize: 21)),
                              const SizedBox(height: 14),
                              Text(prayer.texto,
                                  style: AppTypography.prayerText
                                      .copyWith(fontSize: 17)),
                              const SizedBox(height: 14),
                              Text(
                                prayer.referenciaBiblica,
                                style: AppTypography.quote
                                    .copyWith(color: AppColors.amber),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _amen
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const OnboardingRemindersScreen(),
                                  ),
                                );
                              }
                            : _onAmen,
                        child: Text(_amen ? 'Continuar' : 'Amén 🙏'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
