import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/gate_service.dart';
import '../../services/purchase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../gate_explainer/gate_explainer_screen.dart';

/// Pantalla para elegir que apps instaladas requeriran una "Pausa y Ora"
/// antes de abrirse. La version gratuita permite 1 app; Ora Ahora Plus
/// permite apps ilimitadas.
///
/// v23: esta pantalla tambien se usa DENTRO del onboarding (justo despues
/// de conceder los permisos), porque nadie va a intuir que debe entrar a
/// Ajustes a elegir sus apps. Cuando se pasa [onboardingContinue], se
/// muestra una intro corta y un boton fijo "Continuar" abajo que avanza
/// el onboarding en vez de volver atras.
class GatedAppsScreen extends StatefulWidget {
  final VoidCallback? onboardingContinue;

  const GatedAppsScreen({super.key, this.onboardingContinue});

  @override
  State<GatedAppsScreen> createState() => _GatedAppsScreenState();
}

class _GatedAppsScreenState extends State<GatedAppsScreen> {
  static const _freeLimit = 1;

  late Future<List<Application>> _appsFuture;
  bool? _permissionsOk;

  bool get _onboarding => widget.onboardingContinue != null;

  @override
  void initState() {
    super.initState();
    _appsFuture = context.read<GateService>().installedLaunchableApps();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final gate = context.read<GateService>();
    final granted = await gate.hasAllGatePermissions();
    // En onboarding, si los permisos ya estan concedidos, encendemos la
    // Pausa y Ora automaticamente para que la persona solo tenga que
    // marcar sus apps (un paso menos).
    if (_onboarding && granted && !gate.gateEnabled) {
      await gate.setGateEnabled(true);
    }
    if (mounted) setState(() => _permissionsOk = granted);
  }

  int get _maxApps =>
      context.read<PurchaseService>().isPlusUser ? 999999 : _freeLimit;

  Future<void> _onMasterSwitch(bool value) async {
    final gate = context.read<GateService>();
    if (value && _permissionsOk != true) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const GateExplainerScreen()),
      );
      await _checkPermissions();
      if (result != true && _permissionsOk != true) {
        return; // el usuario no activo los permisos; no encendemos el switch
      }
    }
    await gate.setGateEnabled(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gate = context.watch<GateService>();
    final isPlus = context.watch<PurchaseService>().isPlusUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_onboarding ? 'Elige tus apps' : 'Pausa y Ora'),
        automaticallyImplyLeading: !_onboarding,
      ),
      bottomNavigationBar: _onboarding
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onboardingContinue,
                    child: const Text('Continuar 🙏'),
                  ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (_onboarding)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  'Elige qué apps te van a pedir una pausa para orar antes '
                  'de abrirlas (por ejemplo TikTok, Instagram o YouTube). '
                  'Podrás cambiarlas cuando quieras desde Ajustes.',
                  style: AppTypography.body.copyWith(color: AppColors.inkSoft),
                ),
              ),
            SwitchListTile(
              value: gate.gateEnabled,
              onChanged: _onMasterSwitch,
              title: const Text('Activar Pausa y Ora'),
              subtitle: const Text('Requiere dos permisos sencillos (te guiamos)'),
            ),
            if (!isPlus)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amberLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Plan gratuito: puedes elegir 1 app. Con Ora Ahora Plus '
                    'puedes bloquear todas las que quieras.',
                    style: AppTypography.caption,
                  ),
                ),
              ),
            const Divider(height: 24),
            Expanded(
              child: FutureBuilder<List<Application>>(
                future: _appsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final apps = snapshot.data!;
                  if (apps.isEmpty) {
                    // Caso extremo (casi nunca ocurre en un telefono real):
                    // sin apps instaladas que se puedan abrir. Estado vacio
                    // minimo (icono + texto centrado) en vez de una lista en
                    // blanco sin explicacion.
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.apps_outlined,
                              size: 48,
                              color: AppColors.inkSoft,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No encontramos apps instaladas para elegir.',
                              textAlign: TextAlign.center,
                              style: AppTypography.body.copyWith(color: AppColors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      final isGated = gate.isGated(app.packageName);
                      return ListTile(
                        leading: app is ApplicationWithIcon
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(app.icon,
                                    width: 36, height: 36),
                              )
                            : const Icon(Icons.apps),
                        title: Text(app.appName),
                        trailing: Switch(
                          value: isGated,
                          onChanged: (value) async {
                            if (value && !isGated && gate.gatedApps.length >= _maxApps) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Con el plan gratuito solo puedes elegir '
                                    '$_freeLimit app. Obtén Ora Ahora Plus '
                                    'para apps ilimitadas.',
                                  ),
                                ),
                              );
                              return;
                            }
                            await gate.toggleGatedApp(
                              app.packageName,
                              maxApps: _maxApps,
                            );
                            setState(() {});
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
