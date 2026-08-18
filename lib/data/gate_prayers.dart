import 'dart:convert';

import '../services/prefs_service.dart';

/// Oraciones CORTAS para la pausa de "Pausa y Ora", agrupadas por la
/// necesidad/categoría que la persona eligió (ansiedad, familia, etc.).
/// Flutter arma una lista personalizada según esas categorías y la guarda
/// para que la pantalla nativa la muestre (en vez de oraciones genéricas).
///
/// Voz del ICP, neutro de género, evangélico (no católico). Sin emojis.
const Map<String, List<String>> _porCategoria = {
  'ansiedad': [
    'Señor, esta ansiedad que me empuja al teléfono, la pongo en tus manos. Respiro contigo. Amén.',
    'Dios, calma lo que traigo por dentro. No necesito huir; te necesito a ti. Amén.',
    'Padre, echo sobre ti mi afán, porque sé que cuidas de mí. Amén.',
    'Señor, cambia este nudo en el pecho por tu paz. Aquí estoy. Amén.',
    'Dios, quédate conmigo en lo que me preocupa. No cargo esto en soledad. Amén.',
  ],
  'paz': [
    'Señor, dame tu paz, esa que el mundo no puede dar. Amén.',
    'Dios, aquieta mi mente. Respiro y descanso en ti. Amén.',
    'Padre, que mi paz no la decidan las noticias ni los comentarios. Amén.',
  ],
  'gratitud': [
    'Señor, antes de seguir: gracias. Por hoy, por respirar, por seguir aquí. Amén.',
    'Dios, gracias porque tu amor no depende de cómo me sienta hoy. Amén.',
    'Padre, en medio del ruido, gracias por lo bueno que sí tengo. Amén.',
    'Señor, hoy elijo dar gracias antes que quejarme. Ayúdame. Amén.',
  ],
  'familia': [
    'Señor, cuida a los míos hoy, estén donde estén. Los pongo en tus manos. Amén.',
    'Dios, dame paciencia y amor para mi familia, aun cuando cuesta. Amén.',
    'Padre, sana lo que está roto en mi casa. Trae paz. Amén.',
    'Señor, que mi familia te sienta a través de mí hoy. Amén.',
  ],
  'trabajo': [
    'Señor, dame fuerzas para lo de hoy. Que trabaje como para ti. Amén.',
    'Dios, calma mi estrés del trabajo. Tú vas delante de mí. Amén.',
    'Padre, dame sabiduría para lo que tengo que resolver hoy. Amén.',
    'Señor, que mi valor no dependa de cuánto logre hoy. Amén.',
  ],
  'tentacion_enfoque': [
    'Señor, dame dominio propio ahora mismo. Tú puedes donde yo no. Amén.',
    'Dios, que hoy tu voz sea más fuerte que todas estas notificaciones. Amén.',
    'Padre, líbrame de escapar en la pantalla. Quédate tú. Amén.',
    'Señor, un minuto contigo vale más que una hora perdida aquí. Amén.',
  ],
  'sanidad': [
    'Señor, sana lo que me duele, por dentro y por fuera. Confío en ti. Amén.',
    'Dios, pon tu mano donde más me duele hoy. Amén.',
    'Padre, dame paciencia mientras sano. No me sueltes. Amén.',
  ],
  'perdon': [
    'Señor, ayúdame a perdonar como tú me perdonas a mí. Amén.',
    'Dios, quita el rencor que cargo. No quiero llevarlo más. Amén.',
    'Padre, perdóname, y ayúdame a empezar de nuevo hoy. Amén.',
  ],
  'duelo': [
    'Señor, en esta tristeza que cargo, quédate cerca. Amén.',
    'Dios, consuélame como solo tú sabes. Aquí estoy. Amén.',
    'Padre, sostén mi corazón hoy. No me sueltes. Amén.',
  ],
  'soledad': [
    'Señor, aunque me sienta en soledad, tú estás aquí conmigo. Amén.',
    'Dios, llena este vacío que ninguna pantalla puede llenar. Amén.',
    'Padre, recuérdame que soy tuyo y que tú siempre estás conmigo. Amén.',
  ],
  'matrimonio': [
    'Señor, cuida mi relación. Danos paciencia y amor hoy. Amén.',
    'Dios, sana lo que está tenso con mi pareja. Trae paz. Amén.',
    'Padre, enséñame a amar como tú amas. Amén.',
  ],
  'finanzas': [
    'Señor, calma mi angustia por el dinero. Tú provees. Amén.',
    'Dios, dame sabiduría con lo que tengo y paz con lo que falta. Amén.',
    'Padre, confío en que no me vas a soltar. Provee, Señor. Amén.',
  ],
  'manana': [
    'Señor, gracias por este día. Quiero dártelo a ti antes que a nada. Amén.',
    'Dios, ordena mi mañana. Que lo primero seas tú. Amén.',
  ],
  'noche': [
    'Señor, gracias por hoy. En paz me acuesto, porque tú me cuidas. Amén.',
    'Dios, suelto el día en tus manos. Dame descanso de verdad. Amén.',
  ],
};

/// Unas pocas universales (para variar aunque la persona elija poco).
const List<String> _universales = [
  'Señor, gracias por este alto. Respiro, y me acuerdo de que estás aquí. Amén.',
  'Padre, que este momento sea mío otra vez, y no de la pantalla. Amén.',
  'Dios, dame un minuto contigo antes que a la pantalla. Amén.',
];

/// Construye la lista de oraciones de la pausa según las categorías
/// elegidas. Si no hay ninguna, usa "tentación y enfoque" + universales.
List<String> buildGatePrayers(List<String> categorias) {
  final cats = categorias.isEmpty ? const ['tentacion_enfoque'] : categorias;
  final out = <String>[];
  for (final c in cats) {
    out.addAll(_porCategoria[c] ?? const []);
  }
  out.addAll(_universales);
  out.shuffle();
  final seen = <String>{};
  return out.where(seen.add).toList();
}

/// Calcula la lista personalizada y la guarda para la pantalla nativa.
Future<void> syncGatePrayers(PrefsService prefs) async {
  final lista = buildGatePrayers(prefs.preferredCategories);
  await prefs.setGatePrayersJson(jsonEncode(lista));
}
