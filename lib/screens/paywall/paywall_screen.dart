import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/purchase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Paywall "el viaje de 7 días para reverdecer" (v26).
///
/// Concepto Sequía → Avivamiento: no vende funciones, vende "volver a Dios".
/// Desarma la objeción #1 del ICP ("me falta disciplina"), le hace pre-vivir
/// la transformación día a día, y ancla todo en gracia. La prueba real es de
/// 3 días gratis y luego el plan mensual (el "viaje de 7 días" es la historia
/// de la primera semana, no el tiempo de prueba).
///
/// IMPORTANTE: `PurchaseService.purchase` es todavía un stub (no cobra de
/// verdad). Ver el documento de estrategia para los pasos de RevenueCat /
/// Play Billing que faltan para cobrar.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _loading = false;
  PlusPlan _plan = PlusPlan.anual;

  /// Solo lo que la app hace hoy. No se agregan beneficios inexistentes.
  static const List<String> _beneficios = [
    'Una pausa antes de entrar a las aplicaciones que te distraen',
    'Una oración para lo que estás viviendo',
    'Tu camino de 30 días',
    'Una forma de ver cuánto tiempo estás dando a Dios',
  ];

  String _notaPrecio() => '3 días gratis. Después \$19.99/año.';

  Future<void> _empezar() async {
    setState(() => _loading = true);
    final ok = await context
        .read<PurchaseService>()
        .purchase(_plan);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Empezaste tu viaje! 🌱')),
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
            ? 'Se restauró tu suscripción.'
            : 'No se encontró ninguna suscripción activa.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(backgroundColor: AppColors.cream, elevation: 0),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Center(
              child: Image.asset('assets/mascot/ovejita_planta_fruto.png',
                  height: 130, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            // Reframe: desarma "me falta disciplina".
            Text(
              'Ya diste el primer paso para volver a Dios.',
              textAlign: TextAlign.center,
              style: AppTypography.display.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 16),
            Text('A partir de hoy tendrás:',
                textAlign: TextAlign.center,
                style: AppTypography.body
                    .copyWith(color: AppColors.inkSoft)),
            const SizedBox(height: 12),
            for (final b in _beneficios) ...[
              _Beneficio(texto: b),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 14),
            Text(
              'Dale a Dios un minuto de tu día.',
              textAlign: TextAlign.center,
              style: AppTypography.title
                  .copyWith(color: AppColors.tealDeep),
            ),
            const SizedBox(height: 22),
            Text('elige tu plan',
                textAlign: TextAlign.center,
                style: AppTypography.title.copyWith(color: AppColors.ink)),
            const SizedBox(height: 12),
            _PlanCard(
              seleccionado: _plan == PlusPlan.anual,
              titulo: '\$19.99 / año',
              precio: PurchaseService.precioAnual,
              subtitulo: PurchaseService.precioAnualEquiv,
              badge: 'Plan recomendado',
              onTap: () => setState(() => _plan = PlusPlan.anual),
            ),
            const SizedBox(height: 10),
            _PlanCard(
              seleccionado: _plan == PlusPlan.mensual,
              titulo: '\$2.99 / mes',
              precio: PurchaseService.precioMensual,
              subtitulo: '',
              onTap: () => setState(() => _plan = PlusPlan.mensual),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _empezar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealDeep,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Empezar mis 3 días gratis'),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _notaPrecio(),
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                    color: AppColors.inkSoft, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text('cancelas cuando quieras desde Google Play',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.inkSoft)),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: _loading ? null : _restore,
                child: const Text('Restaurar compras'),
              ),
            ),
            Text(
              'Precios de ejemplo. Los precios finales se configuran en '
              'Google Play Console y pueden variar según tu país.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una linea de beneficio con su palomita.
class _Beneficio extends StatelessWidget {
  final String texto;
  const _Beneficio({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.check_rounded,
              size: 18, color: AppColors.tealDeep),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(texto,
              style: AppTypography.body.copyWith(height: 1.35)),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final bool seleccionado;
  final String titulo;
  final String precio;
  final String subtitulo;
  final String? badge;
  final VoidCallback onTap;

  const _PlanCard({
    required this.seleccionado,
    required this.titulo,
    required this.precio,
    required this.subtitulo,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: seleccionado
              ? AppColors.tealLight.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? AppColors.tealDeep : AppColors.tealLight,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              seleccionado
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: seleccionado ? AppColors.tealDeep : AppColors.inkSoft,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(titulo,
                          style: AppTypography.body
                              .copyWith(fontWeight: FontWeight.w700)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.amber,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(badge!,
                              style: AppTypography.caption.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitulo,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.inkSoft)),
                ],
              ),
            ),
            Text(precio,
                style: AppTypography.body.copyWith(
                    color: AppColors.tealDeep, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _DiaCard extends StatelessWidget {
  final int numero;
  final String titulo;
  final String texto;

  const _DiaCard(
      {required this.numero, required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tealLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.tealLight,
              shape: BoxShape.circle,
            ),
            child: Text('$numero',
                style: AppTypography.body.copyWith(
                    color: AppColors.tealDeep, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: AppTypography.body
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(texto,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
