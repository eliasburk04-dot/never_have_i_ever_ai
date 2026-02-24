import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/service_locator.dart';
import '../../../core/services/native_iap_service.dart';
import '../../../domain/repositories/i_premium_repository.dart';

// ─── State ─────────────────────────────────────────────

class PremiumState extends Equatable {
  const PremiumState({
    this.isPremium = false,
    this.isLoading = false,
    this.errorMessage,
    this.priceString = '\$4.99',
  });

  final bool isPremium;
  final bool isLoading;
  final String? errorMessage;
  final String priceString;

  PremiumState copyWith({
    bool? isPremium,
    bool? isLoading,
    String? errorMessage,
    String? priceString,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      priceString: priceString ?? this.priceString,
    );
  }

  @override
  List<Object?> get props => [isPremium, isLoading, errorMessage, priceString];
}

// ─── Cubit ─────────────────────────────────────────────

// ─── Cubit ─────────────────────────────────────────────

class PremiumCubit extends Cubit<PremiumState> {
  PremiumCubit() : super(const PremiumState()) {
    _initIap();
  }

  // We are bypassing IPremiumRepository for now 
  // and going straight to our new NativeIapService.
  final _iapService = NativeIapService.instance;

  void _initIap() {
    _iapService.purchasesStream.listen((purchases) async {
      // Whenever a purchase succeeds, re-check local status.
      // This stream emits when buyPremium or restorePurchases succeeds.
      final isNowPremium = await _iapService.checkLocalPremiumStatus();
      if (isNowPremium && !state.isPremium) {
        emit(state.copyWith(isPremium: true, isLoading: false, errorMessage: null));
      } else {
        // Purchase was cancelled, errored, or not premium — always stop loading.
        emit(state.copyWith(isLoading: false));
      }
    });
  }

  /// Check current premium status and fetch real price from the store.
  Future<void> checkPremium() async {
    emit(state.copyWith(isLoading: true));
    try {
      // ── DEBUG: Force premium for screenshots ──
      await _iapService.debugGrantPremium();
      // ── END DEBUG ──

      final isPremium = await _iapService.checkLocalPremiumStatus();
      
      String priceText = '\$9.99'; // Fallback
      
      if (!isPremium) {
        // Timeout product query — on simulator the store may hang.
        final product = await _iapService
            .getPremiumProduct()
            .timeout(const Duration(seconds: 5), onTimeout: () => null);
        if (product != null) {
          priceText = product.price;
        }
      }

      emit(state.copyWith(
        isPremium: isPremium,
        isLoading: false,
        priceString: priceText,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Initiate a purchase via StoreKit/PlayStore.
  Future<void> purchase() async {
    if (state.isLoading) return; // Prevent double-tap
    emit(state.copyWith(isLoading: true, errorMessage: null));

    // Listen for the NEXT purchase stream event to stop loading.
    // If no event arrives within 10 seconds, assume the purchase
    // dialog was dismissed or the store is unavailable.
    _purchaseTimeout?.cancel();
    _purchaseTimeout = Timer(const Duration(seconds: 10), () {
      if (state.isLoading && !isClosed) {
        emit(state.copyWith(isLoading: false));
      }
    });

    try {
      final product = await _iapService.getPremiumProduct();
      if (product == null) {
        _purchaseTimeout?.cancel();
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Premium product not found in the store.',
        ));
        return;
      }

      // The actual result will come back asynchronously through the stream.
      await _iapService.buyPremium(product);
    } catch (e) {
      _purchaseTimeout?.cancel();
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Purchase error: $e',
      ));
    }
  }

  Timer? _purchaseTimeout;

  /// Restore previous App Store purchases.
  Future<void> restore() async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    _purchaseTimeout?.cancel();
    _purchaseTimeout = Timer(const Duration(seconds: 10), () {
      if (state.isLoading && !isClosed) {
        emit(state.copyWith(isLoading: false));
      }
    });

    try {
      await _iapService.restorePurchases();
      // The actual result will come back asynchronously through the stream.
    } catch (e) {
      _purchaseTimeout?.cancel();
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Restore error: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    _purchaseTimeout?.cancel();
    return super.close();
  }
}
