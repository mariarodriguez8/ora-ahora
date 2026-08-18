import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../data/gate_prayers.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'onboarding_progress_dots.dart';
import 'onboarding_times_screen.dart';

class OnboardingCategoriesScreen extends StatefulWidget {
  const OnboardingCategoriesScreen({super.key});

  @override
  State<OnboardingCategoriesScreen> createState() =>
      _OnboardingCategoriesScreenState();
}

class _OnboardingCategoriesScreenState
    extends State<OnboardingCategoriesScreen> {
  static const _opciones = [
    (PrayerCategories.ansiedad, '😟 Ansiedad'),
    (PrayerCategories.paz, '🕊️ Paz interior'),
    (PrayerCategories.gratitud, '🙌 Gratitud'),
    (PrayerCategories.familia, '👨‍👩‍👧 Familia'),
    (PrayerCategories.matrimonio, '💛 Matrimonio y pareja'),
    (PrayerCategories.trabajo, '💼 Trabajo'),
    (PrayerCategories.finanzas, '🪙 Finanzas'),
    (PrayerCategories.sanidad, '🌿 Salud y sanidad'),
    (PrayerCategories.perdon, '🤝 Perdón'),
    (PrayerCategories.duelo, '🕯️ Una pérdida'),
    (PrayerCategories.soledad, '🫂 Soledad'),
    (PrayerCategories.noche, '😴 Dormir mejor'),
    (PrayerCategories.tentacionEnfoque, '📵 Menos celular'),
  ];

  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const OnboardingTopBar(step: 1),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Qué te gustaría\nentregarle a Dios?',
                  style: AppTypography.display.copyWith(fontSize: 28)),
              const SizedBox(height: 12),
              Text(
                'Toca todas las que sientas tuyas — pueden ser varias. '
                'Con esto elegimos las oraciones para ti.',
                style:
                    AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final (cat, label) in _opciones)
                        _CategoryChip(
                          label: label,
                          selected: _selected.contains(cat),
                          onTap: () {
                            setState(() {
                              if (_selected.contains(cat)) {
                                _selected.remove(cat);
                              } else {
                                _selected.add(cat);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () async {
                          final prefs = context.read<PrefsService>();
                          await prefs
                              .setPreferredCategories(_selected.toList());
                          await syncGatePrayers(prefs);
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const OnboardingTimesScreen()),
                          );
                        },
                  child: Text(_selected.isEmpty
                      ? 'Elige al menos una'
                      : 'Continuar (${_selected.length} elegida${_selected.length == 1 ? '' : 's'})'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.tealDeep : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.tealDeep : AppColors.tealLight,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              fontSize: 15.5,
              color: selected ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
