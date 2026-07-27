import 'package:flutter/widgets.dart';

/// Llave global del Navigator, para poder navegar desde fuera del arbol de
/// widgets (por ejemplo, al tocar una notificacion). La usa `main.dart`
/// (MaterialApp.navigatorKey) y `NotificationService`.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Payload que llevan los recordatorios de la hora: al tocarlos, la app
/// abre la pantalla "momento de oracion".
const String kMomentoPayload = 'momento_oracion';
