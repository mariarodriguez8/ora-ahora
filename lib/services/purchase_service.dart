import 'package:flutter/foundation.dart';

import 'prefs_service.dart';

/// Planes disponibles de Ora Ahora Plus.
enum PlusPlan { mensual, anual }

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

  static const precioMensual = r'$4.99 USD/mes';
  static const precioAnual = r'$39.99 USD/año';

  /// Precio anual reformulado como monto diario equivalente
  /// ($39.99 / 365 dias ~= $0.11 USD/dia), para que la comparacion de
  /// valor sea mas concreta en el paywall (practica estandar y
  /// transparente de la industria, no un patron oscuro: el precio total
  /// real sigue mostrandose siempre junto a este).
  static const precioAnualDiario = r'equivale a $0.11 USD/día';

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
