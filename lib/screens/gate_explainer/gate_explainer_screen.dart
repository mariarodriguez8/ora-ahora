import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/gate_service.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Pantalla explicativa, obligatoria antes de pedir los permisos de
/// "Pausa y Ora", tal como exige la politica de Google Play: se debe
/// explicar con claridad, ANTES de solicitarlos, para que se usa cada
/// permiso.
///
/// v8: ya no se usa el permiso de Accesibilidad. Ahora son DOS permisos
/// estandar de bienestar digital, cada uno con su tarjeta, su estado en
/// vivo (activado / pendiente) y su boton que abre la pantalla exacta de
/// Ajustes:
///  1. "Acceso de uso": para saber que app abres (solo el nombre).
///  2. "Mostrar sobre otras apps": para poner la pausa de oracion encima.
class GateExplainerScreen extends StatefulWidget {
  const GateExplainerScreen({super.key});

  @override
  State<GateExplainerScreen> createState() => _GateExplainerScreenState();
}

class _GateExplainerScreenState extends State<GateExplainerScreen>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool? _usageGranted;
  bool? _overlayGranted;
  bool _isMiui = false;
  bool? _miuiGranted;
  bool _celebrated = false;

  // En MIUI el tercer permiso cuenta; si no se pudo comprobar (null),
  // no bloquea el "Continuar".
  bool get _allGranted =>
      (_usageGranted ?? false) &&
      (_overlayGranted ?? false) &&
      (!_isMiui || (_miuiGranted ?? true));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus().then((_) {
        if (mounted && _allGranted && !_celebrated) {
          _celebrated = true;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('¡Permisos activados! Pausa y Ora ya funciona ✅🙏'),
          ));
        }
      });
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _checking = true);
    final gate = context.read<GateService>();
    final usage = await gate.hasUsageAccess();
    final overlay = await gate.hasOverlayPermission();
    final isMiui = await gate.isMiuiDevice();
    final miui = isMiui ? await gate.isMiuiBackgroundStartAllowed() : null;
    if (!mounted) return;
    setState(() {
      _usageGranted = usage;
      _overlayGranted = overlay;
      _isMiui = isMiui;
      _miuiGranted = miui;
      _checking = false;
    });
    if (usage && overlay) {
      // Si el interruptor ya estaba encendido, arranca el detector ya.
      await gate.syncNativeService();
    }
  }

  Future<void> _markSeenAnd(Future<void> Function() abrir) async {
    final prefs = context.read<PrefsService>();
    await prefs.setAccessibilityExplainerSeen(true);
    await abrir();
  }

  @override
  Widget build(BuildContext context) {
    final gate = context.read<GateService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Permisos de Pausa y Ora')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset('assets/mascot/ovejita.png',
                          height: 110),
                    ),
                    const SizedBox(height: 20),
                    Text('Activa Pausa y Ora',
                        style: AppTypography.headline),
                    const SizedBox(height: 12),
                    Text(
                      'Activa estos permisos para que Pausa y Ora funcione. '
                      'Toca cada botón y te llevamos al lugar exacto.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Solo vemos el nombre de la app que abres. Nada sale de '
                      'tu teléfono.',
                      style:
                          AppTypography.body.copyWith(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 20),
                    _PermisoCard(
                      numero: '1',
                      titulo: 'Acceso de uso',
                      descripcion: 'Para saber cuándo mostrarte la pausa.',
                      granted: _usageGranted,
                      botonTexto: 'Abrir ajustes',
                      instruccion: 'Activa el interruptor de Ora Ahora.',
                      onPressed: () =>
                          _markSeenAnd(gate.openUsageAccessSettings),
                    ),
                    const SizedBox(height: 14),
                    _PermisoCard(
                      numero: '2',
                      titulo: 'Mostrar sobre otras apps',
                      descripcion: 'Para que la pausa aparezca encima.',
                      granted: _overlayGranted,
                      botonTexto: 'Abrir ajustes',
                      instruccion: 'Busca Ora Ahora y enciende el permiso.',
                      onPressed: () => _markSeenAnd(gate.openOverlaySettings),
                    ),
                    if (_isMiui) ...[
                      const SizedBox(height: 14),
                      _PermisoCard(
                        numero: '3',
                        titulo: 'Xiaomi: ventanas en segundo plano',
                        descripcion:
                            'Tu teléfono Xiaomi pide un permiso extra.',
                        granted: _miuiGranted,
                        botonTexto: 'Abrir ajustes',
                        instruccion:
                            'Enciende "Mostrar ventanas emergentes en '
                            'segundo plano".',
                        onPressed: () =>
                            _markSeenAnd(gate.openMiuiOtherPermissions),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Puedes apagar estos permisos cuando quieras desde el '
                      'mismo lugar, y "Pausa y Ora" se detendrá de inmediato. '
                      'Si te pierdes, vuelve aquí y empieza de nuevo: no pasa '
                      'nada 😊.',
                      style:
                          AppTypography.body.copyWith(color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  if (_allGranted)
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
                                'Los dos permisos están activos. ¡Gracias!'),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _checking
                            ? null
                            : () async {
                                await _refreshStatus();
                                if (!context.mounted) return;
                                if (_allGranted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text(
                                        '¡Permisos detectados! Pausa y Ora está activa ✅🙏'),
                                  ));
                                  Navigator.of(context).pop(true);
                                } else {
                                  final pendientes = <String>[
                                    if (!(_usageGranted ?? false))
                                      '1: "Acceso de uso"',
                                    if (!(_overlayGranted ?? false))
                                      '2: "Mostrar sobre otras apps"',
                                    if (_isMiui && _miuiGranted == false)
                                      '3: "Ventanas en segundo plano"',
                                  ];
                                  final falta = pendientes.length == 1
                                      ? 'el permiso ${pendientes.first}'
                                      : 'los permisos ${pendientes.join(' y ')}';
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        'Aún falta $falta 🤔 Usa el botón de '
                                        'esa tarjeta y enciende el interruptor '
                                        'de Ora Ahora.'),
                                  ));
                                }
                              },
                        child: Text(_checking
                            ? 'Comprobando...'
                            : 'Ya activé los permisos'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_allGranted),
                    child: Text(_allGranted ? 'Continuar' : 'Volver'),
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

class _PermisoCard extends StatelessWidget {
  final String numero;
  final String titulo;
  final String descripcion;
  final String instruccion;
  final String botonTexto;
  final bool? granted;
  final VoidCallback onPressed;

  const _PermisoCard({
    required this.numero,
    required this.titulo,
    required this.descripcion,
    required this.instruccion,
    required this.botonTexto,
    required this.granted,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final activo = granted ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: activo ? AppColors.success : AppColors.tealLight,
          width: activo ? 1.6 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: activo ? AppColors.success : AppColors.tealDeep,
                  shape: BoxShape.circle,
                ),
                child: activo
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(numero,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        )),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(titulo, style: AppTypography.title)),
              if (activo)
                Text('Activado ✅',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 8),
          Text(descripcion, style: AppTypography.body),
          if (!activo) ...[
            const SizedBox(height: 8),
            Text(instruccion,
                style: AppTypography.body
                    .copyWith(fontSize: 13.5, color: AppColors.inkSoft)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(botonTexto),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
