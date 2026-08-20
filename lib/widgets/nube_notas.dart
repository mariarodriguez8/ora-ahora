import 'dart:math';

import 'package:flutter/material.dart';

import '../screens/journal/journal_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Globito de sugerencia en el home.
///
/// Invita a escribir en el diario lo que la persona trae encima. Elige uno
/// de cuatro mensajes al azar y se puede cerrar con la X.
class NubeNotas extends StatefulWidget {
  const NubeNotas({super.key});

  @override
  State<NubeNotas> createState() => _NubeNotasState();
}

class _NubeNotasState extends State<NubeNotas> {
  static const _mensajes = <String>[
    '¿Qué traes en el corazón hoy? Escríbelo aquí.',
    'Hay algo que no le has dicho a nadie. Puedes dejarlo acá.',
    '¿Qué quieres poner hoy en manos de Dios?',
    'Escribe eso que te está dando vueltas. Después se lo entregas.',
  ];

  late final String _mensaje = _mensajes[Random().nextInt(_mensajes.length)];
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const JournalScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        decoration: BoxDecoration(
          color: AppColors.amberLight.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.32)),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_note_rounded,
                size: 22, color: AppColors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _mensaje,
                style: AppTypography.body.copyWith(
                    fontSize: 13.5, height: 1.3, color: AppColors.tealDeep),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _visible = false),
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.inkSoft,
              visualDensity: VisualDensity.compact,
              tooltip: 'Cerrar',
            ),
          ],
        ),
      ),
    );
  }
}
