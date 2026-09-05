import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Aviso que aparece en el inicio cuando la pausa dejo de funcionar.
///
/// En Xiaomi (MIUI) el sistema mata la app en segundo plano y revoca de hecho
/// el arranque automatico. La persona cree que esta protegida, abre TikTok,
/// no pasa nada y concluye que la app no sirve. Este aviso hace visible el
/// problema y lo arregla en un toque.
///
/// Si todo esta correcto no ocupa espacio: devuelve un widget vacio.
class AvisoPausa extends StatefulWidget {
  const AvisoPausa({super.key});

  @override
  State<AvisoPausa> createState() => _AvisoPausaState();
}

class _AvisoPausaState extends State<AvisoPausa> with WidgetsBindingObserver {
  static const _canal = MethodChannel('com.oraahora.app/gate');

  bool _uso = true;
  bool _superposicion = true;
  bool _miuiFondo = true;
  bool _revisado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _revisar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Al volver de ajustes hay que comprobar de nuevo: puede que ya lo arreglara.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _revisar();
  }

  Future<void> _revisar() async {
    bool uso = true, sup = true, fondo = true;
    try {
      uso = await _canal.invokeMethod<bool>('hasUsageAccess') ?? true;
      sup = await _canal.invokeMethod<bool>('hasOverlayPermission') ?? true;
      final miui = await _canal.invokeMethod<bool>('isMiuiDevice') ?? false;
      if (miui) {
        // En MIUI este permiso no existe en Android estandar y
        // canDrawOverlays() no lo detecta: hay que preguntarlo aparte.
        fondo = await _canal.invokeMethod<bool>('isMiuiBackgroundStartAllowed')
            ?? true;
      }
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _uso = uso;
      _superposicion = sup;
      _miuiFondo = fondo;
      _revisado = true;
    });
  }

  bool get _todoBien => _uso && _superposicion && _miuiFondo;

  String get _texto {
    if (!_uso) return 'Ora Ahora no puede ver qué app abres.';
    if (!_superposicion) return 'Ora Ahora no puede mostrarte la oración.';
    return 'Tu teléfono está bloqueando la pausa.';
  }

  Future<void> _arreglar() async {
    try {
      if (!_uso) {
        await _canal.invokeMethod('openUsageAccessSettings');
      } else if (!_superposicion) {
        await _canal.invokeMethod('openOverlaySettings');
      } else {
        await _canal.invokeMethod('openMiuiOtherPermissions');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_revisado || _todoBien) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_off_rounded,
              size: 20, color: AppColors.amber),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('La pausa está apagada',
                    style: AppTypography.title.copyWith(
                      fontSize: 15,
                      color: AppColors.ink,
                    )),
                const SizedBox(height: 3),
                Text(_texto,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSoft,
                      height: 1.3,
                    )),
                const SizedBox(height: 9),
                GestureDetector(
                  onTap: _arreglar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.tealDeep,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('Reactivar',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
