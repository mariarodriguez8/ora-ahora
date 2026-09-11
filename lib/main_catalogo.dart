// Catalogo visual: las pantallas del embudo, una al lado de otra.
//
// No forma parte de la app. Existe para poder MIRAR las pantallas en un
// navegador y juzgar la composicion con los ojos, que es lo unico que
// detecta un texto encima de otro o un dibujo que queda mal. Las pruebas
// solo cazan desbordes.
//
//   flutter build web -t lib/main_catalogo.dart
import 'package:flutter/material.dart';

import 'screens/onboarding/funnel_screens.dart';
import 'screens/onboarding/funnel_parabola.dart';
import 'package:provider/provider.dart';
import 'screens/onboarding/onboarding_welcome_screen.dart';
import 'screens/onboarding/onboarding_name_screen.dart';
import 'services/prefs_service.dart';
import 'services/streak_service.dart';
import 'services/purchase_service.dart';
import 'services/gate_service.dart';
import 'services/appearance_service.dart';
import 'theme/app_theme.dart';

void _nada() {}

late PrefsService prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await PrefsService.create();
  runApp(
    MultiProvider(
      providers: [
        Provider<PrefsService>.value(value: prefs),
        ChangeNotifierProvider(create: (_) => StreakService(prefs)),
        ChangeNotifierProvider(create: (_) => PurchaseService(prefs)),
        ChangeNotifierProvider(create: (_) => GateService(prefs)),
        ChangeNotifierProvider(create: (_) => AppearanceService(prefs)),
      ],
      child: const Catalogo(),
    ),
  );
}

final _pantallas = <String, Widget>{
  '0 BIENVENIDA': const OnboardingWelcomeScreen(),
  '0b tu nombre': const OnboardingNameScreen(),
  '8 la cancion': FunnelCancion(),
  '4 el espejo': FunnelMirror(),
  '1 te ha pasado': FunnelQ1(),
  '2 horas de celular': FunnelQ2(),
  '3 tiempo con Dios': FunnelQ3(),
  '4 el espejo': FunnelMirror(),
  '5 TEN parabola': FunnelParabola(onContinuar: _nada),
  '6 KETSU telefono': FunnelKetsu(onContinuar: _nada),
  '7 el minuto': FunnelMinute(),
};

class Catalogo extends StatelessWidget {
  const Catalogo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        backgroundColor: const Color(0xFF2B2B2B),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final p in _pantallas.entries)
                SizedBox(
                  width: 288,
                  child: Column(
                    children: [
                      Text(p.key,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      // Medida de un movil corriente en Latinoamerica.
                      Container(
                        width: 288,
                        height: 660,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: MediaQuery(
                          data: const MediaQueryData(size: Size(360, 740)),
                          child: p.value,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
