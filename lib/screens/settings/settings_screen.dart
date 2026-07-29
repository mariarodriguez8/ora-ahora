import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/prefs_service.dart';
import '../../services/purchase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../onboarding/onboarding_welcome_screen.dart';
import '../paywall/paywall_screen.dart';
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
          _SettingsTile(
            icon: Icons.replay_outlined,
            title: 'Ver la introducción otra vez',
            subtitle: 'Repite el recorrido de bienvenida',
            onTap: () async {
              await context.read<PrefsService>().setOnboardingComplete(false);
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => const OnboardingWelcomeScreen()),
                (route) => false,
              );
            },
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

