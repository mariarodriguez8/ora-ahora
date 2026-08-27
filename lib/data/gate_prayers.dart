import 'dart:convert';

import '../services/prefs_service.dart';

/// Oraciones de la pausa de "Pausa y Ora", agrupadas por la necesidad que la
/// persona eligio.
///
/// Voz del cancionero evangelico hispano: cada una junta una situacion
/// concreta y honesta con una imagen del salmo o de la alabanza (tormenta,
/// refugio, sostenme, bajo tus alas). Sin lo primero suena a folleto; sin lo
/// segundo suena a app de meditacion.
const Map<String, List<String>> _porCategoria = {
  'ansiedad': [
    'Señor, tengo el pecho apretado y ni sé bien por qué. Tú calmaste el mar con una sola palabra; cálmame a mí. Y si esta tormenta no se va todavía, no me sueltes mientras pasa.',
    'Padre, mi cabeza ya vivió mañana diez veces y ninguna salió bien. Sé mi refugio hoy. Que tu paz me guarde el corazón aunque no entienda nada de lo que viene.',
    'Dios, no puedo con todo lo que estoy imaginando. Echo sobre ti esta ansiedad, porque tú tienes cuidado de mí. Ayúdame a soltar lo que ni siquiera ha pasado.',
    'Señor, si eso que tanto temo llega, tú vas a estar ahí antes que yo. Con eso me alcanza para hoy. Sostenme hasta mañana.',
    'Padre, dame descanso de mi propia cabeza. Ven tú donde yo no llego. Que tu presencia pese más que todo este ruido.',
    'Dios, no me pidas que finja que estoy bien. Tú ves lo que nadie ve. Aquí estoy, tal como estoy, y confío en que eso te basta.',
    'Señor, cuando el corazón se me acelera, recuérdame que tú no te aceleras. Tú reinas también sobre esto. Quédate conmigo hasta que se me pase.',
    'Padre, cambia mi "y si pasa" por "tú estás conmigo". Aunque ande en valle de sombra no temeré, porque tú vas delante de mí.',
    'Dios, hoy no puedo con esto. Me rindo y te lo entrego. Sé tú mi fuerza justo donde a mí se me acabó.',
    'Señor, esto me queda grande y no sé por dónde empezar. Hazte cargo tú. Yo me quedo quieto y espero en ti.',
  ],
  'paz': [
    'Señor, aquieta lo que llevo por dentro. Tú eres mi refugio y mi fuerza, mi pronto auxilio en la angustia. Hoy me quedo debajo de tus alas hasta que amaine.',
    'Dios, dame tu calma, no la que finjo delante de los demás. Tú sabes cómo estoy de verdad. Lléname donde estoy vacío.',
    'Padre, hoy suelto lo que no me toca cargar. Tu yugo es fácil y tu carga ligera. Enséñame a caminar así.',
    'Señor, que mi día no lo maneje lo que siento, que lo mandes tú. Guarda mi corazón y mis pensamientos hoy.',
    'Dios, tú calmaste la tormenta con una palabra. Calma también esta. Y si todavía no, dame paz en medio de ella.',
    'Padre, no necesito entenderlo todo hoy. Confío en ti aunque no vea el camino. Dirige tú mis pasos.',
    'Señor, guarda mi corazón de lo que me roba la calma. Que tu presencia sea el lugar al que vuelvo cuando todo se mueve.',
    'Dios, en medio de este día, quédate. No me dejes solo con mis pensamientos. Háblame aunque sea bajito.',
    'Padre, que tu paz pese más que mi ansiedad. Esa que sobrepasa todo entendimiento, esa te pido hoy.',
    'Señor, aquí estoy. Cansado, pero aquí. Renueva mis fuerzas como prometiste, que ya no me quedan muchas.',
  ],
  'gratitud': [
    'Señor, gracias por lo que ni pedí y aun así me diste. Tus misericordias son nuevas cada mañana, y hoy me tocó otra vez. Grande es tu fidelidad.',
    'Dios, gracias por seguir aquí después de todo lo que hice. Tu amor no se acaba ni se gasta. Hoy solo quiero decirte gracias.',
    'Padre, gracias por la gente que me quiere sin condiciones. Cuídalos hoy como me cuidas a mí. Que nunca les falte lo que a mí me sobra.',
    'Señor, gracias por lo que me libraste y ni me di cuenta. Tú peleaste por mí mientras yo dormía. No lo vi, pero ahí estabas.',
    'Dios, gracias por hoy, aunque no fue perfecto. Tú haces bien todas las cosas, aun las que no entiendo todavía.',
    'Padre, gracias por lo que tengo y ni valoro. Abre mis ojos para verlo antes de que me falte.',
    'Señor, gracias porque tu amor no se gana ni se pierde. No me lo merezco y aun así me lo das. Eso es gracia y hoy la recibo.',
    'Dios, hoy quiero decir gracias antes de pedirte algo. Solo eso. Gracias por ser quien eres conmigo.',
    'Padre, gracias también por las veces que me dijiste que no. Tú sabías lo que había del otro lado y me guardaste.',
    'Señor, gracias por la cruz. Y no lo digo por decir: hoy de verdad sé lo que me costó a mí y lo que te costó a ti.',
  ],
  'familia': [
    'Señor, cuida a mi gente cuando yo no puedo estar. Pon tus ángeles alrededor de mi casa. Guárdalos en tus manos, que ahí están más seguros que en las mías.',
    'Dios, dame paciencia con quien más quiero y menos entiendo. Que el amor cubra lo que hoy no puedo arreglar.',
    'Padre, sana lo que se rompió en mi casa. Tú puedes hablar donde ya nadie se habla. Restaura lo que nosotros no supimos cuidar.',
    'Señor, que yo no sea el motivo por el que alguien en mi casa se aleja de ti. Cámbiame a mí primero.',
    'Dios, gracias por los que me aguantan en mis peores días. Bendícelos el doble de lo que yo los merezco.',
    'Padre, por los que están lejos: cuídalos como si yo estuviera ahí. Que sientan hoy que no están solos.',
    'Señor, enséñame a pedir perdón primero, aunque yo crea que tengo la razón. Quiebra mi orgullo antes de que quiebre mi casa.',
    'Dios, en mi casa hay cosas que duelen y nadie las dice. Entra tú donde nosotros no nos atrevemos.',
    'Padre, que en mi familia te vean en cómo trato, no en lo que digo. Que mi vida hable más fuerte que mis palabras.',
    'Señor, cuida hoy a quien no me está hablando. Bendícelo aunque me duela, y trabaja tú en los dos.',
  ],
  'trabajo': [
    'Señor, dame fuerzas para lo que hoy no tengo ganas de hacer. Tú das esfuerzo al cansado y multiplicas las fuerzas del que no las tiene. Hoy me toca a mí.',
    'Dios, que mi valor no dependa de cuánto produzca hoy. Yo ya soy tuyo antes de hacer nada. Recuérdamelo cuando se me olvide.',
    'Padre, sostenme cuando entre a esa reunión. Pon tú las palabras que yo no encuentro y calla las que sobran.',
    'Señor, dame sabiduría para lo que no sé resolver. Tú la das en abundancia y sin reproche. Aquí estoy pidiéndola.',
    'Dios, gracias por el trabajo que tengo, aunque hoy pese. Ayúdame a hacerlo como para ti y no para los hombres.',
    'Padre, líbrame de compararme con lo que otros muestran. Tú me diste mi propio camino. Ayúdame a caminar el mío sin mirar el de al lado.',
    'Señor, que haga bien lo mío aunque nadie lo note. Tú ves en lo secreto y eso me basta.',
    'Dios, calma mi cabeza antes de que responda ese mensaje. Que hable el que quiere agradarte, no el que quiere tener razón.',
    'Padre, si esto no es lo mío, muéstrame; y mientras tanto, ayúdame a ser fiel aquí. En lo poco se prueba lo mucho.',
    'Señor, que se note que eres tú quien me sostiene. Que mi paz en medio de todo esto sea testimonio y no casualidad.',
  ],
  'tentacion_enfoque': [
    'Señor, tú sabes lo que estoy por hacer. Dame la salida que prometiste dar. Sostenme fuerte, porque solo no puedo y no quiero volver a lo mismo.',
    'Dios, dame fuerza justo en este segundo. No mañana, ahora. Tú eres mi fortaleza cuando la mía se acaba.',
    'Padre, no quiero volver a lo mismo. Rompe tú esta cadena, que yo llevo años intentando y no puedo.',
    'Señor, tú conoces mi lucha mejor que nadie y no me despreciaste por ella. No me sueltes ahora.',
    'Dios, hazme fuerte justo donde soy débil. Que tu poder se perfeccione en esto que tanto me avergüenza.',
    'Padre, lo que estoy por hacer, ¿me acerca o me aleja de ti? Dame un segundo de claridad antes de decidir.',
    'Señor, gracias porque tu gracia es más grande que mi recaída. Que eso no sea excusa, sino la razón por la que me levanto otra vez.',
    'Dios, dame la salida. Sé que está ahí, pero hoy no la veo. Muéstramela y dame el valor de tomarla.',
    'Padre, hoy elijo lo que me hace bien aunque no me nazca. Que mi obediencia vaya adelante de mis ganas.',
    'Señor, si caigo otra vez, no me dejes quedarme ahí. Levántame rápido, aunque sea la séptima vez del día.',
  ],
  'sanidad': [
    'Señor, tú conoces este dolor mejor que yo, porque tú también cargaste el tuyo. Pon tu mano donde duele. Y si hoy no hay sanidad, dame fuerzas para un día más.',
    'Dios, sana también lo que los demás no ven. Por tus llagas fuimos nosotros curados. Que eso sea verdad en mi cuerpo y en mi alma.',
    'Padre, dame paciencia mientras espero mejorar. Los que esperan en ti tendrán nuevas fuerzas. Aquí estoy esperando.',
    'Señor, tú tocaste al que nadie quería tocar. Tócame a mí también, aunque me sienta lejos de merecerlo.',
    'Dios, cuida a quien hoy está peor que yo. Aunque me duela lo mío, hoy te pido por ellos.',
    'Padre, gracias por cada día que me das. Ninguno me lo debías. Enséñame a contarlos bien.',
    'Señor, toca ese lugar que duele y que ya me acostumbré a cargar. No quiero acostumbrarme más.',
    'Dios, no me sueltes en esta espera. Tú eres el mismo ayer, hoy y siempre, también en la sala de espera.',
    'Padre, sana lo que quedó adentro, eso que nunca dije en voz alta. Tú lo conoces todo y aun así te quedas.',
    'Señor, si esto no se va, que al menos no me quite la fe. Sostenme ahí, que es lo único que no quiero perder.',
  ],
  'perdon': [
    'Señor, límpiame de este rencor que me está pudriendo por dentro. Crea en mí un corazón limpio. Dame la gracia de soltar a quien me hirió, porque con mis fuerzas no puedo.',
    'Dios, todavía no puedo perdonar. Ayúdame por lo menos a querer hacerlo. Empieza tú por donde yo no llego.',
    'Padre, perdóname por lo que hice y por lo que dejé de hacer. Lávame y quedaré más blanco que la nieve.',
    'Señor, sáname de lo que me hicieron. Que la herida no se convierta en la persona que soy.',
    'Dios, ayúdame a soltar la deuda que llevo años cobrando. Tú me perdonaste una mucho más grande.',
    'Padre, gracias porque tú perdonas de verdad, no a medias. Nunca me lo echas en cara. Enséñame a perdonar así.',
    'Señor, bendice a quien me hirió. Cuesta y lo digo con la boca chueca, pero lo digo.',
    'Dios, no quiero volverme como aquello que me dolió. Guarda mi corazón de endurecerse.',
    'Padre, hoy empiezo de nuevo. Gracias porque contigo siempre hay un empezar de nuevo.',
    'Señor, perdóname también por lo que ni recuerdo. Examina mi corazón y muéstrame lo que yo no veo.',
  ],
  'duelo': [
    'Padre, hoy pesa más de lo normal. Tú estás cerca de los quebrantados de corazón. Acércate hoy, aunque yo no tenga fuerzas ni para pedírtelo.',
    'Señor, gracias por lo que viví con esa persona. Nadie me quita eso. Guárdalo tú, que a mí se me borra.',
    'Dios, no sé cómo seguir. Enséñame a caminar de nuevo, aunque sea despacio y agarrado de tu mano.',
    'Padre, guarda mis recuerdos y sana la herida. Que pueda acordarme sin que me parta en dos.',
    'Señor, tú también lloraste frente a una tumba. Eso me consuela más que cualquier explicación.',
    'Dios, acompáñame en los días que nadie ve, cuando ya todos siguieron con su vida y yo no.',
    'Padre, dame fuerzas para hoy. Solo para hoy. Mañana vuelvo a pedirte.',
    'Señor, cuida a los que también están tristes conmigo. Consuélalos donde yo no alcanzo.',
    'Dios, sé que un día no va a doler así. Hoy no es ese día. Sostenme hasta que llegue.',
    'Padre, gracias porque la muerte no tiene la última palabra. Que esa esperanza me alcance hoy, no solo en teoría.',
  ],
  'soledad': [
    'Padre, me siento solo aunque tenga gente alrededor. Tú prometiste no dejarme ni desampararme. Recuérdamelo hoy, que se me olvidó.',
    'Señor, hoy me siento a un lado, como si nadie notara si falto. Tú me ves. Con eso me sostengo.',
    'Dios, gracias porque contigo no tengo que explicar nada ni fingir que estoy bien.',
    'Padre, pon a alguien cerca con quien pueda hablar de verdad. No aguanto más conversaciones de cortesía.',
    'Señor, cuando nadie escribe, tú sigues ahí. Enséñame a buscarte a ti antes que a la pantalla.',
    'Dios, enséñame a buscar a alguien en vez de esconderme. Rompe este muro que yo mismo levanté.',
    'Padre, tú me conoces entero, lo bueno y lo feo, y aun así te quedas. Eso no lo hace nadie más.',
    'Señor, hoy no quiero estar así. Acompáñame. Lléname donde estoy hueco.',
    'Dios, que la tristeza no me convenza de que a nadie le importo. Esa mentira ya me la creí demasiadas veces.',
    'Padre, tú estuviste solo en la cruz para que yo nunca lo estuviera. Que hoy eso sea más fuerte que lo que siento.',
  ],
  'matrimonio': [
    'Señor, cuida lo nuestro cuando estamos cansados y decimos cosas que no sentimos. Que lo que tú uniste no lo separe nuestro mal día.',
    'Dios, ayúdame a escuchar antes de responder. Que sea pronto para oír y tardo para hablar, aunque me hierva por dentro.',
    'Padre, sana lo que dijimos y no debimos. Esas palabras ya no las puedo recoger, pero tú sí puedes curarlas.',
    'Señor, que yo ceda primero. Quiebra mi orgullo antes de que nos quiebre a los dos.',
    'Dios, enséñanos a discutir sin herirnos. Que el enojo no dure hasta que se ponga el sol.',
    'Padre, cuida su corazón hoy, aunque hoy yo esté molesto. Bendícelo igual.',
    'Señor, gracias por quien camina a mi lado. Ayúdame a verlo con los ojos del primer día.',
    'Dios, ayúdame a elegirle también en los días difíciles, que es donde se ve si el amor era de verdad.',
    'Padre, que el orgullo no decida por nosotros. Que decida el amor, aunque cueste más.',
    'Señor, ponnos de acuerdo donde no lo estamos. Y donde no se pueda, danos paz para amarnos igual.',
  ],
  'finanzas': [
    'Señor, no me alcanza y tú lo sabes. Tú alimentaste a miles con cinco panes. Aquí está lo poco que tengo. Provee, Padre, que confío aunque me tiemble la voz.',
    'Dios, quita el miedo que me da mirar la cuenta. Tú vistes los lirios del campo; yo valgo más que ellos.',
    'Padre, dame sabiduría con lo poco y con lo mucho. Que ni la falta ni la abundancia me alejen de ti.',
    'Señor, gracias por lo que hoy sí tengo. No es todo lo que quería, pero es más de lo que muchos tienen.',
    'Dios, que el dinero no me robe la paz ni el sueño. Que mi confianza esté en ti y no en el saldo.',
    'Padre, provee. No te pido de más, te pido el pan de hoy. Y confío en que mañana también estarás.',
    'Señor, ayúdame a no medir mi vida por lo que me falta. Tú eres mi porción y mi herencia.',
    'Dios, enséñame a dar aun cuando me cuesta. Que la mano apretada no me endurezca el corazón.',
    'Padre, esta deuda me está ahogando. No sé cómo se sale. Abre tú la puerta que yo no encuentro.',
    'Señor, hoy elijo confiar en vez de calcular. Jehová es mi pastor, nada me faltará. Que lo crea de verdad.',
  ],
  'manana': [
    'Señor, este día es tuyo antes de ser mío. Tus misericordias son nuevas esta mañana. Que lo primero que busque hoy seas tú y no la pantalla.',
    'Dios, ordena lo que tengo por delante. Yo no sé lo que trae este día, pero tú ya estuviste ahí.',
    'Padre, gracias por despertarme otra vez. No me lo debías. Que no desperdicie lo que me diste.',
    'Señor, dirige mis pasos hoy. Que no me guíe la prisa sino tu Espíritu.',
    'Dios, dame fuerza para lo que hoy me toca, sea lo que sea. Todo lo puedo en ti que me fortaleces.',
    'Padre, acompáñame en cada rato de este día, también en los aburridos y en los que nadie ve.',
    'Señor, hoy empiezo contigo. Con eso ya cambia todo lo demás.',
    'Dios, guía las decisiones que tome hoy, las grandes y las chiquitas. Que ninguna me aleje de ti.',
    'Padre, que hoy alguien vea algo de ti en mí, aunque yo ni me dé cuenta.',
    'Señor, antes de que el día me agarre, quiero agarrarme de ti. Aquí estoy.',
  ],
  'noche': [
    'Padre, gracias por hoy, con todo lo que trajo. Lo que no resolví te lo entrego. En paz me acuesto y duermo, porque solo tú me haces vivir confiado.',
    'Señor, perdóname por lo de hoy. No quiero llevarme esto a la cama. Límpiame y mañana empiezo de nuevo.',
    'Dios, apaga mi cabeza y dame descanso. Tú das a tu amado el sueño; hoy te lo pido de verdad.',
    'Padre, cuida a los míos mientras duermen. Pon tus ángeles alrededor de esta casa.',
    'Señor, lo que no resolví hoy, te lo dejo. No lo voy a arreglar dándole vueltas a las tres de la mañana.',
    'Dios, gracias por lo bueno que ni noté hoy. Abre mis ojos mañana para verlo a tiempo.',
    'Padre, si alguien se acostó peor que yo esta noche, consuélalo tú. Te lo pido antes de dormirme.',
    'Señor, mañana será mejor contigo. Y si no lo es, igual estarás. Con eso me duermo.',
    'Dios, cierra este día con tu paz. Que lo último que piense hoy seas tú.',
    'Padre, gracias por estar también en las noches largas. Aquí estoy, en tus manos, hasta mañana.',
  ],
};

/// Pocas universales: solo para que nunca quede vacío.
const List<String> _universales = [
  'Señor, aquí estoy. Gracias por este alto en medio del día. Que no sea el último de hoy.',
  'Padre, un minuto contigo y sigo. Sostenme el resto del camino.',
  'Dios, gracias porque puedo hablarte en cualquier momento y no tengo que sacar cita.',
];

/// Lista de oraciones según las necesidades elegidas.
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

/// Calcula la lista personalizada y la guarda para la pantalla nativa.
Future<void> syncGatePrayers(PrefsService prefs) async {
  final lista = buildGatePrayers(prefs.preferredCategories);
  await prefs.setGatePrayersJson(jsonEncode(lista));
}
