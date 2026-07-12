import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/appearance_service.dart';
import '../../theme/app_palettes.dart';
import '../../theme/app_typography.dart';

/// Pantalla de Ajustes > Apariencia: elegir una de las 4 paletas de color
/// Material 3 (o seguir el tema del sistema), y activar "Modo Simple"
/// (fuente y botones mas grandes, pensado para usuarios mayores).
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceService>();
    final explicitId = appearance.explicitPaletteId;

    return Scaffold(
      appBar: AppBar(title: const Text('Apariencia')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text('Paleta de color', style: AppTypography.headline),
            const SizedBox(height: 6),
            Text(
              'Elige el estilo visual de Ora Ahora. "Seguir el sistema" usa '
              'Zafiro Calmo en modo claro y Mares Profundos en modo oscuro '
              'automáticamente.',
              style: AppTypography.body,
            ),
            const SizedBox(height: 16),
            _SystemDefaultTile(
              selected: explicitId == null,
              onTap: () => appearance.useSystemDefault(),
            ),
            const SizedBox(height: 10),
            for (final palette in AppPalette.all) ...[
              _PaletteTile(
                palette: palette,
                selected: explicitId == palette.id,
                onTap: () => appearance.setPalette(palette.id),
              ),
              const SizedBox(height: 10),
            ],
            const Divider(height: 40),
            Text('Accesibilidad', style: AppTypography.headline),
            const SizedBox(height: 6),
            Text(
              'Aumenta el tamaño del texto y de los botones principales '
              '(altura ~65dp) en toda la app. Recomendado para usuarios '
              'mayores o con baja visión.',
              style: AppTypography.body,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: appearance.simpleModeEnabled,
              onChanged: (value) => appearance.setSimpleMode(value),
              title: const Text('Modo Simple'),
              subtitle: const Text('Texto y botones más grandes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemDefaultTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _SystemDefaultTile({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: scheme.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Seguir el sistema', style: AppTypography.title),
                  Text(
                    'Zafiro Calmo (claro) / Mares Profundos (oscuro)',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.brightness_auto),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de paleta con una franja de vista previa a todo el ancho (cada
/// uno de los 4 colores de marca ocupa un cuarto), en vez de los antiguos
/// "chips" circulares pequeños: da una idea mucho mas fiel de como se va a
/// ver la app con esa paleta antes de tocarla.
class _PaletteTile extends StatelessWidget {
  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteTile({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline.withValues(alpha: 0.35),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  for (final color in palette.swatch)
                    Expanded(child: Container(color: color)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(palette.nombre, style: AppTypography.title),
                        Text(palette.descripcion, style: AppTypography.caption),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, color: scheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
