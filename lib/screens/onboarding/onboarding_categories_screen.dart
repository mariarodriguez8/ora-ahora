import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'onboarding_done_screen.dart';
import 'onboarding_progress_dots.dart';

class OnboardingCategoriesScreen extends StatefulWidget {
  const OnboardingCategoriesScreen({super.key});

  @override
  State<OnboardingCategoriesScreen> createState() =>
      _OnboardingCategoriesScreenState();
}

class _OnboardingCategoriesScreenState
    extends State<OnboardingCategoriesScreen> {
  static const _opciones = [
    PrayerCategories.ansiedad,
    PrayerCategories.gratitud,
    PrayerCategories.familia,
    PrayerCategories.trabajo,
    PrayerCategories.noche,
    PrayerCategories.tentacionEnfoque,
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
              Text('¿Qué te gustaría trabajar en oración?',
                  style: AppTypography.display),
              const SizedBox(height: 12),
              Text(
                'Elige una o más opciones. Usaremos esto para mostrarte '
                'oraciones más relevantes en tu inicio. Podrás cambiarlo '
                'cuando quieras desde Ajustes.',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _opciones.map((cat) {
                  final label = cat == PrayerCategories.noche
                      ? 'Sueño / descanso'
                      : PrayerCategories.displayName(cat);
                  final selected = _selected.contains(cat);
                  return _CategoryChip(
                    label: label,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selected.remove(cat);
                        } else {
                          _selected.add(cat);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final prefs = context.read<PrefsService>();
                    await prefs.setPreferredCategories(_selected.toList());
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OnboardingDoneScreen(),
                      ),
                    );
                  },
                  child: const Text('Siguiente'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OnboardingDoneScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Omitir por ahora',
                    style: AppTypography.body.copyWith(color: AppColors.inkSoft),
                  ),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.tealDeep : AppColors.tealLight,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTypography.body.copyWith(
                  color: selected ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
