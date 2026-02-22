import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Centralized service to handle RevenueCat logic for In-App Purchases.
class IapService {
  IapService._();

  static final IapService instance = IapService._();

  bool _isConfigured = false;
  bool get isConfigured => _isConfigured;

  // Replace with your actual RevenueCat Public API Keys later.
  // For now, we will use placeholders or leave it ready for insertion.
  static const String _appleApiKey = 'appl_YOUR_APPLE_API_KEY';
  static const String _googleApiKey = 'goog_YOUR_GOOGLE_API_KEY';

  /// The entitlement ID configured in RevenueCat dashboard.
  static const String _premiumEntitlementId = 'premium';

  /// Initializes the RevenueCat SDK. Call this in `main.dart`.
  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('[IapService] Web not supported by purchases_flutter.');
      return;
    }
    
    // Enable debug logs for testing
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration? configuration;

    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_googleApiKey);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_appleApiKey);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
      _isConfigured = true;
      debugPrint('[IapService] RevenueCat configured successfully.');
    }
  }

  /// Checks if the user currently has the premium entitlement active.
  Future<bool> checkPremiumStatus() async {
    if (!_isConfigured) return false;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_premiumEntitlementId]?.isActive == true;
    } catch (e) {
      debugPrint('[IapService] Failed to check premium status: $e');
      return false;
    }
  }

  /// Fetches available packages (products) from RevenueCat.
  Future<List<Package>> getOfferings() async {
    if (!_isConfigured) return [];

    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        return offerings.current!.availablePackages;
      }
      return [];
    } catch (e) {
      debugPrint('[IapService] Failed to fetch offerings: $e');
      return [];
    }
  }

  /// Initiates the purchase flow for a specific package.
  /// Returns `true` if the purchase was successful and unlocked premium.
  Future<bool> purchasePackage(Package package) async {
    if (!_isConfigured) return false;

    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.all[_premiumEntitlementId]?.isActive == true;
    } catch (e) {
      debugPrint('[IapService] Purchase failed: $e');
      return false;
    }
  }

  /// Restores previous purchases (essential for App Store review).
  /// Returns `true` if restoring unlocked the premium entitlement.
  Future<bool> restorePurchases() async {
    if (!_isConfigured) return false;

    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[_premiumEntitlementId]?.isActive == true;
    } catch (e) {
      debugPrint('[IapService] Restore failed: $e');
      return false;
    }
  }
}
