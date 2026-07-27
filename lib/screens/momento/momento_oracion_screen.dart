import 'package:flutter/material.dart';
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
  const MomentoOracionScreen({super.key});

  /// Oraciones cortas, voz del ICP, lenguaje NEUTRO (no asume genero).
  /// Se elige una por dia para que vaya cambiando.
  static const List<String> _oraciones = [
    'Señor, aquí estoy. antes que nada y antes que nadie, quiero buscarte '
        'a ti. gracias por esperarme.\n\nAmén.',
    'Dios, este ratito es tuyo. calma lo que traigo por dentro y '
        'recuérdame que estás cerca.\n\nAmén.',
    'Padre, gracias por hoy. ayúdame a no dejarte para el final del día. '
        'quiero volver a ti.\n\nAmén.',
    'Jesús, sé que me distraigo fácil. hoy elijo parar un momento y '
        'hablarte. gracias por escucharme.\n\nAmén.',
    'Señor, no traigo palabras bonitas, solo mi corazón. quédate conmigo '
        'en lo que venga hoy.\n\nAmén.',
    'Dios, gracias porque no te cansas de mí. dame paz y guíame en lo de '
        'hoy.\n\nAmén.',
    'Padre, aquí me tienes otra vez. gracias por recibirme sin reproches. '
        'te necesito.\n\nAmén.',
    'Señor, ordena mi día y mi mente. que lo primero seas tú, no la '
        'pantalla.\n\nAmén.',
  ];

  String get _oracionDeHoy {
    final now = DateTime.now();
    final doy = now.difference(DateTime(now.year, 1, 1)).inDays;
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
