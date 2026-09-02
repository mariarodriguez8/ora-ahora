import 'package:flutter/foundation.dart';

import 'prefs_service.dart';

/// Planes disponibles de Ora Ahora Plus.
enum PlusPlan { pruebaMensual, semanal, mensual, anual }

/// Servicio de compras "stub" para el MVP.
///
/// IMPORTANTE: esto NO procesa pagos reales todavia. Sirve para que toda la
/// pantalla de paywall y la logica de "usuario Plus" funcionen de extremo a
/// extremo en el MVP, dejando un unico punto de integracion futuro.
///
/// TODO: integrar RevenueCat (recomendado, simplifica recibos/validacion en
/// ambas tiendas) o directamente Play Billing Library a traves del paquete
/// `in_app_purchase` / `in_app_purchase_android`. Esa integracion requiere:
///   1. Crear los productos de suscripcion en Play Console (IDs, precios).
///   2. Configurar RevenueCat (o Billing) con esos IDs de producto.
///   3. Reemplazar los metodos `purchase*` de esta clase para llamar al SDK
///      real y reemplazar `restorePurchases` para consultar el estado real
///      de la suscripcion en la tienda.
///   4. Mantener `_prefs.setIsPlusUser` como la fuente de verdad local que
///      lee el resto de la app (para no tener que tocar las pantallas).
class PurchaseService extends ChangeNotifier {
  final PrefsService _prefs;

  PurchaseService(this._prefs);

  bool get isPlusUser => _prefs.isPlusUser;

  // Precios de EJEMPLO (Maria puede cambiarlos; deben coincidir con los
  // productos configurados en Play Console).
  static const precioMensual = r'$2.99 USD/mes';
  static const precioAnual = r'$19.99 USD/año';
  static const precioAnualEquiv = r'equivale a $1.67 USD/mes';
  static const precioSemanal = r'$1.99 USD/semana';
  // La prueba gratis dura 3 dias y al terminar cobra el plan MENSUAL.
  // (El titulo de la opcion ya dice "Prueba 3 días gratis", aqui solo el
  // precio para no repetir ni encimar textos.)
  static const textoPrueba = r'Luego $4.99 USD/mes';

  /// Simula la compra del plan mensual. En producción esto debe abrir el
  /// flujo de compra nativo de Google Play a través de RevenueCat/Billing.
  Future<bool> purchase(PlusPlan plan) async {
    // TODO: integrar RevenueCat o Play Billing aqui. Por ahora, simulamos
    // una compra exitosa localmente para poder probar el resto del flujo
    // (paywall -> desbloqueo de funciones Plus) sin backend de pagos.
    await Future.delayed(const Duration(milliseconds: 400));
    await _prefs.setIsPlusUser(true);
    notifyListeners();
    return true;
  }

  /// Simula restaurar compras anteriores (normalmente consultaria la tienda
  /// o RevenueCat). En el MVP solo respeta el estado local ya guardado.
  Future<bool> restorePurchases() async {
    // TODO: reemplazar por una consulta real a RevenueCat/Play Billing.
    await Future.delayed(const Duration(milliseconds: 300));
    notifyListeners();
    return isPlusUser;
  }

  /// Utilidad para pruebas manuales durante el desarrollo: revierte el
  /// estado Plus. No debe exponerse en una build de producción final.
  Future<void> debugResetPlus() async {
    await _prefs.setIsPlusUser(false);
    notifyListeners();
  }
}
