import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Marcador de posición de la política de privacidad.
///
/// TODO: reemplazar este texto por el enlace/texto legal definitivo de la
/// política de privacidad publicada (requisito obligatorio de Play
/// Console antes de publicar, especialmente por usar el permiso de
/// Accesibilidad y por procesar datos dentro de la app).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de privacidad')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.amberLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Este texto es un marcador de posición para el MVP. '
                  'Antes de publicar en Google Play, reemplázalo con tu '
                  'política de privacidad real, publicada en una URL '
                  'pública (requisito obligatorio del formulario de '
                  'seguridad de datos de Play Console).',
                  style: AppTypography.caption,
                ),
              ),
              const SizedBox(height: 20),
              Text('Datos que maneja Ora Ahora', style: AppTypography.title),
              const SizedBox(height: 8),
              Text(
                'Ora Ahora guarda toda tu información (preferencias, racha, '
                'diario de oración y lista de apps con pausa) únicamente '
                'en tu propio dispositivo. La app no tiene servidor '
                'propio ni cuenta de usuario en esta versión, y no '
                'comparte tu información con terceros.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 16),
              Text('Permiso de Accesibilidad', style: AppTypography.title),
              const SizedBox(height: 8),
              Text(
                'Si activas "Pausa y Ora", Ora Ahora usa el permiso de '
                'Accesibilidad de Android exclusivamente para detectar '
                'qué app está abierta en primer plano, y así decidir si '
                'debe mostrarte la pantalla de pausa de oración. Este '
                'permiso no se usa para leer el contenido de otras apps.',
                style: AppTypography.body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
