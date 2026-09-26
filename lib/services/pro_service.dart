import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config.dart';
import 'app_state.dart';

/// Einmaliger Kauf „Redewendix Pro“ über App Store / Google Play.
///
/// Der Kaufstatus wird in [AppState.isPro] gespeichert, damit Pro auch ohne
/// Netz sofort gilt. Beim Wiederherstellen fragt die App den Store erneut.
class ProService extends ChangeNotifier {
  ProService({InAppPurchase? store}) : _storeOverride = store;

  final InAppPurchase? _storeOverride;
  InAppPurchase get _store => _storeOverride ?? InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  AppState? _state;

  ProductDetails? _product;
  bool _available = false;
  bool _busy = false;
  String? _error;

  /// Preis laut Store, z. B. „2,99 €“; null, solange unbekannt.
  String? get price => _product?.price;

  /// Store erreichbar und Produkt gefunden.
  bool get available => _available && _product != null;

  /// Kauf oder Wiederherstellen läuft.
  bool get busy => _busy;

  /// Letzter Fehler für die Anzeige.
  String? get error => _error;

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init(AppState state) async {
    _state = state;
    if (!_supported && _storeOverride == null) return;
    _sub = _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) => _fail('Der Store meldet einen Fehler.'),
    );
    try {
      _available = await _store.isAvailable();
      if (!_available) return;
      final response = await _store.queryProductDetails({kProProductId});
      _product = response.productDetails
          .where((p) => p.id == kProProductId)
          .firstOrNull;
    } catch (e) {
      debugPrint('Pro: $e');
    }
    notifyListeners();
  }

  Future<void> buy() async {
    final product = _product;
    if (product == null || _busy) return;
    _setBusy(true);
    try {
      final started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) _fail('Der Kauf konnte nicht gestartet werden.');
    } catch (e) {
      _fail('Der Kauf konnte nicht gestartet werden.');
    }
  }

  Future<void> restore() async {
    if (_busy) return;
    _setBusy(true);
    try {
      await _store.restorePurchases();
      // Ohne frühere Käufe kommt kein Ereignis – nach kurzer Zeit freigeben.
      Timer(const Duration(seconds: 8), () {
        if (_busy) _setBusy(false);
      });
    } catch (e) {
      _fail('Wiederherstellen ist fehlgeschlagen.');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != kProProductId) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          _setBusy(true);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _state?.setPro(true);
          _error = null;
          _setBusy(false);
        case PurchaseStatus.error:
          _fail('Der Kauf ist fehlgeschlagen.');
        case PurchaseStatus.canceled:
          _setBusy(false);
      }
      if (p.pendingCompletePurchase) {
        await _store.completePurchase(p);
      }
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    if (value) _error = null;
    notifyListeners();
  }

  void _fail(String message) {
    _error = message;
    _busy = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
