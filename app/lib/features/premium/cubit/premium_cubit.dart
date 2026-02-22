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
      } else if (!isNowPremium) {
        // If it emits but we still aren't premium, it might have been an error or cancel.
        emit(state.copyWith(isLoading: false));
      }
    });
  }

  /// Check current premium status and fetch real price from the store.
  Future<void> checkPremium() async {
    emit(state.copyWith(isLoading: true));
    try {
      final isPremium = await _iapService.checkLocalPremiumStatus();
      
      String priceText = '\$9.99'; // Fallback
      
      if (!isPremium) {
        final product = await _iapService.getPremiumProduct();
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
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final product = await _iapService.getPremiumProduct();
      if (product == null) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Premium product not found in the store.',
        ));
        return;
      }
      
      // The actual result will come back asynchronously through the stream.
      await _iapService.buyPremium(product);
      
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Purchase error: $e',
      ));
    }
  }

  /// Restore previous App Store purchases.
  Future<void> restore() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _iapService.restorePurchases();
      // The actual result will come back asynchronously through the stream.
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Restore error: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    // We don't dispose the singleton, just close the cubit.
    return super.close();
  }
}
