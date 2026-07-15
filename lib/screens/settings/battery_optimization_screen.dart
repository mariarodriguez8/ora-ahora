import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/gate_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Pantalla que explica, en español sencillo, por qué conviene excluir a
/// Ora Ahora de la optimización de batería de Android, y da acceso directo
/// al diálogo nativo para hacerlo
/// (`Intent.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`).
///
/// Esto complementa (no reemplaza) al foreground service nativo
/// (`PrayerGateForegroundService.kt`): ambos existen para reducir el
/// riesgo de que Android silencie `PrayerGateForegroundService` en
/// segundo plano, especialmente en fabricantes con gestión agresiva de
/// batería (Xiaomi, Samsung, Huawei, etc.).
class BatteryOptimizationScreen extends StatefulWidget {
  const BatteryOptimizationScreen({super.key});

  @override
  State<BatteryOptimizationScreen> createState() => _BatteryOptimizationScreenState();
}

class _BatteryOptimizationScreenState extends State<BatteryOptimizationScreen>
    with WidgetsBindingObserver {
  bool? _ignoring;

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
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    final gate = context.read<GateService>();
    final ignoring = await gate.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() => _ignoring = ignoring);
  }

  @override
  Widget build(BuildContext context) {
    final ignoring = _ignoring ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Optimización de batería')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.battery_saver_outlined, size: 48, color: AppColors.tealDeep),
            const SizedBox(height: 20),
            Text('¿Por qué importa esto?', style: AppTypography.headline),
            const SizedBox(height: 12),
            Text(
              'Algunos fabricantes de teléfonos (Xiaomi, Samsung, Huawei y '
              'otros) aplican una gestión de batería muy agresiva que puede '
              'apagar en silencio el servicio que detecta cuándo abres una '
              'app marcada para "Pausa y Ora", sin avisarte. Si eso pasa, '
              'dejarías de ver la pausa de oración sin darte cuenta.',
              style: AppTypography.body,
            ),
            const SizedBox(height: 14),
            Text(
              'Al excluir a Ora Ahora de la optimización de batería, le pides '
              'a Android que no apague esta función en segundo plano. Esto '
              'no consume batería adicional de forma relevante: Ora Ahora no '
              'hace ningún trabajo salvo cuando abres una app marcada.',
              style: AppTypography.body.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 28),
            if (ignoring)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ora Ahora ya está excluida de la optimización de batería. ¡Gracias!',
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final gate = context.read<GateService>();
                    await gate.requestIgnoreBatteryOptimizations();
                    await _refreshStatus();
                  },
                  child: const Text('Permitir que Ora Ahora se ejecute sin restricciones'),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _refreshStatus,
                child: const Text('Comprobar de nuevo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
