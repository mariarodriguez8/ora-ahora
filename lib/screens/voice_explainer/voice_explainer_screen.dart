import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/prefs_service.dart';
import '../../services/voice_prayer_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Pantalla explicativa, obligatoria antes de pedir el permiso de
/// Microfono (`RECORD_AUDIO`) de Android, con el mismo espiritu de
/// "aviso previo claro" que `GateExplainerScreen` usa para el permiso de
/// Accesibilidad: se explica en español sencillo, ANTES de solicitarlo,
/// para que sirve el permiso y que NO se hace con el.
///
/// Devuelve (via `Navigator.pop`) `true` si la persona concedio el
/// permiso de microfono y quedo disponible el reconocimiento de voz en
/// este dispositivo, o `false`/`null` si no.
class VoiceExplainerScreen extends StatefulWidget {
  const VoiceExplainerScreen({super.key});

  @override
  State<VoiceExplainerScreen> createState() => _VoiceExplainerScreenState();
}

class _VoiceExplainerScreenState extends State<VoiceExplainerScreen> {
  final VoicePrayerService _voiceService = VoicePrayerService();

  bool _requesting = false;
  bool? _granted;

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);
    final granted = await _voiceService.checkAvailability();
    if (!mounted) return;
    if (granted) {
      await context.read<PrefsService>().setVoiceDisclosureSeen(true);
    }
    setState(() {
      _requesting = false;
      _granted = granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final granted = _granted;

    return Scaffold(
      appBar: AppBar(title: const Text('Detección por voz')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.mic_none, size: 48, color: AppColors.tealDeep),
                    const SizedBox(height: 20),
                    Text('¿Para qué se usa el micrófono?', style: AppTypography.headline),
                    const SizedBox(height: 12),
                    Text(
                      'Esta función, totalmente opcional, escucha mientras oras '
                      'en voz alta para confirmar que de verdad terminaste tu '
                      'oración, en vez de solo confiar en un toque de botón. '
                      'El micrófono solo se activa mientras tienes abierta una '
                      'oración y tocas "Escuchar mi oración": nunca escucha en '
                      'segundo plano ni fuera de esa pantalla.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Todo el procesamiento ocurre 100% en tu propio teléfono '
                      '(reconocimiento de voz "en el dispositivo" de Android). '
                      'Ora Ahora nunca graba, guarda ni sube tu audio a ningún '
                      'servidor: solo revisa, en el momento, si dijiste la '
                      'palabra "amén" o si llevas ya un buen rato hablando de '
                      'forma continua, para saber que terminaste.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Si tu teléfono no tiene descargado el reconocimiento de '
                      'voz en el dispositivo, esta función no estará disponible '
                      'y no se te volverá a preguntar: siempre podrás usar el '
                      'botón manual "Marcar como orada hoy" en su lugar.',
                      style: AppTypography.body.copyWith(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Puedes desactivar esta función en cualquier momento desde '
                      'Ajustes, y seguir usando Ora Ahora exactamente igual con '
                      'el botón manual.',
                      style: AppTypography.body.copyWith(color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  if (granted == true)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle, color: AppColors.success),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Permiso concedido y disponible en este teléfono.',
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (granted == false)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.amberLight.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'No se pudo activar el micrófono en este dispositivo '
                        '(puede que el permiso no se haya concedido, o que no '
                        'esté disponible el reconocimiento de voz local). No '
                        'te preocupes: puedes seguir usando el botón manual '
                        'para marcar tu oración.',
                        style: AppTypography.caption,
                      ),
                    ),
                  if (granted != true)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _requesting ? null : _requestPermission,
                        child: Text(
                          _requesting
                              ? 'Comprobando...'
                              : 'Entiendo, activar micrófono',
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(granted == true),
                    child: Text(granted == true ? 'Continuar' : 'Volver'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
