/// Biblioteca fija (sin costo, sin IA) de "canción de la semana" para
/// usuarios Plus. Son enlaces a videos oficiales de YouTube (nunca se
/// aloja música: solo se abre el enlace en la app de YouTube/navegador).
///
/// Cada semana del año rota una canción distinta, ligada a un momento o
/// emoción del ICP (volver a Dios, ansiedad, gratitud, descanso, etc.).
class Cancion {
  final String titulo;
  final String artista;

  /// Mensaje corto en la voz del ICP (neutro, sin lenguaje IA).
  final String mensaje;

  /// Enlace al video oficial en YouTube.
  final String url;
  /// Que orar mientras suena. Es el diferenciador de la app.
  final String oracion;

  const Cancion({
    required this.titulo,
    required this.artista,
    required this.mensaje,
    required this.url,
    this.oracion = 'Señor, mientras la escucho, quédate conmigo.',
  });
}

const List<Cancion> kCanciones = [
  Cancion(
    titulo: 'Vuelvo a Ti',
    artista: 'Un Corazón ft. Lowsan Melgar',
    mensaje: 'para cuando sientes que te alejaste. da igual cuánto tiempo '
        'pasó: la puerta sigue abierta.',
    url: 'https://www.youtube.com/watch?v=KqRWUCqjeAE',
    oracion: 'Señor, aquí estoy otra vez. Recíbeme como si no me hubiera ido.',
  ),
  Cancion(
    titulo: 'Océanos',
    artista: 'Hillsong United (español)',
    mensaje: 'cuando no ves piso firme, esta te recuerda que Él te sostiene.',
    url: 'https://www.youtube.com/watch?v=2BJ0OA0nXPY',
    oracion: 'Dios, donde no hago pie, sostenme tú.',
  ),
  Cancion(
    titulo: 'Gracias / Tu Fidelidad',
    artista: 'Marcos Witt ft. Un Corazón',
    mensaje: 'acuérdate de todo lo que Él ya hizo por ti, aunque hoy pese.',
    url: 'https://www.youtube.com/watch?v=53BatKbRO2A',
    oracion: 'Padre, gracias por lo que hiciste cuando yo no estaba mirando.',
  ),
  Cancion(
    titulo: 'Gracias',
    artista: 'Marcela Gándara',
    mensaje: 'un minuto para agradecer lo simple: hoy, respirar, seguir aquí.',
    url: 'https://www.youtube.com/watch?v=HkZhNE3n-i4',
    oracion: 'Señor, gracias por lo que tengo hoy, aunque no sea todo lo que quería.',
  ),
  Cancion(
    titulo: 'Renuévame',
    artista: 'Marcos Witt',
    mensaje: 'para cuando por dentro te sientes seco. pídele que te renueve.',
    url: 'https://www.youtube.com/watch?v=F5gMNbGfy1g',
    oracion: 'Dios, cambia en mí lo que yo solo no puedo cambiar.',
  ),
  Cancion(
    titulo: 'Todo Va a Estar Bien',
    artista: 'Redimi2 ft. Evan Craft',
    mensaje: 'no es fingir que todo está bien; es soltar en Sus manos lo que '
        'no lo está.',
    url: 'https://www.youtube.com/watch?v=UjDiKcjYKCM',
    oracion: 'Padre, calma mi cabeza. Tú tienes esto.',
  ),
  Cancion(
    titulo: 'Santo Espíritu',
    artista: 'Averly Morillo',
    mensaje: 'sube el volumen y déjalo llenar el cuarto. no cargas esto en '
        'soledad.',
    url: 'https://www.youtube.com/watch?v=v_zcvFofipg',
  ),
  Cancion(
    titulo: 'Dame de Beber',
    artista: 'Marco Barrientos',
    mensaje: 'cuando nada llena, esa sed es de Él. déjala llevarte a orar.',
    url: 'https://www.youtube.com/watch?v=3cSENmro9Hc',
  ),
  Cancion(
    titulo: 'Dios de Maravillas',
    artista: "Christine D'Clario",
    mensaje: 'para acordarte de quién es Él, no solo de lo que necesitas.',
    url: 'https://www.youtube.com/watch?v=PR8R2aRhyo4',
  ),
  Cancion(
    titulo: 'No Hay Nada Imposible',
    artista: 'Generación 12',
    mensaje: 'para el día en que todo se ve cuesta arriba. nada le queda '
        'grande a Dios.',
    url: 'https://www.youtube.com/watch?v=j0Bbaoqk_JA',
  ),
  Cancion(
    titulo: 'Ancla',
    artista: "Christine D'Clario",
    mensaje: 'para la noche, cuando la cabeza no para. Él es tu ancla: hoy '
        'sí puedes descansar.',
    url: 'https://www.youtube.com/watch?v=r5nEttyHAvo',
  ),
  Cancion(
    titulo: 'Escondite',
    artista: 'Marco Barrientos ft. Un Corazón',
    mensaje: 'cuando quieras esconderte del mundo, escóndete en Él.',
    url: 'https://www.youtube.com/watch?v=COctfH9K1sQ',
  ),
  Cancion(
    titulo: 'Encontré',
    artista: 'Generación 12 ft. Sofía Mancipe',
    mensaje: 'dejaste de buscar en el celular lo que solo se encuentra en Él.',
    url: 'https://www.youtube.com/watch?v=fb3QgRd5AnM',
  ),
  Cancion(
    titulo: 'Dios Conmigo Estás',
    artista: 'Generación 12 ft. Sofía Mancipe',
    mensaje: 'aunque no lo sientas, no estás en esto en soledad.',
    url: 'https://www.youtube.com/watch?v=hbXgvM-y0ng',
  ),
  Cancion(
    titulo: 'Un Día a la Vez',
    artista: 'Majo y Dan',
    mensaje: 'no tienes que arreglar todo hoy. solo hoy, con Él.',
    url: 'https://www.youtube.com/watch?v=fEMndv6YMB8',
  ),
  Cancion(
    titulo: 'Me Rindo a Ti',
    artista: 'Majo y Dan',
    mensaje: 'por un momento, entrégaselo. no tienes que poder con todo.',
    url: 'https://www.youtube.com/watch?v=ZFDOHMn01EE',
  ),
  Cancion(
    titulo: 'Tú Estás Aquí',
    artista: 'Su Presencia',
    mensaje: 'cierra los ojos y respira: Él ya está aquí, contigo.',
    url: 'https://www.youtube.com/watch?v=IbGcLrYMFC8',
  ),
];

/// Índice de la semana del año (0-basado), para rotar la canción.
int _semanaDelAno(DateTime now) {
  final inicio = DateTime(now.year, 1, 1);
  return now.difference(inicio).inDays ~/ 7;
}

/// La canción que toca esta semana.
Cancion cancionDeLaSemana([DateTime? ahora]) {
  final now = ahora ?? DateTime.now();
  return kCanciones[_semanaDelAno(now) % kCanciones.length];
}
