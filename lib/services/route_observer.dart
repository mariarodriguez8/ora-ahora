import 'package:flutter/material.dart';

/// Observador de rutas compartido de toda la app, registrado una sola vez
/// en `MaterialApp.navigatorObservers` (ver `main.dart`).
///
/// Se usa hoy para que la pestaña de Inicio (`HomeScreen`/`_HomeFeedTab`)
/// pueda detectar el momento exacto en que el usuario *vuelve* a verla
/// (`RouteAware.didPopNext`), por ejemplo despues de cerrar
/// `PrayerDetailScreen` tras marcar una oracion como orada. Eso permite
/// mostrar la celebracion de hito de racha cuando el Inicio realmente
/// vuelve a estar visible, en vez de dispararla mientras esta tapado por
/// otra pantalla (donde el usuario no la veria).
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
