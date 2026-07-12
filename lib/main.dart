import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_welcome_screen.dart';
import 'services/appearance_service.dart';
import 'services/gate_service.dart';
import 'services/journal_repository.dart';
import 'services/notification_service.dart';
import 'services/prayer_repository.dart';
import 'services/prefs_service.dart';
import 'services/purchase_service.dart';
import 'services/route_observer.dart';
import 'services/streak_service.dart';
import 'theme/app_palettes.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es');
  Intl.defaultLocale = 'es';

  final prefsService = await PrefsService.create();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(OraAhoraApp(
    prefsService: prefsService,
    notificationService: notificationService,
  ));
}

class OraAhoraApp extends StatelessWidget {
  final PrefsService prefsService;
  final NotificationService notificationService;

  const OraAhoraApp({
    super.key,
    required this.prefsService,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PrefsService>.value(value: prefsService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<PrayerRepository>(create: (_) => PrayerRepository()),
        Provider<JournalRepository>(create: (_) => JournalRepository()),
        ChangeNotifierProvider<StreakService>(
          create: (_) => StreakService(prefsService),
        ),
        ChangeNotifierProvider<PurchaseService>(
          create: (_) => PurchaseService(prefsService),
        ),
        ChangeNotifierProvider<GateService>(
          create: (_) => GateService(prefsService),
        ),
        ChangeNotifierProvider<AppearanceService>(
          create: (_) => AppearanceService(prefsService),
        ),
      ],
      child: Consumer<AppearanceService>(
        builder: (context, appearance, _) {
          final explicitId = appearance.explicitPaletteId;
          final simpleMode = appearance.simpleModeEnabled;

          final ThemeData lightTheme;
          final ThemeData darkTheme;
          final ThemeMode themeMode;

          if (explicitId != null) {
            // El usuario eligio una paleta a mano: se usa siempre esa
            // misma paleta (tanto para `theme` como `darkTheme`) y se fija
            // `themeMode` a su propio brillo, para que el modo claro/
            // oscuro del sistema no la "reemplace".
            final palette = AppPalette.byId(explicitId);
            final themeData = AppTheme.fromPalette(palette, simpleMode: simpleMode);
            lightTheme = themeData;
            darkTheme = themeData;
            themeMode = palette.isDark ? ThemeMode.dark : ThemeMode.light;
          } else {
            // Sin preferencia explicita: Zafiro Calmo (clara, alto
            // contraste) en modo claro, Mares Profundos (oscura) en modo
            // oscuro, siguiendo el ajuste del sistema operativo.
            lightTheme = AppTheme.fromPalette(AppPalette.zafiroCalmo, simpleMode: simpleMode);
            darkTheme = AppTheme.fromPalette(AppPalette.maresProfundos, simpleMode: simpleMode);
            themeMode = ThemeMode.system;
          }

          return MaterialApp(
            title: 'Ora Ahora',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            locale: const Locale('es'),
            supportedLocales: const [Locale('es')],
            navigatorObservers: [appRouteObserver],
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();
              if (!simpleMode) return child;
              // "Modo Simple": agranda TODO el texto de la app (incluidos
              // los estilos de `AppTypography` usados directamente, no
              // solo `Theme.of(context).textTheme`), aplicando el escalado
              // a nivel de MediaQuery en la raiz del arbol de widgets.
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: const TextScaler.linear(1.2),
                ),
                child: child,
              );
            },
            home: prefsService.onboardingComplete
                ? const HomeScreen()
                : const OnboardingWelcomeScreen(),
          );
        },
      ),
    );
  }
}
