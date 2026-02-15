import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/i_premium_repository.dart';
import '../../services/store_kit_service.dart';

/// Local premium implementation.
///
/// For now this is "local premium": if StoreKit purchase/restore succeeds,
/// we mark the device as premium. No server dependency required.
class PremiumRepository implements IPremiumRepository {
  PremiumRepository(this._storeKit);

  final StoreKitService _storeKit;
  final _log = Logger();

  static const _premiumKey = 'premium_local_enabled';

  bool? _cachedPremium;

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  @override
  Future<void> initialize() async {
    await _storeKit.initialize();
    _storeKit.onPurchaseVerification = _handlePurchaseVerification;
  }

  @override
  void dispose() {
    _storeKit.dispose();
  }

  @override
  String get priceString => _storeKit.priceString;

  @override
  Future<bool> isPremium() async {
    if (_cachedPremium != null) return _cachedPremium!;
    final prefs = await _prefs();
    _cachedPremium = prefs.getBool(_premiumKey) ?? false;
    return _cachedPremium!;
  }

  Future<void> _setPremium(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_premiumKey, value);
    _cachedPremium = value;
  }

  @override
  Future<bool> purchasePremium() async {
    try {
      final success = await _storeKit.purchasePremium();
      if (success) await _setPremium(true);
      return success;
    } catch (e) {
      _log.e('Purchase failed', error: e);
      rethrow;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    try {
      await _storeKit.restorePurchases();
      // If restore succeeded, assume premium for this device.
      await _setPremium(true);
      return true;
    } catch (e) {
      _log.e('Restore failed', error: e);
      return false;
    }
  }

  @override
  Future<bool> verifyReceipt({
    required String receiptData,
    required String productId,
  }) async {
    // No server verification in the local-only premium build.
    await _setPremium(true);
    return true;
  }

  Future<void> _handlePurchaseVerification(dynamic purchase) async {
    // StoreKitService calls this after a confirmed purchase/restore.
    // We treat that as verified for local premium.
    await _setPremium(true);
  }
}

