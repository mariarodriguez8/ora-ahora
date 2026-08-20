import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/cancion_semana.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Pantalla Premium "Canción de la semana": muestra la alabanza de esta
/// semana (rota sola cada semana) con un mensaje corto y un botón bonito
/// que abre el video oficial en YouTube. Nunca se muestra el enlace crudo.
class CancionSemanaScreen extends StatelessWidget {
  const CancionSemanaScreen({super.key});

  Future<void> _abrir(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir el enlace 😔')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = cancionDeLaSemana();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Canción de la semana'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              Center(
                child: Container(
                  width: 92,
                  height: 92,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.tealLight.withValues(alpha: 0.5),
                  ),
                  child: const Text('🎧', style: TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 18),
              Text('esta semana, escucha esto',
                  textAlign: TextAlign.center,
                  style:
                      AppTypography.caption.copyWith(color: AppColors.inkSoft)),
              const SizedBox(height: 6),
              Text(c.titulo,
                  textAlign: TextAlign.center,
                  style: AppTypography.display.copyWith(fontSize: 28)),
              const SizedBox(height: 4),
              Text(c.artista,
                  textAlign: TextAlign.center,
                  style: AppTypography.title
                      .copyWith(color: AppColors.tealDeep, fontSize: 17)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.tealLight),
                ),
                child: Text(
                  c.mensaje,
                  textAlign: TextAlign.center,
                  style: AppTypography.quote.copyWith(fontSize: 16, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _abrir(context, c.url),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealDeep,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  label: const Text('Escuchar 🎵'),
                ),
              ),
              const SizedBox(height: 10),
              Text('se abre en YouTube · una nueva cada semana',
                  textAlign: TextAlign.center,
                  style:
                      AppTypography.caption.copyWith(color: AppColors.inkSoft)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de entrada en el Inicio hacia la canción de la semana. Si la
/// persona no es Plus, [onTap] la lleva al paywall (feature Premium).
class CancionSemanaCard extends StatelessWidget {
  final bool isPlus;
  final VoidCallback onTap;

  const CancionSemanaCard({super.key, required this.isPlus, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = cancionDeLaSemana();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFB07A1E),
              AppColors.amber,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              child: const Text('🎧', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Canción de la semana',
                          style: AppTypography.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      if (!isPlus)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('Plus',
                              style: AppTypography.caption.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPlus
                        ? '${c.titulo} · ${c.artista}'
                        : 'una alabanza nueva cada semana',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption
                        .copyWith(color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
              const SizedBox(height: 12),
              Text(c.mensaje,
                  style: AppTypography.body.copyWith(
                      fontSize: 13,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.92))),
              if (isPlus) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Mientras la escuchas, ora:\n' + c.oracion,
                      style: AppTypography.body.copyWith(
                          fontSize: 12.5, height: 1.35, color: Colors.white)),
                ),
              ],
            ],
          ),
      ),
    );
  }
}
