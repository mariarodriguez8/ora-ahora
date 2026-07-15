import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/gate_service.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Pantalla explicativa, obligatoria antes de pedir el permiso de
/// Accesibilidad de Android, tal como exige la politica de Google Play
/// para apps que usan la API de Accesibilidad: se debe explicar con
/// claridad, ANTES de solicitarlo, para que se usa el permiso.
///
/// Aqui se explica en español sencillo por que Ora Ahora necesita este
/// permiso especifico (detectar cuando el usuario abre una app marcada
/// para "Pausa y Ora"), y que NO se usa para leer contenido de otras apps,
/// contraseñas ni datos personales.
class GateExplainerScreen extends StatefulWidget {
  const GateExplainerScreen({super.key});

  @override
  State<GateExplainerScreen> createState() => _GateExplainerScreenState();
}

class _GateExplainerScreenState extends State<GateExplainerScreen>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool? _enabled;

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
        if (mounted && (_enabled ?? false)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('¡Permiso activado! Pausa y Ora ya funciona ✅🙏'),
          ));
        }
      });
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _checking = true);
    final gate = context.read<GateService>();
    final enabled = await gate.isAccessibilityServiceEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Permiso de Accesibilidad')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.accessibility_new,
                        size: 48, color: AppColors.tealDeep),
                    const SizedBox(height: 20),
                    Text('¿Para qué se usa este permiso?',
                        style: AppTypography.headline),
                    const SizedBox(height: 12),
                    Text(
                      'La función "Pausa y Ora" necesita el permiso de '
                      'Accesibilidad de Android para detectar en qué momento '
                      'abres una de las apps que tú mismo elegiste para pausar '
                      '(por ejemplo, Instagram o TikTok).',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Con este permiso, Ora Ahora solo puede ver el nombre de '
                      'la app que está al frente en tu pantalla en ese instante, '
                      'para decidir si debe mostrarte la pausa de oración. '
                      'Ora Ahora NO lee contraseñas, mensajes, fotos, ni ningún '
                      'otro contenido de tus otras apps, y no envía esa '
                      'información a ningún servidor: todo se procesa en tu '
                      'propio teléfono.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 18),
                    Text('Cómo activarlo, paso a paso 👇',
                        style: AppTypography.title),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.tealLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _PasoNum(n: '1',
                              texto: 'Toca el botón verde de abajo. Se abrirá '
                                  'la pantalla de Accesibilidad de tu teléfono '
                                  '(en muchos celulares, Ora Ahora ya aparece '
                                  'resaltado).'),
                          _PasoNum(n: '2',
                              texto: 'Si no lo ves de una vez, busca una lista '
                                  'que puede llamarse "Apps instaladas", "Apps '
                                  'descargadas" o "Servicios instalados" — ahí '
                                  'está Ora Ahora 🙏.'),
                          _PasoNum(n: '3',
                              texto: 'Toca "Ora Ahora", enciende el '
                                  'interruptor y confirma con "Permitir" o '
                                  '"Aceptar".'),
                          _PasoNum(n: '4',
                              texto: 'Vuelve aquí con el botón de atrás. '
                                  'Nosotros comprobamos el resto ✅.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.amberLight.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '⚠️ ¿Te aparece "Configuración restringida"?\n'
                        'Es normal si instalaste la app por archivo APK. '
                        'Solución: Ajustes → Aplicaciones → Ora Ahora → '
                        'menú de 3 puntos (⋮) arriba a la derecha → '
                        '"Permitir configuración restringida" (pide tu '
                        'PIN) → vuelve a intentarlo.',
                        style: AppTypography.body.copyWith(fontSize: 13.5),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Puedes desactivar este permiso cuando quieras desde el '
                      'mismo lugar, y "Pausa y Ora" se apagará de inmediato. '
                      'Si te pierdes, vuelve aquí y empieza de nuevo: no pasa '
                      'nada 😊.',
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
                  if (enabled)
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
                            child: Text('El permiso ya está activo. ¡Gracias!'),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = context.read<PrefsService>();
                          await prefs.setAccessibilityExplainerSeen(true);
                          final gate = context.read<GateService>();
                          await gate.openAccessibilitySettings();
                        },
                        child: const Text('Ir a Ajustes de Accesibilidad'),
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _checking
                          ? null
                          : () async {
                              await _refreshStatus();
                              if (!context.mounted) return;
                              if (_enabled ?? false) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content: Text(
                                      '¡Permiso detectado! Pausa y Ora está activo ✅🙏'),
                                ));
                                Navigator.of(context).pop(true);
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content: Text(
                                      'Aún no lo detecto 🤔 Asegúrate de ENCENDER el interruptor de "Ora Ahora" dentro de Accesibilidad y vuelve a tocar aquí.'),
                                ));
                              }
                            },
                      child: Text(
                          _checking ? 'Comprobando...' : 'Ya activé el permiso'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(enabled),
                    child: const Text('Volver'),
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

class _PasoNum extends StatelessWidget {
  final String n;
  final String texto;
  const _PasoNum({required this.n, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.tealDeep,
              shape: BoxShape.circle,
            ),
            child: Text(n,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto, style: AppTypography.body),
          ),
        ],
      ),
    );
  }
}
