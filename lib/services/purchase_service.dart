import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'prefs_service.dart';

/// Planes que la pantalla de paywall puede ofrecer.
enum PlusPlan { pruebaMensual, semanal, mensual, anual }

/// Resultado de un intento de compra, para que la pantalla sepa qué mostrar.
enum ResultadoCompra {
  exito,
  cancelada,
  yaSuscrito,
  productoNoDisponible,
  sinRed,
  error,
}

/// Monetizacion real con RevenueCat.
///
/// La unica fuente de verdad de Premium es el entitlement [entitlementId] que
/// devuelve RevenueCat en el CustomerInfo. Nunca se marca Premium por haber
/// pulsado un boton.
class PurchaseService extends ChangeNotifier {
  /// Clave de PRUEBA de RevenueCat. Reemplazar por la de produccion antes de
  /// publicar.
  static const apiKeyAndroid = 'goog_EGkmXjcdLzZPVccQnPxJSUdNIBN';

  /// Entitlement configurado en el panel de RevenueCat.
  static const entitlementId = 'ora_ahora_pro';

  /// Identificadores de los paquetes dentro del offering.
  static const idAnual = 'yearly';
  static const idMensual = 'monthly';

  final PrefsService _prefs;
  PurchaseService(this._prefs);

  bool _premium = false;
  bool _listo = false;
  Offering? _offering;
  String? _errorOffering;

  /// Premium segun RevenueCat. Antes de la primera consulta se usa el ultimo
  /// valor conocido para no parpadear, pero nunca para conceder acceso nuevo.
  bool get isPlusUser => _listo ? _premium : _prefs.isPlusUser;

  bool get listo => _listo;
  Offering? get offering => _offering;
  String? get errorOffering => _errorOffering;

  /// Precios reales traidos de la tienda. Si el offering todavia no cargo,
  /// se muestran los de referencia para que la pantalla no quede vacia.
  String get precioAnualTienda =>
      _paquete(idAnual)?.storeProduct.priceString ?? precioAnual;
  String get precioMensualTienda =>
      _paquete(idMensual)?.storeProduct.priceString ?? precioMensual;

  // Precios de referencia. Los reales mandan.
  static const precioMensual = r'$2.99 USD/mes';
  static const precioAnual = r'$19.99 USD/año';
  static const precioAnualEquiv = r'equivale a $1.67 USD/mes';
  static const precioSemanal = r'$1.99 USD/semana';
  static const textoPrueba = r'Luego $19.99 USD/año';

  Package? _paquete(String id) {
    final o = _offering;
    if (o == null) return null;

    // RevenueCat nombra los paquetes estandar \$rc_annual y \$rc_monthly,
    // mientras que idAnual/idMensual son los IDs de producto de Google Play.
    // Por eso se busca primero por tipo de paquete y solo despues por
    // identificador de paquete o de producto.
    final tipo = id == idAnual ? PackageType.annual : PackageType.monthly;
    for (final p in o.availablePackages) {
      if (p.packageType == tipo) return p;
    }
    for (final p in o.availablePackages) {
      if (p.identifier == id) return p;
    }
    for (final p in o.availablePackages) {
      final producto = p.storeProduct.identifier;
      if (producto == id || producto.split(':').first == id) return p;
    }
    return null;
  }

  /// Arranca RevenueCat. Se llama una sola vez al iniciar la app.
  Future<void> init() async {
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(apiKeyAndroid));
      Purchases.addCustomerInfoUpdateListener(_alActualizarCliente);
      await refrescarEstado();
      await cargarOffering();
    } catch (e) {
      debugPrint('RevenueCat no pudo iniciar: $e');
      _listo = false;
      notifyListeners();
    }
  }

  void _alActualizarCliente(CustomerInfo info) {
    _aplicar(info);
  }

  void _aplicar(CustomerInfo info) {
    final activo = info.entitlements.active.containsKey(entitlementId);
    _premium = activo;
    _listo = true;
    // Copia local solo como cache para el resto de la app (por ejemplo la
    // notificacion nativa). Nunca es la fuente de verdad.
    _prefs.setIsPlusUser(activo);
    notifyListeners();
  }

  /// Consulta el estado real en RevenueCat.
  Future<void> refrescarEstado() async {
    try {
      final info = await Purchases.getCustomerInfo();
      _aplicar(info);
    } catch (e) {
      debugPrint('No se pudo leer CustomerInfo: $e');
    }
  }

  /// Trae el offering actual con sus paquetes.
  Future<void> cargarOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      final actual = offerings.current;
      if (actual == null || actual.availablePackages.isEmpty) {
        _offering = null;
        _errorOffering = 'No hay planes disponibles todavía.';
      } else {
        _offering = actual;
        _errorOffering = null;
      }
    } on PlatformException catch (e) {
      _offering = null;
      _errorOffering = 'No pudimos conectar con la tienda. ${e.message ?? ''}';
    } catch (e) {
      _offering = null;
      _errorOffering = 'No pudimos conectar con la tienda.';
    }
    notifyListeners();
  }

  /// Compra real. Solo devuelve exito si el entitlement queda activo.
  Future<ResultadoCompra> purchase(PlusPlan plan) async {
    if (isPlusUser) return ResultadoCompra.yaSuscrito;

    final id = plan == PlusPlan.anual ? idAnual : idMensual;
    var paquete = _paquete(id);
    if (paquete == null) {
      await cargarOffering();
      paquete = _paquete(id);
    }
    if (paquete == null) return ResultadoCompra.productoNoDisponible;

    try {
      final resultado = await Purchases.purchasePackage(paquete);
      _aplicar(resultado.customerInfo);
      return _premium ? ResultadoCompra.exito : ResultadoCompra.error;
    } on PlatformException catch (e) {
      final codigo = PurchasesErrorHelper.getErrorCode(e);
      switch (codigo) {
        case PurchasesErrorCode.purchaseCancelledError:
          return ResultadoCompra.cancelada;
        case PurchasesErrorCode.productAlreadyPurchasedError:
          await refrescarEstado();
          return ResultadoCompra.yaSuscrito;
        case PurchasesErrorCode.productNotAvailableForPurchaseError:
        case PurchasesErrorCode.purchaseNotAllowedError:
          return ResultadoCompra.productoNoDisponible;
        case PurchasesErrorCode.networkError:
        case PurchasesErrorCode.offlineConnectionError:
          return ResultadoCompra.sinRed;
        default:
          debugPrint('Error de compra: $codigo');
          return ResultadoCompra.error;
      }
    } catch (e) {
      debugPrint('Error de compra: $e');
      return ResultadoCompra.error;
    }
  }

  /// Restaura compras anteriores desde la cuenta de Google Play.
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      _aplicar(info);
      return _premium;
    } catch (e) {
      debugPrint('No se pudo restaurar: $e');
      return false;
    }
  }

  /// Centro de cliente de RevenueCat. Queda disponible por si se quiere abrir
  /// desde Ajustes; no cambia la navegacion actual.
  Future<void> abrirCentroDeCliente() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint('Centro de cliente no disponible: $e');
    }
  }
}
