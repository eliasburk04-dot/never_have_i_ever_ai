import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logger/logger.dart';

import '../core/constants/app_constants.dart';

/// Custom in-app purchase service using Apple StoreKit 2 via
/// the official `in_app_purchase` Flutter plugin. No third-party
/// payment SDK required.
class StoreKitService {
  StoreKitService();

  final _log = Logger();
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _purchaseCompleter = <String, Completer<bool>>{};

  ProductDetails? _premiumProduct;

  /// Cached product price string for UI display (e.g. "$4.99").
  String get priceString => _premiumProduct?.price ?? '\$4.99';

  /// Whether IAP is available on this device.
  bool _available = false;
  bool get isAvailable => _available;

  // ─── Lifecycle ────────────────────────────────────────

  /// Initialize the IAP connection and start listening for purchase updates.
  Future<void> initialize() async {
    if (!Platform.isIOS) {
      _log.w('StoreKit is only available on iOS');
      return;
    }

    _available = await _iap.isAvailable();
    if (!_available) {
      _log.w('In-app purchases not available on this device');
      return;
    }

    // Listen for purchase updates (required by the plugin).
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => _log.e('Purchase stream error', error: error),
    );

    // Pre-fetch product details.
    await _loadProducts();
  }

  /// Dispose subscriptions.
  void dispose() {
    _subscription?.cancel();
  }

  // ─── Product loading ──────────────────────────────────

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(
      {AppConstants.lifetimeProductId},
    );

    if (response.notFoundIDs.isNotEmpty) {
      _log.w('Product(s) not found: ${response.notFoundIDs}');
    }

    if (response.error != null) {
      _log.e('Error loading products', error: response.error);
      return;
    }

    if (response.productDetails.isNotEmpty) {
      _premiumProduct = response.productDetails.first;
      _log.i('Loaded product: ${_premiumProduct!.id} — ${_premiumProduct!.price}');
    }
  }

  // ─── Purchase ─────────────────────────────────────────

  /// Initiate the premium lifetime purchase.
  /// Returns `true` if the purchase succeeds, `false` if cancelled.
  /// Throws on unexpected errors.
  Future<bool> purchasePremium() async {
    if (_premiumProduct == null) {
      await _loadProducts();
      if (_premiumProduct == null) {
        throw Exception('Premium product not available');
      }
    }

    final purchaseParam = PurchaseParam(productDetails: _premiumProduct!);
    final completer = Completer<bool>();
    _purchaseCompleter[_premiumProduct!.id] = completer;

    // buyNonConsumable is used for lifetime/one-time purchases.
    final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!started) {
      _purchaseCompleter.remove(_premiumProduct!.id);
      return false;
    }

    return completer.future;
  }

  /// Restore previously completed purchases.
  /// The results arrive via the purchase stream.
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  // ─── Purchase stream handler ──────────────────────────

  /// Callback invoked for every purchase update from the App Store.
  /// Returns the raw receipt data for server-side verification.
  ///
  /// [onVerified] is called with `(PurchaseDetails)` when a purchase is
  /// in `purchased` or `restored` state, so the caller can verify the
  /// receipt on the backend before completing the transaction.
  PurchaseVerificationCallback? onPurchaseVerification;

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _log.d('Purchase update: ${purchase.productID} — ${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchase);
          break;
        case PurchaseStatus.error:
          _log.e('Purchase error', error: purchase.error);
          _resolveCompleter(purchase.productID, false);
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.canceled:
          _log.i('Purchase cancelled by user');
          _resolveCompleter(purchase.productID, false);
          break;
        case PurchaseStatus.pending:
          _log.i('Purchase pending...');
          break;
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    try {
      // Notify the repository layer to verify the receipt server-side.
      if (onPurchaseVerification != null) {
        await onPurchaseVerification!(purchase);
      }

      _resolveCompleter(purchase.productID, true);
    } catch (e) {
      _log.e('Post-purchase verification failed', error: e);
      _resolveCompleter(purchase.productID, false);
    } finally {
      // Always complete the purchase to avoid App Store retries.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void _resolveCompleter(String productId, bool result) {
    final completer = _purchaseCompleter.remove(productId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }
}

/// Callback type for server-side receipt verification.
typedef PurchaseVerificationCallback = Future<void> Function(
  PurchaseDetails purchase,
);
