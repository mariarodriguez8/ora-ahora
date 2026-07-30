/// Estampas de versículo que se DESBLOQUEAN por racha. Cada una se
/// desbloquea al llegar a cierto día de racha (calendario elegido por la
/// clienta: 3, 5, 7, 10, 14, 21, 27, 33, 45, 55, 66, 77). Sirven de premio
/// y, al compartirse a WhatsApp/estados, de motor de crecimiento gratis.
///
/// Las imágenes viven en `store_assets/estampas/` (declaradas como assets
/// en pubspec.yaml). Están en la estética de la ovejita, con versículo
/// Reina-Valera (evangélico, no católico).
class Estampa {
  /// Día de racha en el que se desbloquea.
  final int dia;

  /// Ruta del asset (PNG 1080x1920).
  final String asset;

  /// Referencia del versículo (para el pie en la galería).
  final String versiculo;

  const Estampa({required this.dia, required this.asset, required this.versiculo});
}

const List<Estampa> kEstampas = [
  Estampa(dia: 0, asset: 'store_assets/estampas/estampa_01.png', versiculo: 'Lamentaciones 3:23'), // estampa de bienvenida (siempre desbloqueada)
  Estampa(dia: 5, asset: 'store_assets/estampas/estampa_02.png', versiculo: 'Filipenses 1:6'),
  Estampa(dia: 7, asset: 'store_assets/estampas/estampa_03.png', versiculo: 'Salmo 23:1'),
  Estampa(dia: 10, asset: 'store_assets/estampas/estampa_04.png', versiculo: 'Salmo 118:24'),
  Estampa(dia: 14, asset: 'store_assets/estampas/estampa_05.png', versiculo: 'Salmo 42:8'),
  Estampa(dia: 21, asset: 'store_assets/estampas/estampa_06.png', versiculo: 'Salmo 119:105'),
  Estampa(dia: 27, asset: 'store_assets/estampas/estampa_07.png', versiculo: 'Mateo 6:33'),
  Estampa(dia: 33, asset: 'store_assets/estampas/estampa_08.png', versiculo: 'Salmo 4:8'),
  Estampa(dia: 45, asset: 'store_assets/estampas/estampa_09.png', versiculo: 'Isaías 40:31'),
  Estampa(dia: 55, asset: 'store_assets/estampas/estampa_10.png', versiculo: '1 Tesalonicenses 5:18'),
  Estampa(dia: 66, asset: 'store_assets/estampas/estampa_11.png', versiculo: '1 Pedro 5:7'),
  Estampa(dia: 77, asset: 'store_assets/estampas/estampa_12.png', versiculo: 'Mateo 11:28'),
];

/// Cuántas estampas están desbloqueadas para una racha dada.
int estampasDesbloqueadas(int racha) =>
    kEstampas.where((e) => racha >= e.dia).length;

/// ¿Hay alguna estampa desbloqueada que la persona todavía no ha visto?
/// (`vistaHasta` = mayor racha con la que ya abrió la galería).
bool hayEstampaNueva(int racha, int vistaHasta) =>
    kEstampas.any((e) => e.dia > vistaHasta && e.dia <= racha);
