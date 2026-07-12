/// Fuente de "prueba social" (social proof) cuantificada para el inicio.
///
/// PRINCIPIO ANTI DARK-PATTERN DE ESTE PROYECTO: Ora Ahora nunca muestra un
/// numero especifico e inventado (por ejemplo, "2,340 personas orando
/// ahora mismo") como si fuera un dato real cuando no lo es. Eso seria
/// prueba social falsa, un patron oscuro clasico que erosiona la confianza
/// apenas alguien se da cuenta. Mientras no exista un backend real que
/// agregue usuarios activos de verdad, la unica implementacion disponible
/// ([StubCommunityStatsService]) devuelve `null`, y la pantalla de Inicio
/// debe caer siempre a un copy honesto y no cuantificado en ese caso (ver
/// `_SocialProofBanner` en `home_screen.dart`).
abstract class CommunityStatsService {
  /// Estimacion del numero de personas orando "ahora" en la app, o `null`
  /// si no hay una fuente de datos real conectada todavia. Cualquier
  /// implementacion futura de este metodo debe basarse en datos agregados
  /// reales (nunca en un numero inventado o embellecido).
  Future<int?> getPrayingNowEstimate();
}

/// Implementacion usada en este MVP: no hay ningun backend (Firebase,
/// Supabase, etc.) que agregue usuarios activos reales todavia, asi que
/// siempre devuelve `null`. Esto NO es un placeholder de un numero que
/// "pronto" se activara con datos falsos: es, a proposito, la unica opcion
/// honesta hasta que exista una fuente de datos real.
///
/// TODO: wire to a real backend (Firebase/Supabase) that aggregates actual
/// active users before enabling a live counter. Cuando eso exista, se debe
/// crear una nueva implementacion de [CommunityStatsService] (o reemplazar
/// esta) que consulte ese backend y devuelva el numero real agregado --
/// nunca un valor inventado ni una aproximacion sin fundamento.
class StubCommunityStatsService implements CommunityStatsService {
  const StubCommunityStatsService();

  @override
  Future<int?> getPrayingNowEstimate() async {
    return null;
  }
}
