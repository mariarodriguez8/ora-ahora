import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app_globals.dart';
import 'screens/home/home_screen.dart';
import 'screens/momento/momento_oracion_screen.dart';
import 'screens/onboarding/onboarding_welcome_screen.dart';
import 'services/appearance_service.dart';
import 'services/gate_service.dart';
import 'services/journal_repository.dart';
import 'services/notification_service.dart';
import 'services/prayer_repository.dart';
import 'data/gate_prayers.dart';
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
  // Recordatorios a prueba de reinicios y de limpiadores de memoria
  // (Huawei/Xiaomi): se reprograman en CADA apertura de la app.
  try {
    await notificationService.refreshSchedule(prefsService.reminderTimes);
  } catch (_) {}

  // Oraciones de la pausa personalizadas segun las necesidades elegidas.
  try {
    await syncGatePrayers(prefsService);
  } catch (_) {}

  // v29: ¿la app se abrió por tocar un recordatorio de la hora? Si es así,
  // al primer frame la llevamos directo a la pantalla de "momento de
  // oración" (oración corta + "Amén, ya oré").
  final abrirMomento = await notificationService.wasLaunchedByNotification();

  runApp(OraAhoraApp(
    prefsService: prefsService,
    notificationService: notificationService,
  ));

  if (abrirMomento) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const MomentoOracionScreen()),
      );
    });
  }
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
          create: (_) => PurchaseService(prefsService)..init(),
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
            final palette = AppPalette.byId(explicitId);
            final themeData = AppTheme.fromPalette(palette, simpleMode: simpleMode);
            lightTheme = themeData;
            darkTheme = themeData;
            themeMode = palette.isDark ? ThemeMode.dark : ThemeMode.light;
          } else {
            lightTheme = AppTheme.fromPalette(AppPalette.zafiroCalmo, simpleMode: simpleMode);
            darkTheme = AppTheme.fromPalette(AppPalette.maresProfundos, simpleMode: simpleMode);
            themeMode = ThemeMode.light;
          }

          return MaterialApp(
            title: 'Ora Ahora',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            locale: const Locale('es'),
            supportedLocales: const [Locale('es')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            navigatorObservers: [appRouteObserver],
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();
              if (!simpleMode) return child;
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
