import 'package:flutter/material.dart';

import '../../data/gate_prayers.dart';
import 'package:provider/provider.dart';

import '../../services/purchase_service.dart';
import '../../services/streak_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../home/home_screen.dart';

/// Pantalla a la que se llega al TOCAR el recordatorio de la hora (v29).
///
/// En vez de dejar a la persona en un menu, cae directo en una oracion
/// CORTA que puede rezar en 30 segundos. El boton "Amen, ya ore" cuenta
/// igual que orar dentro de la app: riega la plantita y sube la racha
/// (usa `StreakService.markPrayedToday`, la misma fuente de verdad).
class MomentoOracionScreen extends StatelessWidget {
  /// Tema concreto por el que orar. Llega cuando la persona toca la
  /// notificacion, para que la oracion sea la suya y no una generica.
  final String? categoria;
  const MomentoOracionScreen({super.key, this.categoria});

  /// Oraciones cortas, voz del ICP, lenguaje NEUTRO (no asume genero).
  /// Se elige una por dia para que vaya cambiando.
  static const List<String> _oraciones = [
    'Señor, aquí estoy. Antes que nada y antes que nadie, quiero buscarte a ti.\n\nGracias por esperarme todo este tiempo sin reclamarme nada. Tú sabes por dónde anduve y aun así me recibes.\n\nToma este día antes de que empiece.\n\nAmén.',
    'Padre, hoy vengo cansado. No traigo palabras bonitas, traigo lo que hay.\n\nTú eres refugio y fortaleza, pronto auxilio en la tribulación. Hoy necesito que seas eso y no una frase que me sé de memoria.\n\nRenueva mis fuerzas, que las mías ya se acabaron.\n\nAmén.',
    'Dios, este ratito es tuyo. Calma lo que traigo por dentro.\n\nTú calmaste el mar con una sola palabra. Calma también esta tormenta que nadie ve pero que a mí no me deja dormir.\n\nY si todavía no la calmas, quédate conmigo dentro de ella.\n\nAmén.',
    'Señor, sé que me distraigo fácil. Hoy elijo parar un momento y hablarte.\n\nPerdóname por dejarte para el final del día, cuando ya no me queda nada. Hoy quiero darte lo primero y no lo que sobra.\n\nGracias por escucharme igual, siempre.\n\nAmén.',
    'Padre, aquí estoy otra vez. Gracias porque me recibes sin reproches.\n\nCada vez que vuelvo tú estás en el mismo lugar, esperando. Tus misericordias son nuevas cada mañana y hoy me tocó otra.\n\nHazme fiel hoy, aunque sea solo hoy.\n\nAmén.',
    'Señor, ordena mi día y mi cabeza. Que lo primero sea tu voz y no la pantalla.\n\nGuarda mi corazón y mis pensamientos, que se me van solos a donde no debo.\n\nDirige tú mis pasos, porque yo solo me pierdo.\n\nAmén.',
    'Dios, cuando quiera huir a la pantalla, recuérdame que tú me llenas.\n\nSé lo que estoy buscando ahí y sé que nunca lo encuentro. Solo tú llenas ese hueco que ninguna otra cosa alcanza.\n\nSostenme, que hoy me siento débil.\n\nAmén.',
    'Padre, calma mi cabeza. Hoy quiero caminar contigo y no correr solo.\n\nQuítame la prisa que no viene de ti. Enséñame a estar quieto y saber que tú eres Dios.\n\nQue tu paz guarde este día completo.\n\nAmén.',
    'Jesús, perdona que te dejo para el final. Hoy empiezo por ti.\n\nGracias porque no me cobras las ausencias ni me pasas factura. Solo abres la puerta otra vez, como si nada.\n\nQue hoy alguien vea algo de ti en mí, aunque yo ni me dé cuenta.\n\nAmén.',
    'Señor, no traigo palabras bonitas, solo mi corazón. Quédate conmigo en lo que venga hoy.\n\nTú conoces lo que ni yo sé explicar. Examíname y muéstrame qué tengo que soltar.\n\nAquí estoy. Haz tu obra en mí.\n\nAmén.',
    'Padre, gracias por hoy antes de que pase nada. Gracias por lo que ya me diste y ni valoro.\n\nAbre mis ojos para ver tu bondad en las cosas chiquitas, esas que se me pasan de largo todos los días.\n\nQue hoy sepa darte gracias sin pedirte nada.\n\nAmén.',
    'Dios, hoy no tengo ganas. Ni de esto ni de casi nada.\n\nPero vine igual, porque te lo prometí. Y sé que tú no mides mis ganas, mides que haya venido.\n\nHazte cargo tú de lo que a mí hoy me falta.\n\nAmén.',
  ];

  String get _oracionDeHoy {
    final now = DateTime.now();
    final doy = now.difference(DateTime(now.year, 1, 1)).inDays;
    // Si venimos de la notificacion, oramos por ese tema concreto.
    if (categoria != null) {
      final delTema = buildGatePrayers([categoria!]);
      if (delTema.isNotEmpty) {
        return delTema[now.millisecondsSinceEpoch ~/ 60000 % delTema.length];
      }
    }
    return _oraciones[doy % _oraciones.length];
  }

  Future<void> _confirmar(BuildContext context) async {
    final streak = context.read<StreakService>();
    final isPlus = context.read<PurchaseService>().isPlusUser;
    if (streak.prayedToday) {
      await streak.addExtraMinutes(2);
    } else {
      await streak.markPrayedToday(isPlusUser: isPlus, minutes: 2);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Amén! regaste tu fe hoy 🌱')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _verMas(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text('tu momento de hoy 🙏',
                  textAlign: TextAlign.center,
                  style: AppTypography.display.copyWith(fontSize: 26)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.tealLight),
                ),
                child: Text(
                  _oracionDeHoy,
                  textAlign: TextAlign.center,
                  style: AppTypography.quote.copyWith(
                    fontSize: 18,
                    height: 1.5,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _confirmar(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealDeep,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Amén, ya oré 🙏'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => _verMas(context),
                  child: Text('ver más oraciones',
                      style: AppTypography.body
                          .copyWith(color: AppColors.inkSoft)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
