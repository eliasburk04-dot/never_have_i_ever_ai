import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logger/logger.dart';

import '../core/constants/app_constants.dart';

/// Handles in-app purchases via StoreKit 2 / Google Play Billing.
class PurchaseService {
  final _log = Logger();
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isPremium = false;

  /// Whether the user has premium access.
  bool get isPremium => _isPremium;

  /// Initialize the purchase listener. Call once in main().
  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) {
      _log.w('In-app purchases not available on this device');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) => _log.e('Purchase stream error', error: error),
    );

    // Restore / check existing purchases on startup
    await restorePurchases();
    _log.i('PurchaseService initialized');
  }

  /// Purchase lifetime premium.
  Future<bool> purchasePremium() async {
    final available = await _iap.isAvailable();
    if (!available) {
      _log.w('Store not available');
      return false;
    }

    final response = await _iap.queryProductDetails(
      {AppConstants.lifetimeProductId},
    );

    if (response.productDetails.isEmpty) {
      _log.w('Product not found: ${AppConstants.lifetimeProductId}');
      return false;
    }

    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);

    // Non-consumable (lifetime)
    final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!started) {
      _log.w('Purchase flow could not be started');
    }
    return started;
  }

  /// Restore previous purchases.
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  /// Handle incoming purchase updates from the stream.
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == AppConstants.lifetimeProductId) {
            _isPremium = true;
            _log.i('Premium unlocked via ${purchase.status}');
          }
          // Complete the purchase so the store clears it
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
        case PurchaseStatus.error:
          _log.e('Purchase error: ${purchase.error}');
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
        case PurchaseStatus.canceled:
          _log.i('Purchase cancelled by user');
        case PurchaseStatus.pending:
          _log.i('Purchase pending...');
      }
    }
  }

  /// Dispose the purchase stream subscription.
  void dispose() {
    _subscription?.cancel();
  }
}
