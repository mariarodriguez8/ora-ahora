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
    mensaje: 'para el día que te sientas lejos. da igual cuánto tiempo pasó: la puerta sigue abierta.',
    url: 'https://www.youtube.com/watch?v=KqRWUCqjeAE',
    oracion: 'Señor, aquí estoy otra vez. Recíbeme como si no me hubiera ido.',
  ),
  Cancion(
    titulo: 'Océanos',
    artista: 'Hillsong United (español)',
    mensaje: 'para cuando no haces pie y aun así tienes que caminar.',
    url: 'https://www.youtube.com/watch?v=2BJ0OA0nXPY',
    oracion: 'Dios, donde no hago pie, sostenme tú.',
  ),
  Cancion(
    titulo: 'Gracias / Tu Fidelidad',
    artista: 'Marcos Witt ft. Un Corazón',
    mensaje: 'para acordarte de todo lo que hizo cuando no estabas mirando.',
    url: 'https://www.youtube.com/watch?v=53BatKbRO2A',
    oracion: 'Padre, gracias por lo que hiciste cuando yo no estaba mirando.',
  ),
  Cancion(
    titulo: 'Gracias',
    artista: 'Marcela Gándara',
    mensaje: 'para los días en que lo único que te sale es decir gracias.',
    url: 'https://www.youtube.com/watch?v=HkZhNE3n-i4',
    oracion: 'Señor, gracias por lo que tengo hoy, aunque no sea todo lo que quería.',
  ),
  Cancion(
    titulo: 'Renuévame',
    artista: 'Marcos Witt',
    mensaje: 'para cuando ya intentaste cambiar solo y no pudiste.',
    url: 'https://www.youtube.com/watch?v=F5gMNbGfy1g',
    oracion: 'Dios, cambia en mí lo que yo solo no puedo cambiar.',
  ),
  Cancion(
    titulo: 'Todo Va a Estar Bien',
    artista: 'Redimi2 ft. Evan Craft',
    mensaje: 'para la noche en que la cabeza no te deja dormir.',
    url: 'https://www.youtube.com/watch?v=UjDiKcjYKCM',
    oracion: 'Padre, calma mi cabeza. Tú tienes esto.',
  ),
  Cancion(
    titulo: 'Santo Espíritu',
    artista: 'Averly Morillo',
    mensaje: 'para cuando necesitas que llene lo que está vacío.',
    url: 'https://www.youtube.com/watch?v=v_zcvFofipg',
    oracion: 'Espíritu Santo, ven y llena lo que tengo hueco.',
  ),
  Cancion(
    titulo: 'Dame de Beber',
    artista: 'Marco Barrientos',
    mensaje: 'para esa sed que no se quita con nada de lo que tienes a mano.',
    url: 'https://www.youtube.com/watch?v=3cSENmro9Hc',
    oracion: 'Señor, dame de beber de ti, que lo demás me deja igual.',
  ),
  Cancion(
    titulo: 'Dios de Maravillas',
    artista: "Christine D'Clario",
    mensaje: 'para volver a mirar quién es Él cuando todo se ve chiquito.',
    url: 'https://www.youtube.com/watch?v=PR8R2aRhyo4',
    oracion: 'Dios, recuérdame quién eres, que se me achicó la fe.',
  ),
  Cancion(
    titulo: 'No Hay Nada Imposible',
    artista: 'Generación 12',
    mensaje: 'para eso que ya diste por perdido.',
    url: 'https://www.youtube.com/watch?v=j0Bbaoqk_JA',
    oracion: 'Padre, esto ya lo di por perdido. Tú todavía no.',
  ),
  Cancion(
    titulo: 'Ancla',
    artista: "Christine D'Clario",
    mensaje: 'para cuando todo se mueve y necesitas algo firme.',
    url: 'https://www.youtube.com/watch?v=r5nEttyHAvo',
    oracion: 'Señor, sé mi ancla mientras todo se sacude.',
  ),
  Cancion(
    titulo: 'Escondite',
    artista: 'Marco Barrientos ft. Un Corazón',
    mensaje: 'para el día en que solo quieres esconderte un rato.',
    url: 'https://www.youtube.com/watch?v=COctfH9K1sQ',
    oracion: 'Dios, escóndeme en ti hasta que pase.',
  ),
  Cancion(
    titulo: 'Encontré',
    artista: 'Generación 12 ft. Sofía Mancipe',
    mensaje: 'para acordarte de cómo eras antes y de quién te encontró.',
    url: 'https://www.youtube.com/watch?v=fb3QgRd5AnM',
    oracion: 'Señor, gracias por encontrarme cuando ni te estaba buscando.',
  ),
  Cancion(
    titulo: 'Dios Conmigo Estás',
    artista: 'Generación 12 ft. Sofía Mancipe',
    mensaje: 'para cuando sientes soledad aunque haya gente al lado.',
    url: 'https://www.youtube.com/watch?v=hbXgvM-y0ng',
    oracion: 'Padre, recuérdame que estás, aunque hoy no te sienta.',
  ),
  Cancion(
    titulo: 'Un Día a la Vez',
    artista: 'Majo y Dan',
    mensaje: 'para cuando pensar en mañana ya te cansa.',
    url: 'https://www.youtube.com/watch?v=fEMndv6YMB8',
    oracion: 'Dios, dame para hoy. Mañana vuelvo a pedirte.',
  ),
  Cancion(
    titulo: 'Me Rindo a Ti',
    artista: 'Majo y Dan',
    mensaje: 'para el momento en que dejas de pelear solo.',
    url: 'https://www.youtube.com/watch?v=ZFDOHMn01EE',
    oracion: 'Señor, me rindo. Hazte cargo tú.',
  ),
  Cancion(
    titulo: 'Tú Estás Aquí',
    artista: 'Su Presencia',
    mensaje: 'para empezar el día sabiendo que Él va contigo.',
    url: 'https://www.youtube.com/watch?v=IbGcLrYMFC8',
    oracion: 'Padre, sé que estás aquí. Que hoy no se me olvide.',
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
