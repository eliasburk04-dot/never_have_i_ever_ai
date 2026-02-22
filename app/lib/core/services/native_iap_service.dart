import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service to handle Native In-App Purchases (StoreKit/Google Play).
class NativeIapService {
  NativeIapService._();

  static final NativeIapService instance = NativeIapService._();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // The actual Product ID configured in App Store Connect / Google Play Console
  static const String premiumProductId = 'exposed_premium_lifetime';

  final _isAvailableController = StreamController<bool>.broadcast();
  final _purchasesController = StreamController<List<PurchaseDetails>>.broadcast();
  
  Stream<bool> get isAvailableStream => _isAvailableController.stream;
  Stream<List<PurchaseDetails>> get purchasesStream => _purchasesController.stream;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// Call this once in `main.dart` or when initializing the app.
  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('[NativeIapService] IAP not supported on web.');
      return;
    }

    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      debugPrint('[NativeIapService] Purchase stream error: $error');
    });

    _isAvailable = await _inAppPurchase.isAvailable();
    _isAvailableController.add(_isAvailable);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    _purchasesController.add(purchaseDetailsList);
    
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('[NativeIapService] Purchase pending...');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('[NativeIapService] Purchase error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          debugPrint('[NativeIapService] Purchase successful / restored!');
          
          if (purchaseDetails.productID == premiumProductId) {
            _grantPremium();
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  /// Fetches the Premium product details (price, title, etc) from the store.
  Future<ProductDetails?> getPremiumProduct() async {
    if (!_isAvailable) return null;

    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({premiumProductId});
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[NativeIapService] Premium product not found in store.');
      return null;
    }
    if (response.error != null) {
      debugPrint('[NativeIapService] Error fetching product: ${response.error}');
      return null;
    }
    
    return response.productDetails.isNotEmpty ? response.productDetails.first : null;
  }

  /// Initiate the purchase flow for the premium unlock.
  Future<void> buyPremium(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restore previous purchases.
  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  /// Persist the premium status locally.
  Future<void> _grantPremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', true);
  }

  /// Check the cached premium status.
  Future<bool> checkLocalPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_premium') ?? false;
  }

  void dispose() {
    _subscription.cancel();
    _isAvailableController.close();
    _purchasesController.close();
  }
}
