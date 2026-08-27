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

  static const List<(String, String)> _dias = [
    ('Día 1 · Rompes el silencio',
        'hoy oras antes de abrir el celu. la tierra vuelve a sentir agua.'),
    ('Día 2 · El día que vas a querer rendirte',
        'Hoy vas a querer volver al celular. Ahí es donde se gana.'),
    ('Día 3 · Le entregas lo que más te duele',
        'le entregas eso que vienes cargando solo.'),
    ('Día 4 · Te sale solo, sin recordatorio',
        'dejas de sentirte tan lejos. vuelve la sensación de que Él está.'),
    ('Día 5 · Relees tu diario y ves lo que Dios hizo',
        'Cinco días seguidos escritos. Dios sí estaba ahí.'),
    ('Día 6 · El celular deja de mandarte',
        'tu racha ya no es número, es raíz que agarra.'),
    ('Día 7 · Ya no es un plan, es tu vida',
        'una semana regando sin fallar. ¿hace cuánto no lo lograbas?'),
  ];

  String _notaPrecio() {
    switch (_plan) {
      case PlusPlan.anual:
        return '3 días gratis, después ${PurchaseService.precioAnual}';
      case PlusPlan.semanal:
        return 'Se cobra ${PurchaseService.precioSemanal}';
      default:
        return '3 días gratis, después ${PurchaseService.precioMensual}';
    }
  }

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
            Text('Dios no se movió.',
                textAlign: TextAlign.center,
                style: AppTypography.display.copyWith(fontSize: 26)),
            const SizedBox(height: 6),
            Text('Te alejaste tú.',
                textAlign: TextAlign.center,
                style: AppTypography.title.copyWith(color: AppColors.tealDeep)),
            const SizedBox(height: 12),
            Text(
              'Y aun así sigue esperándote en el mismo lugar. '
              'No necesitas llegar perfecto ni ponerte al día. '
              'Solo volver a Él. Y llegó el momento.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < _dias.length; i++) ...[
              _DiaCard(numero: i + 1, titulo: _dias[i].$1, texto: _dias[i].$2),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tealLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('ya no estás en sequía.',
                      textAlign: TextAlign.center,
                      style: AppTypography.title
                          .copyWith(color: AppColors.tealDeep)),
                  const SizedBox(height: 4),
                  Text(
                    'ahora esto se vuelve tu vida, no una tarea.',
                    textAlign: TextAlign.center,
                    style:
                        AppTypography.body.copyWith(color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('elige tu plan',
                textAlign: TextAlign.center,
                style: AppTypography.title.copyWith(color: AppColors.ink)),
            const SizedBox(height: 12),
            _PlanCard(
              seleccionado: _plan == PlusPlan.anual,
              titulo: 'Anual',
              precio: PurchaseService.precioAnual,
              subtitulo: PurchaseService.precioAnualEquiv,
              badge: 'MÁS POPULAR',
              onTap: () => setState(() => _plan = PlusPlan.anual),
            ),
            const SizedBox(height: 10),
            _PlanCard(
              seleccionado: _plan == PlusPlan.mensual,
              titulo: 'Mensual',
              precio: PurchaseService.precioMensual,
              subtitulo: '3 días gratis',
              onTap: () => setState(() => _plan = PlusPlan.mensual),
            ),
            const SizedBox(height: 10),
            _PlanCard(
              seleccionado: _plan == PlusPlan.semanal,
              titulo: 'Semanal',
              precio: PurchaseService.precioSemanal,
              subtitulo: 'para probar',
              onTap: () => setState(() => _plan = PlusPlan.semanal),
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
                    : const Text('empezar a reverdecer 🌱'),
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
