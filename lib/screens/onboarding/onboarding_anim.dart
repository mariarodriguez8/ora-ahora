import 'package:flutter/material.dart';

/// Transicion entre pantallas del onboarding.
///
/// La pantalla nueva entra desde la derecha con un zoom minimo y se funde;
/// la anterior retrocede un poco y se apaga. Es la sensacion de "avanzar"
/// que tienen las apps caras. Se registra en el tema, asi que aplica sola
/// a TODAS las pantallas sin tocar cada Navigator.push.
class TransicionOra extends PageTransitionsBuilder {
  const TransicionOra();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final entra = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final sale = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic);

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: const Interval(0.10, 1.0, curve: Curves.easeOut)),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.16, 0.0), end: Offset.zero).animate(entra),
        child: SlideTransition(
          position: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.09, 0.0)).animate(sale),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.975, end: 1.0).animate(entra),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Entrada escalonada de un elemento.
///
/// Cada hijo aparece un poco despues del anterior, subiendo unos pixeles
/// mientras se funde. Es lo que hace que una pantalla se sienta viva en
/// vez de aparecer de golpe. Se usa envolviendo cada bloque con un [orden]
/// creciente: titulo 0, subtitulo 1, botones 2, 3, 4...
class AparicionSuave extends StatefulWidget {
  final Widget child;
  final int orden;
  final int escalonMs;
  final double desplazamiento;

  const AparicionSuave({
    super.key,
    required this.child,
    this.orden = 0,
    this.escalonMs = 85,
    this.desplazamiento = 22.0,
  });

  @override
  State<AparicionSuave> createState() => _AparicionSuaveState();
}

class _AparicionSuaveState extends State<AparicionSuave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  late final Animation<double> _curva =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    // Espera a que termine de entrar la pantalla y recien ahi escalona.
    final espera = 240 + widget.orden * widget.escalonMs;
    Future<void>.delayed(Duration(milliseconds: espera), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curva,
      builder: (context, hijo) => Opacity(
        opacity: _curva.value,
        child: Transform.translate(
          offset: Offset(0, widget.desplazamiento * (1 - _curva.value)),
          child: hijo,
        ),
      ),
      child: widget.child,
    );
  }
}
