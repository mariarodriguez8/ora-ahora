import 'package:flutter/material.dart';

/// La pradera del Salmo 23, dibujada en capas y pegada al borde inferior.
///
/// Va en codigo y no en imagen a proposito: pesa dos kilobytes en vez de
/// trescientos, se ve nitida en cualquier pantalla y toma los colores del
/// tema, asi que funciona con las cuatro paletas y con el modo noche sin
/// necesitar una version distinta de cada archivo.
///
/// La sensacion de "trabajado a mano" no viene de la forma sino del numero
/// de capas: tres planos superpuestos con hierbas al pie.
class Colina extends StatelessWidget {
  const Colina({
    super.key,
    required this.base,
    this.altura = 200,
    this.acento,
  });

  /// Color del plano mas lejano. Los demas se derivan aclarando.
  final Color base;

  /// Alto total del dibujo.
  final double altura;

  /// Punto de luz (el sol, una flor). Si es null no se dibuja.
  final Color? acento;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: altura,
        width: double.infinity,
        child: CustomPaint(painter: _PintorColina(base, acento)),
      ),
    );
  }
}

class _PintorColina extends CustomPainter {
  _PintorColina(this.base, this.acento);

  final Color base;
  final Color? acento;

  Color _aclarar(Color c, double cuanto) =>
      Color.lerp(c, Colors.white, cuanto)!;

  @override
  void paint(Canvas lienzo, Size s) {
    final p = Paint()..isAntiAlias = true;
    final w = s.width;
    final h = s.height;

    p.color = base;
    lienzo.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(0, h * 0.50)
        ..quadraticBezierTo(w * 0.16, h * 0.14, w * 0.34, h * 0.32)
        ..quadraticBezierTo(w * 0.52, h * 0.50, w * 0.68, h * 0.20)
        ..quadraticBezierTo(w * 0.86, h * -0.08, w, h * 0.24)
        ..lineTo(w, h)
        ..close(),
      p,
    );

    p.color = _aclarar(base, 0.09);
    lienzo.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(0, h * 0.66)
        ..quadraticBezierTo(w * 0.20, h * 0.46, w * 0.42, h * 0.60)
        ..quadraticBezierTo(w * 0.66, h * 0.76, w * 0.84, h * 0.54)
        ..quadraticBezierTo(w * 0.94, h * 0.44, w, h * 0.50)
        ..lineTo(w, h)
        ..close(),
      p,
    );

    p.color = _aclarar(base, 0.18);
    lienzo.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(0, h * 0.84)
        ..quadraticBezierTo(w * 0.26, h * 0.70, w * 0.54, h * 0.80)
        ..quadraticBezierTo(w * 0.80, h * 0.90, w, h * 0.76)
        ..lineTo(w, h)
        ..close(),
      p,
    );

    final hierba = Paint()
      ..color = _aclarar(base, 0.30)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const sitios = <double>[0.07, 0.12, 0.16, 0.72, 0.79, 0.86, 0.93];
    for (var i = 0; i < sitios.length; i++) {
      final x = w * sitios[i];
      final alto = 9.0 + (i % 3) * 4.0;
      final pie = h * (0.93 - (i % 2) * 0.03);
      lienzo.drawLine(Offset(x, pie), Offset(x, pie - alto), hierba);
    }

    if (acento != null) {
      lienzo.drawCircle(
          Offset(w * 0.82, h * 0.12), 5, Paint()..color = acento!);
    }
  }

  @override
  bool shouldRepaint(_PintorColina viejo) =>
      viejo.base != base || viejo.acento != acento;
}
