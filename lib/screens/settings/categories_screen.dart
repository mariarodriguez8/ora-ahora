import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_typography.dart';
import '../../widgets/category_chip.dart';

/// Permite ajustar en cualquier momento las categorías de interés que
/// personalizan el feed de inicio (las mismas que se preguntan en el
/// onboarding, pero aquí se muestran las 10 categorías completas).
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = context.read<PrefsService>().preferredCategories.toSet();
  }

  Future<void> _save() async {
    await context.read<PrefsService>().setPreferredCategories(_selected.toList());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Intereses actualizados')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis intereses')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Elige los temas que quieres ver más en tu inicio.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: PrayerCategories.all.map((cat) {
                  return CategoryChip(
                    categoria: cat,
                    selected: _selected.contains(cat),
                    onChanged: (v) {
                      setState(() {
                        if (v) {
                          _selected.add(cat);
                        } else {
                          _selected.remove(cat);
                        }
                      });
                      _save();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
