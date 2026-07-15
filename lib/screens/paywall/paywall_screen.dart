import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../services/purchase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Pantalla de paywall de Ora Ahora Plus.
///
/// Los precios mostrados ($4.99/mes y $39.99/año) son de ejemplo: se
/// deben configurar los productos y precios reales en Google Play
/// Console antes de publicar. Las compras se procesan a traves de
/// `PurchaseService`, que hoy es un stub (ver TODOs alli).
///
/// DISEÑO DEL PAYWALL (paywall "suave", no un patron oscuro):
/// - El plan Anual aparece preseleccionado por defecto (practica estandar
///   de la industria, no oculta el plan Mensual: ambos son visibles y
///   elegibles con un toque).
/// - El precio anual se muestra tambien como equivalente diario
///   ("$39.99 USD/año — equivale a $0.11 USD/día") para dar contexto de
///   valor real, sin ocultar el monto total.
/// - Debajo del boton principal se muestra siempre, de forma clara y
///   visible, "Cancela cuando quieras desde Google Play".
/// - Esta pantalla es una `Scaffold` normal con boton de "atras" del
///   `AppBar`/gesto del sistema: el usuario puede cerrarla en cualquier
///   momento sin ninguna interceptacion ni oferta forzada de reemplazo
///   (deliberadamente NO se implementa ningun "exit drawer" ni mecanismo
///   que intercepte el cierre o el boton atras para insistir con otra
///   oferta antes de dejar salir al usuario).
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  PlusPlan _selected = PlusPlan.anual;
  bool _loading = false;

  Future<void> _purchase() async {
    setState(() => _loading = true);
    final ok = await context.read<PurchaseService>().purchase(_selected);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Bienvenido a Ora Ahora Plus!')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    final restored = await context.read<PurchaseService>().restorePurchases();
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(restored
            ? 'Se restauró tu suscripción Plus.'
            : 'No se encontró ninguna suscripción activa.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPlus = context.watch<PurchaseService>().isPlusUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Ora Ahora Plus')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Ilustracion original de "destello premium" (ver
            // `assets/illustrations/paywall_hero.svg`) en reemplazo del
            // icono generico `Icons.workspace_premium`, como elemento
            // dominante de la pantalla.
            Center(
              child: SvgPicture.asset(
                'assets/illustrations/paywall_hero.svg',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'PLUS',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: AppColors.amber),
            ),
            const SizedBox(height: 8),
            Text(
              'Lleva tu vida de oración\nmás lejos',
              textAlign: TextAlign.center,
              style: AppTypography.display.copyWith(fontSize: 27),
            ),
            const SizedBox(height: 24),
            const _FeatureRow(
              icon: Icons.lock_open,
              title: 'Apps ilimitadas en Pausa y Ora',
              subtitle: 'El plan gratuito siempre incluye 1 app gratis',
            ),
            const _FeatureRow(
              icon: Icons.ac_unit,
              title: 'Fichas de congelación de racha',
              subtitle: '2 fichas al mes para proteger tu racha si un día se te pasa',
            ),
            const _FeatureRow(
              icon: Icons.headphones,
              title: 'Oraciones narradas en audio',
              subtitle: 'Próximamente',
            ),
            const _FeatureRow(
              icon: Icons.auto_stories,
              title: 'Paquetes de oración exclusivos',
              subtitle: 'Series temáticas para profundizar cada mes',
            ),
            const SizedBox(height: 24),
            if (isPlus)
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
                    Expanded(child: Text('Ya eres miembro de Ora Ahora Plus')),
                  ],
                ),
              )
            else ...[
              _PlanOption(
                plan: PlusPlan.anual,
                title: 'Anual',
                price: PurchaseService.precioAnual,
                priceSubtitle: PurchaseService.precioAnualDiario,
                badge: 'Ahorra más',
                selected: _selected == PlusPlan.anual,
                onTap: () => setState(() => _selected = PlusPlan.anual),
              ),
              const SizedBox(height: 12),
              _PlanOption(
                plan: PlusPlan.mensual,
                title: 'Mensual',
                price: PurchaseService.precioMensual,
                selected: _selected == PlusPlan.mensual,
                onTap: () => setState(() => _selected = PlusPlan.mensual),
              ),
              const SizedBox(height: 8),
              Text(
                'Precios de ejemplo. Los precios finales se configuran en '
                'Google Play Console y pueden variar según tu país.',
                style: AppTypography.caption.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _purchase,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Continuar'),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Cancela cuando quieras desde Google Play. Sin compromiso.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : _restore,
                  child: const Text('Restaurar compras'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.tealLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.tealDeep, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.title),
                Text(subtitle, style: AppTypography.body.copyWith(color: AppColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final PlusPlan plan;
  final String title;
  final String price;
  final String? priceSubtitle;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanOption({
    required this.plan,
    required this.title,
    required this.price,
    this.priceSubtitle,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.tealDeep : AppColors.tealLight,
            width: selected ? 2 : 1,
          ),
          color: selected ? AppColors.tealLight.withValues(alpha: 0.3) : null,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: AppColors.tealDeep,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Text(title, style: AppTypography.title),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge!,
                        style: AppTypography.caption.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: AppTypography.title),
                if (priceSubtitle != null)
                  Text(
                    priceSubtitle!,
                    style: AppTypography.caption.copyWith(color: AppColors.inkSoft),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
