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
