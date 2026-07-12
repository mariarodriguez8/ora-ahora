import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'onboarding_done_screen.dart';

/// Pantalla de onboarding que pregunta que situaciones le importan mas al
/// usuario, para personalizar el feed de inicio.
class OnboardingCategoriesScreen extends StatefulWidget {
  const OnboardingCategoriesScreen({super.key});

  @override
  State<OnboardingCategoriesScreen> createState() =>
      _OnboardingCategoriesScreenState();
}

class _OnboardingCategoriesScreenState
    extends State<OnboardingCategoriesScreen> {
  // Situaciones destacadas para el onboarding (subconjunto de las 10
  // categorias totales del catalogo, las mas relevantes para personalizar
  // el feed inicial).
  static const _opciones = [
    PrayerCategories.ansiedad,
    PrayerCategories.gratitud,
    PrayerCategories.familia,
    PrayerCategories.trabajo,
    PrayerCategories.noche, // "sueño / descanso"
    PrayerCategories.tentacionEnfoque,
  ];

  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tus intereses')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Qué te gustaría trabajar en oración?',
                  style: AppTypography.headline),
              const SizedBox(height: 8),
              Text(
                'Elige una o más opciones. Usaremos esto para mostrarte '
                'oraciones más relevantes en tu inicio. Podrás cambiarlo '
                'cuando quieras desde Ajustes.',
                style: AppTypography.body.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _opciones.map((cat) {
                  final label = cat == PrayerCategories.noche
                      ? 'Sueño / descanso'
                      : PrayerCategories.displayName(cat);
                  return FilterChip(
                    label: Text(label),
                    selected: _selected.contains(cat),
                    showCheckmark: false,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selected.add(cat);
                        } else {
                          _selected.remove(cat);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
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
                  child: const Text('Omitir por ahora'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
