import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Estado real de la pausa.
///
/// Existe porque el servicio fallaba en silencio: si le faltaba un permiso o
/// el bucle moria, la app no decia nada y parecia rota. Aqui se ve en verde y
/// rojo que funciona y que no.
class DiagnosticoScreen extends StatefulWidget {
  const DiagnosticoScreen({super.key});

  @override
  State<DiagnosticoScreen> createState() => _DiagnosticoScreenState();
}

class _DiagnosticoScreenState extends State<DiagnosticoScreen> {
  static const _canal = MethodChannel('com.oraahora.app/gate');

  bool _cargando = true;
  bool _uso = false;
  bool _superposicion = false;
  bool _esMiui = false;
  bool? _miuiFondo;
  int _appsVigiladas = 0;
  String _latido = '—';
  String _deteccion = '—';
  String _salto = '—';
  String _lanzamiento = '—';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  String _hace(int? ms) {
    if (ms == null || ms == 0) return 'nunca';
    final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (d.inSeconds < 60) return 'hace ${d.inSeconds} s';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    return 'hace ${d.inDays} días';
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final p = await SharedPreferences.getInstance();
    await p.reload();
    bool uso = false, sup = false, miui = false;
    bool? miuiFondo;
    try {
      uso = await _canal.invokeMethod<bool>('hasUsageAccess') ?? false;
      sup = await _canal.invokeMethod<bool>('hasOverlayPermission') ?? false;
      miui = await _canal.invokeMethod<bool>('isMiuiDevice') ?? false;
      if (miui) {
        miuiFondo = await _canal.invokeMethod<bool>('isMiuiBackgroundStartAllowed');
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _uso = uso;
      _superposicion = sup;
      _esMiui = miui;
      _miuiFondo = miuiFondo;
      _appsVigiladas = (p.getStringList('gated_apps')?.length) ??
          ((p.getString('gated_apps')?.split('"').length ?? 1) ~/ 2);
      _latido = _hace(p.getInt('diag_latido_ts'));
      _deteccion = p.getString('diag_ultima_deteccion') == null
          ? 'nunca'
          : '${p.getString('diag_ultima_deteccion')} · ${_hace(p.getInt('diag_ultima_deteccion_ts'))}';
      _salto = p.getString('diag_ultimo_salto') == null
          ? '—'
          : '${p.getString('diag_ultimo_salto')} · ${_hace(p.getInt('diag_ultimo_salto_ts'))}';
      _lanzamiento = p.getString('diag_ultimo_lanzamiento') == null
          ? 'nunca'
          : '${p.getString('diag_ultimo_lanzamiento')} · ${_hace(p.getInt('diag_ultimo_lanzamiento_ts'))}';
    });
  }

  Widget _fila(String titulo, bool ok, {String? detalle, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(ok ? Icons.check_circle : Icons.cancel,
          color: ok ? Colors.green.shade600 : Colors.red.shade600),
      title: Text(titulo),
      subtitle: detalle == null ? null : Text(detalle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _dato(String titulo, String valor) =>
      ListTile(dense: true, title: Text(titulo), subtitle: Text(valor));

  @override
  Widget build(BuildContext context) {
    // El latido se escribe cada ~30 s: si hace mas de 3 min que no aparece,
    // el bucle de vigilancia esta muerto aunque la notificacion siga visible.
    final tsLatido = _latido;
    final vivo = tsLatido.contains(' s') ||
        (tsLatido.contains('min') &&
            (int.tryParse(tsLatido.replaceAll(RegExp(r'[^0-9]'), '')) ?? 99) < 3);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de la pausa'),
        actions: [
          IconButton(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar'),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Si algo está en rojo, la pausa no va a aparecer. '
                    'Toca la línea para ir al ajuste que falta.',
                  ),
                ),
                _fila('Vigilancia activa', vivo,
                    detalle: 'Última señal: $tsLatido'),
                _fila('Permiso de acceso a datos de uso', _uso,
                    detalle: _uso ? null : 'Sin esto no sabemos qué app abriste',
                    onTap: _uso
                        ? null
                        : () async {
                            await _canal.invokeMethod('openUsageAccessSettings');
                          }),
                _fila('Permiso para mostrarse sobre otras apps', _superposicion,
                    detalle: _superposicion
                        ? null
                        : 'Sin esto la pausa no se puede dibujar',
                    onTap: _superposicion
                        ? null
                        : () async {
                            await _canal.invokeMethod('openOverlaySettings');
                          }),
                if (_esMiui)
                  _fila('Xiaomi: abrir en segundo plano', _miuiFondo == true,
                      detalle: _miuiFondo == true
                          ? null
                          : 'En Xiaomi hay que activarlo aparte o la pausa nunca sale',
                      onTap: () async {
                        await _canal.invokeMethod('openMiuiOtherPermissions');
                      }),
                _fila('Apps vigiladas', _appsVigiladas > 0,
                    detalle: '$_appsVigiladas seleccionadas'),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('Últimos movimientos',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                _dato('Última app vigilada detectada', _deteccion),
                _dato('Último motivo por el que no se mostró', _salto),
                _dato('Último intento de abrir la pausa', _lanzamiento),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Para probar: abre una app vigilada, vuelve aqui y toca '
                    'actualizar. Si la deteccion cambia pero la pausa no salio, '
                    'el problema es al mostrarla, no al detectarla.',
                  ),
                ),
              ],
            ),
    );
  }
}
