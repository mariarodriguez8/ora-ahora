import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/purchase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Paywall de Ora Ahora.
///
/// No vende funciones: vende volver a Dios. La prueba de 3 dias pertenece
/// UNICAMENTE al plan anual, por eso vive dentro de la tarjeta anual y no
/// debajo de las dos tarjetas.
///
/// La compra se resuelve siempre contra RevenueCat (entitlement ora_ahora_pro).
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _loading = false;
  bool _avisar = true;
  PlusPlan _plan = PlusPlan.anual;

  bool get _esAnual => _plan == PlusPlan.anual;

  /// Solo lo que la app hace hoy. No se agregan beneficios inexistentes.
  static const List<String> _beneficios = [
    'Una pausa antes de entrar a las aplicaciones que te distraen',
    'Una oración para lo que estás viviendo',
    'Tu camino de 30 días',
    'Una forma de ver cuánto tiempo estás dando a Dios',
  ];

  String get _textoCta =>
      _esAnual ? 'Reclama tus 3 días' : 'Suscribirme por \$2.99/mes';

  String get _notaCta => _esAnual
      ? 'Tres días gratis. Después \$19.99/año.'
      : 'Se renueva cada mes. Sin permanencia.';

  Future<void> _empezar() async {
    setState(() => _loading = true);
    final r = await context.read<PurchaseService>().purchase(_plan);
    if (!mounted) return;
    setState(() => _loading = false);

    // El acceso solo se concede si RevenueCat confirmo el entitlement.
    if (r == ResultadoCompra.exito || r == ResultadoCompra.yaSuscrito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listo. Que Dios te acompañe.')),
      );
      Navigator.of(context).pop();
      return;
    }

    final mensaje = switch (r) {
      ResultadoCompra.cancelada => 'No se completó la compra.',
      ResultadoCompra.productoNoDisponible =>
        'Los planes todavía no están disponibles. Intenta más tarde.',
      ResultadoCompra.sinRed => 'Revisa tu conexión e intenta de nuevo.',
      _ => 'No pudimos completar la compra. Intenta de nuevo.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            Center(
              child: Image.asset('assets/mascot/ovejita_planta_fruto.png',
                  height: 116, fit: BoxFit.contain),
            ),
            const SizedBox(height: 10),
            Text(
              'Ya diste el primer paso para volver a Dios.',
              textAlign: TextAlign.center,
              style: AppTypography.display.copyWith(fontSize: 23, height: 1.25),
            ),
            const SizedBox(height: 14),
            const SizedBox(height: 18),
            const _Separador(),
            const SizedBox(height: 16),
            Text('ELIGE TU PLAN',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                )),
            const SizedBox(height: 12),
            _PlanCard(
              seleccionado: _esAnual,
              badge: 'Plan recomendado',
              precio: '\$19.99',
              periodo: '/ año',
              equivalente: 'equivale a \$1.67 USD/mes',
              destacado: '3 DÍAS GRATIS',
              pie: 'Después \$19.99/año',
              onTap: () => setState(() => _plan = PlusPlan.anual),
            ),
            const SizedBox(height: 12),
            _PlanCard(
              seleccionado: !_esAnual,
              precio: '\$2.99',
              periodo: '/ mes',
              pie: 'Renovación mensual',
              onTap: () => setState(() => _plan = PlusPlan.mensual),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _avisar = !_avisar),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: Text('Avísame antes de que termine la prueba',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.ink, fontSize: 12.5)),
                  ),
                  Switch(
                    value: _avisar,
                    onChanged: (v) => setState(() => _avisar = v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.tealDeep,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _BotonCta(
              texto: _textoCta,
              cargando: _loading,
              onPressed: _loading ? null : _empezar,
            ),
            const SizedBox(height: 10),
            Text(_notaCta,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 4),
            Text('Cancelas cuando quieras desde Google Play',
                textAlign: TextAlign.center,
                style: AppTypography.caption
                    .copyWith(color: AppColors.inkSoft, fontSize: 11)),
            const SizedBox(height: 2),
            Center(
              child: TextButton(
                onPressed: _loading ? null : _restore,
                child: Text('Restaurar compras',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.inkSoft)),
              ),
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
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: AppColors.tealLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              size: 13, color: AppColors.tealDeep),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(texto,
              style: AppTypography.body.copyWith(fontSize: 14, height: 1.3)),
        ),
      ],
    );
  }
}

/// Filete decorativo entre los beneficios y los planes.
class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.sand, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.brightness_1, size: 5, color: AppColors.amberLight),
        ),
        const Expanded(child: Divider(color: AppColors.sand, thickness: 1)),
      ],
    );
  }
}

/// Tarjeta de plan. El badge y la oferta viven DENTRO de la tarjeta,
/// cada uno en su propia fila, para que nunca se monten sobre el precio.
class _PlanCard extends StatelessWidget {
  final bool seleccionado;
  final String precio;
  final String periodo;
  final String? badge;
  final String? equivalente;
  final String? destacado;
  final String? pie;
  final VoidCallback onTap;

  const _PlanCard({
    required this.seleccionado,
    required this.precio,
    required this.periodo,
    required this.onTap,
    this.badge,
    this.equivalente,
    this.destacado,
    this.pie,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: seleccionado ? Colors.white : AppColors.cream,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: seleccionado ? AppColors.tealDeep : AppColors.sand,
            width: seleccionado ? 2 : 1.2,
          ),
          boxShadow: seleccionado
              ? [
                  BoxShadow(
                    color: AppColors.tealDeep.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Radio(activo: seleccionado),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.amberLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 12, color: AppColors.amber),
                          const SizedBox(width: 4),
                          Text(badge!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.amber,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(precio,
                          style: AppTypography.display.copyWith(
                            fontSize: 27,
                            height: 1.0,
                            color: AppColors.tealDeep,
                          )),
                      const SizedBox(width: 5),
                      Text(periodo,
                          style: AppTypography.body.copyWith(
                            fontSize: 14,
                            color: AppColors.inkSoft,
                          )),
                    ],
                  ),
                  if (equivalente != null) ...[
                    const SizedBox(height: 3),
                    Text(equivalente!,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.inkSoft)),
                  ],
                  if (destacado != null) ...[
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.tealDeep,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(destacado!,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          )),
                    ),
                  ],
                  if (pie != null) ...[
                    const SizedBox(height: 7),
                    Text(pie!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSoft,
                          fontSize: 11.5,
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circulo de seleccion del plan.
class _Radio extends StatelessWidget {
  final bool activo;
  const _Radio({required this.activo});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(top: 2),
      width: 21,
      height: 21,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: activo ? AppColors.tealDeep : Colors.transparent,
        border: Border.all(
          color: activo ? AppColors.tealDeep : AppColors.sand,
          width: 2,
        ),
      ),
      child: activo
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

/// Boton principal. Cambia de texto segun el plan elegido.
class _BotonCta extends StatelessWidget {
  final String texto;
  final bool cargando;
  final VoidCallback? onPressed;

  const _BotonCta({
    required this.texto,
    required this.cargando,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealDeep.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.tealDeep,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.tealMedium,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 17),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: cargando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(texto,
                  style: AppTypography.title.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
        ),
      ),
    );
  }
}
