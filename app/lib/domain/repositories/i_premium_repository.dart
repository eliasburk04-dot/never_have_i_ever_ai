/// Abstract repository for premium/purchase operations.
///
/// Uses Apple StoreKit 2 (via in_app_purchase plugin) for iOS purchases.
/// No third-party payment SDK required.
abstract class IPremiumRepository {
  /// Check if the current user has premium status.
  Future<bool> isPremium();

  /// Initiate the lifetime premium purchase flow.
  Future<bool> purchasePremium();

  /// Restore previously completed purchases from the App Store.
  Future<bool> restorePurchases();

  /// Verify a receipt server-side and update premium status.
  Future<bool> verifyReceipt({
    required String receiptData,
    required String productId,
  });

  /// Get the formatted price string for the premium product.
  String get priceString;

  /// Initialize the purchase service (call once at app start).
  Future<void> initialize();

  /// Dispose resources.
  void dispose();
}
