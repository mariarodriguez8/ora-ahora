import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/prefs_service.dart';
import '../../services/purchase_service.dart';
import '../../services/voice_prayer_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../paywall/paywall_screen.dart';
import '../voice_explainer/voice_explainer_screen.dart';
import 'about_screen.dart';
import 'appearance_screen.dart';
import 'battery_optimization_screen.dart';
import 'categories_screen.dart';
import 'gated_apps_screen.dart';
import 'privacy_screen.dart';
import 'reminders_screen.dart';

/// Pantalla de Ajustes: punto de entrada a recordatorios, "Pausa y Ora",
/// intereses, plan Plus, privacidad y acerca de. v11c: la ovejita
/// acompana tambien esta pantalla desde el encabezado.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPlus = context.watch<PurchaseService>().isPlusUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/mascot/ovejita.png',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text('Ajustes'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SectionLabel('Tu experiencia'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Recordatorios diarios',
            subtitle: 'Elige hasta 3 horarios para recibir avisos',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RemindersScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.favorite_outline,
            title: 'Mis intereses',
            subtitle: 'Personaliza las categorías de tu inicio',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Apariencia',
            subtitle: 'Paleta de color y Modo Simple',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppearanceScreen()),
            ),
          ),
          const Divider(height: 32),
          _SectionLabel('Pausa y Ora'),
          _SettingsTile(
            icon: Icons.lock_clock_outlined,
            title: 'Apps con pausa de oración',
            subtitle: 'Elige qué apps requieren una pausa antes de abrirse',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GatedAppsScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.battery_saver_outlined,
            title: 'Optimización de batería',
            subtitle: 'Evita que Android silencie la Pausa y Ora',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BatteryOptimizationScreen()),
            ),
          ),
          const Divider(height: 32),
          _SectionLabel('Voz'),
          const _VoiceDetectionTile(),
          const Divider(height: 32),
          _SectionLabel('Tu cuenta'),
          _SettingsTile(
            icon: Icons.workspace_premium_outlined,
            title: isPlus ? 'Eres miembro Ora Ahora Plus' : 'Obtener Ora Ahora Plus',
            subtitle: isPlus
                ? 'Gracias por apoyar Ora Ahora'
                : 'Apps ilimitadas en Pausa y Ora, y más',
            iconColor: AppColors.amber,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
          ),
          const Divider(height: 32),
          _SectionLabel('Información'),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Política de privacidad',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Acerca de Ora Ahora',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: AppColors.inkSoft,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.tealDeep;
    return ListTile(
      // Icono dentro de un circulo tonal (en vez de un icono "suelto"),
      // para que cada fila de Ajustes se sienta como una fila consistente
      // de una app pulida, no una lista generica de texto.
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.caption.copyWith(color: AppColors.inkSoft),
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Interruptor (opt-in, apagado por defecto) de la deteccion automatica
/// de fin de oracion por voz (ver `VoicePrayerService`, `PrayerDetailScreen`
/// y `VoiceExplainerScreen`).
///
/// Comprueba la disponibilidad de reconocimiento de voz en este telefono
/// UNA sola vez al abrir Ajustes: si no hay reconocimiento disponible en
/// este dispositivo, el interruptor se muestra deshabilitado (gris) con
/// el subtitulo "No disponible en este dispositivo", sin dialogos de
/// error ni insistencia, tal como pide el diseño de la función.
class _VoiceDetectionTile extends StatefulWidget {
  const _VoiceDetectionTile();

  @override
  State<_VoiceDetectionTile> createState() => _VoiceDetectionTileState();
}

class _VoiceDetectionTileState extends State<_VoiceDetectionTile> {
  final VoicePrayerService _voiceService = VoicePrayerService();

  bool _checkingAvailability = true;
  bool _available = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _voiceService.checkAvailability();
    if (!mounted) return;
    setState(() {
      _available = available;
      _checkingAvailability = false;
    });
  }

  Future<void> _onChanged(bool value) async {
    final prefs = context.read<PrefsService>();

    if (!value) {
      await prefs.setVoiceDetectionEnabled(false);
      setState(() {});
      return;
    }

    if (!_available) return; // el interruptor deberia estar deshabilitado

    if (!prefs.voiceDisclosureSeen) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const VoiceExplainerScreen()),
      );
      if (result != true) return;
    } else {
      // Ya se vio el aviso antes, pero el permiso de microfono pudo
      // haberse revocado manualmente desde los ajustes del sistema desde
      // entonces: se vuelve a comprobar sin mostrar la pantalla de aviso
      // de nuevo (ya se explico una vez), y simplemente no se activa el
      // interruptor si ya no esta disponible.
      final granted = await _voiceService.checkAvailability();
      if (!granted) return;
    }

    await prefs.setVoiceDetectionEnabled(true);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PrefsService>();
    final enabled = prefs.voiceDetectionEnabled;

    final voiceColor = _available ? AppColors.tealDeep : AppColors.inkSoft;
    return SwitchListTile(
      secondary: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: voiceColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.mic_none, color: voiceColor, size: 20),
      ),
      value: enabled && _available,
      onChanged: _checkingAvailability || !_available ? null : _onChanged,
      title: const Text('Detectar cuando termino de orar (con micrófono)'),
      subtitle: Text(
        _checkingAvailability
            ? 'Comprobando disponibilidad...'
            : _available
                ? 'Opcional. Escucha en tu propio teléfono para confirmar tu '
                    'oración; nunca se envía a un servidor.'
                : 'No disponible en este dispositivo',
      ),
    );
  }
}
