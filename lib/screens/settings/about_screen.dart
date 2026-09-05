import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de Ora Ahora')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.self_improvement, size: 48, color: AppColors.tealDeep),
              const SizedBox(height: 16),
              Text('Ora Ahora', style: AppTypography.headline),
              const SizedBox(height: 4),
              Text('Versión 1.0.0', style: AppTypography.caption.copyWith(color: AppColors.inkSoft)),
              const SizedBox(height: 20),
              Text(
                'Ora Ahora es una app de oración cristiana interdenominacional '
                'en español, pensada para cualquier persona que quiera '
                'orar más, sin importar su tradición o iglesia. Nuestro '
                'contenido se basa en las Escrituras y evita elementos '
                'específicos de una sola denominación, para que cualquiera '
                'se sienta en casa.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 14),
              Text(
                'Además de oraciones diarias y un diario personal, Ora Ahora '
                'incluye "Pausa y Ora": una forma distinta de cuidar tu '
                'tiempo en pantalla, invitándote a una breve pausa de '
                'oración antes de abrir las apps que más te distraen, en '
                'lugar de simplemente bloquearlas.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 24),
              Text(
                'Hecha con cariño para acompañar tu vida de oración.',
                style: AppTypography.body.copyWith(
                  color: AppColors.inkSoft,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
