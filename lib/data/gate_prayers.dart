import 'dart:convert';

import '../services/prefs_service.dart';

/// Oraciones CORTAS de la pausa de "Pausa y Ora", agrupadas por la
/// necesidad que la persona eligio. La app arma una lista personalizada y
/// la guarda para que la pantalla nativa la muestre AL AZAR (la pausa
/// aparece varias veces al dia, asi que hay ~10 por tema para que no se
/// sienta repetitiva).
const Map<String, List<String>> _porCategoria = {
  'ansiedad': [
    'Señor, tengo el pecho apretado y ni sé bien por qué. Tú sí sabes. Quédate.',
    'Dios, mi cabeza ya vivió mañana diez veces. Tráeme de vuelta a hoy.',
    'Padre, no puedo con todo lo que estoy imaginando. Ayúdame a soltar lo que ni ha pasado.',
    'Señor, si eso que temo llega, tú vas a estar ahí. Con eso me basta hoy.',
    'Dios, dame descanso de mi propia cabeza.',
    'Padre, no me pidas que finja que estoy bien. Solo no te vayas.',
    'Señor, cuando el corazón se me acelera, recuérdame que tú no te aceleras.',
    'Dios, cambia mi "¿y si pasa?" por "tú estás conmigo".',
    'Padre, hoy no puedo con esto. Sostenme tú.',
    'Señor, respiro. Tú tienes lo que a mí se me sale de las manos.',
  ],
  'paz': [
    'Señor, aquieta lo que llevo por dentro.',
    'Dios, dame tu calma, no la que finjo delante de los demás.',
    'Padre, hoy suelto lo que no me toca cargar.',
    'Señor, que mi día no lo maneje lo que siento.',
    'Dios, tú calmaste la tormenta. Calma también esta.',
    'Padre, no necesito entenderlo todo hoy.',
    'Señor, guarda mi corazón de lo que me quita la calma.',
    'Dios, en medio de este día, quédate.',
    'Padre, que tu paz pese más que mi ansiedad.',
    'Señor, respiro hondo. Tú estás.',
  ],
  'gratitud': [
    'Señor, gracias por lo que ni pedí y aun así me diste.',
    'Dios, gracias por seguir aquí después de todo.',
    'Padre, gracias por la gente que me quiere sin condiciones.',
    'Señor, gracias por lo que me libraste y ni me di cuenta.',
    'Dios, gracias por hoy, aunque no fue perfecto.',
    'Padre, gracias por lo pequeño: comer, dormir, respirar.',
    'Señor, gracias porque tu amor no se gana ni se pierde.',
    'Dios, hoy quiero decir gracias antes de pedirte algo.',
    'Padre, gracias también por las veces que me dijiste que no.',
    'Señor, gracias por la cruz. Y no lo digo por decir.',
  ],
  'familia': [
    'Señor, cuida a mi gente cuando yo no puedo estar.',
    'Dios, dame paciencia con quien más quiero y menos entiendo.',
    'Padre, sana lo que se rompió en mi casa. Tú puedes donde ya nadie habla.',
    'Señor, que yo no sea el motivo por el que alguien en mi casa se aleja de ti.',
    'Dios, gracias por los que me aguantan en mis peores días.',
    'Padre, por los que están lejos: cuídalos como si yo estuviera ahí.',
    'Señor, enséñame a pedir perdón primero.',
    'Dios, en mi casa hay cosas que duelen. Entra tú.',
    'Padre, que en mi familia te vean en cómo trato, no en lo que digo.',
    'Señor, cuida hoy a quien no me está hablando.',
  ],
  'trabajo': [
    'Señor, dame fuerzas para lo que hoy no tengo ganas de hacer.',
    'Dios, que mi valor no dependa de cuánto produzca hoy.',
    'Padre, sostenme cuando entre a esa reunión.',
    'Señor, dame sabiduría para lo que no sé resolver.',
    'Dios, gracias por el trabajo que tengo, aunque hoy pese.',
    'Padre, líbrame de compararme con lo que otros muestran.',
    'Señor, que haga bien lo mío aunque nadie lo note.',
    'Dios, calma mi cabeza antes de responder ese mensaje.',
    'Padre, si esto no es lo mío, muéstrame; mientras tanto, ayúdame a ser fiel aquí.',
    'Señor, que se note que eres tú quien me sostiene.',
  ],
  'tentacion_enfoque': [
    'Señor, ayúdame a soltar esto ahora.',
    'Dios, dame fuerza justo en este segundo.',
    'Padre, no quiero volver a lo mismo. Ayúdame.',
    'Señor, tú conoces mi lucha. No me sueltes.',
    'Dios, hazme fuerte justo donde soy débil.',
    'Padre, lo que estoy por hacer, ¿me acerca o me aleja de ti?',
    'Señor, gracias porque tu gracia es más grande que mi recaída.',
    'Dios, dame la salida que prometiste dar.',
    'Padre, hoy elijo lo que me hace bien aunque no me nazca.',
    'Señor, si caigo otra vez, no me dejes quedarme ahí.',
  ],
  'sanidad': [
    'Señor, tú conoces este dolor mejor que yo.',
    'Dios, sana también lo que los demás no ven.',
    'Padre, dame paciencia mientras espero mejorar.',
    'Señor, si hoy no hay sanidad, dame fuerzas.',
    'Dios, cuida a quien hoy está peor que yo.',
    'Padre, gracias por cada día que me das.',
    'Señor, toca ese lugar que duele.',
    'Dios, no me sueltes en esta espera.',
    'Padre, tú tocaste al que nadie quería tocar. Tócame.',
    'Señor, sana lo que quedó adentro.',
  ],
  'perdon': [
    'Señor, todavía no puedo perdonar. Ayúdame a querer hacerlo.',
    'Dios, quita este rencor que me está pesando más a mí.',
    'Padre, perdóname por lo que hice y por lo que dejé de hacer.',
    'Señor, sáname de lo que me hicieron.',
    'Dios, ayúdame a soltar la deuda que llevo cobrando.',
    'Padre, gracias porque tú perdonas de verdad, no a medias.',
    'Señor, bendice a quien me hirió. Cuesta, pero lo digo.',
    'Dios, no quiero volverme como aquello que me dolió.',
    'Padre, hoy empiezo de nuevo. Gracias por dejarme.',
    'Señor, perdóname también por lo que ni recuerdo.',
  ],
  'duelo': [
    'Señor, hoy pesa más de lo normal. Quédate.',
    'Dios, gracias por lo que viví con esa persona.',
    'Padre, no sé cómo seguir. Enséñame.',
    'Señor, guarda mis recuerdos y sana la herida.',
    'Dios, tú también lloraste. Eso me consuela.',
    'Padre, acompáñame en los días que nadie ve.',
    'Señor, dame fuerzas para hoy. Solo para hoy.',
    'Dios, cuida a los que también están tristes conmigo.',
    'Padre, un día no va a doler así. Hoy sostenme.',
    'Señor, gracias porque la muerte no es el final.',
  ],
  'soledad': [
    'Señor, hoy me siento a un lado. Tú me ves.',
    'Dios, estoy con gente y aun así me siento así. Tú entiendes.',
    'Padre, gracias porque contigo no tengo que explicar nada.',
    'Señor, pon a alguien cerca con quien pueda hablar de verdad.',
    'Dios, cuando nadie escribe, tú sigues ahí.',
    'Padre, enséñame a buscar a alguien en vez de esconderme.',
    'Señor, tú me conoces entero y aun así te quedas.',
    'Dios, hoy no quiero estar así. Acompáñame.',
    'Padre, que la tristeza no me convenza de que a nadie le importo.',
    'Señor, tú estuviste solo en la cruz para que yo nunca lo estuviera.',
  ],
  'matrimonio': [
    'Señor, cuida lo nuestro cuando estamos cansados.',
    'Dios, ayúdame a escuchar antes de responder.',
    'Padre, sana lo que dijimos y no debimos.',
    'Señor, que yo ceda primero.',
    'Dios, enséñanos a discutir sin herirnos.',
    'Padre, cuida su corazón hoy.',
    'Señor, gracias por quien camina a mi lado.',
    'Dios, ayúdame a elegirle también en los días difíciles.',
    'Padre, que el orgullo no decida por nosotros.',
    'Señor, ponnos de acuerdo donde no lo estamos.',
  ],
  'finanzas': [
    'Señor, no me alcanza y tú lo sabes. Aquí estoy.',
    'Dios, quita el miedo que me da mirar la cuenta.',
    'Padre, dame sabiduría con lo poco y con lo mucho.',
    'Señor, gracias por lo que hoy sí tengo.',
    'Dios, que el dinero no me robe la paz ni el sueño.',
    'Padre, provee. Confío, aunque me tiemble la voz.',
    'Señor, ayúdame a no medir mi vida por lo que me falta.',
    'Dios, enséñame a dar aun cuando me cuesta.',
    'Padre, tú alimentaste a miles con poco. Aquí está lo mío.',
    'Señor, hoy elijo confiar en vez de calcular.',
  ],
  'manana': [
    'Señor, este día es tuyo antes de ser mío.',
    'Dios, ordena lo que tengo por delante.',
    'Padre, gracias por despertarme otra vez.',
    'Señor, que lo primero de hoy seas tú.',
    'Dios, dame fuerza para lo que hoy me toca.',
    'Padre, acompáñame en cada rato de este día.',
    'Señor, hoy empiezo contigo. Con eso basta.',
    'Dios, guía las decisiones que tome hoy.',
  ],
  'noche': [
    'Señor, gracias por hoy, con todo lo que trajo.',
    'Dios, perdóname por lo de hoy. Mañana empiezo de nuevo.',
    'Padre, apaga mi cabeza y dame descanso.',
    'Señor, cuida a los míos mientras duermen.',
    'Dios, lo que no resolví hoy, te lo dejo.',
    'Padre, en paz me acuesto porque tú me cuidas.',
    'Señor, gracias por lo bueno que ni noté hoy.',
    'Dios, mañana será mejor contigo.',
  ],
};

const List<String> _universales = [
  'Señor, aquí estoy. Gracias por este alto.',
  'Padre, un minuto contigo y sigo.',
  'Dios, gracias porque puedo hablarte en cualquier momento.',
];

List<String> buildGatePrayers(List<String> categorias) {
  final cats = categorias.isEmpty ? const ['tentacion_enfoque'] : categorias;
  final out = <String>[];
  for (final c in cats) {
    out.addAll(_porCategoria[c] ?? const []);
  }
  out.addAll(_universales);
  final seen = <String>{};
  return out.where(seen.add).toList();
}

Future<void> syncGatePrayers(PrefsService prefs) async {
  final lista = buildGatePrayers(prefs.preferredCategories);
  await prefs.setGatePrayersJson(jsonEncode(lista));
}
