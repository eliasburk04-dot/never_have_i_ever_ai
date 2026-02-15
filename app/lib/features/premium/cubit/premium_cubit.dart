import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/service_locator.dart';
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

class PremiumCubit extends Cubit<PremiumState> {
  PremiumCubit() : super(const PremiumState());

  final _premiumRepo = getIt<IPremiumRepository>();

  /// Check current premium status and update price.
  Future<void> checkPremium() async {
    emit(state.copyWith(isLoading: true));
    try {
      final isPremium = await _premiumRepo.isPremium();
      emit(state.copyWith(
        isPremium: isPremium,
        isLoading: false,
        priceString: _premiumRepo.priceString,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Initiate a purchase via StoreKit → server-side verification.
  Future<void> purchase() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final success = await _premiumRepo.purchasePremium();
      if (success) {
        emit(state.copyWith(isPremium: true, isLoading: false));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Purchase failed or cancelled',
        ));
      }
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
      final restored = await _premiumRepo.restorePurchases();
      if (restored) {
        emit(state.copyWith(isPremium: true, isLoading: false));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'No purchases to restore',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Restore error: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    _premiumRepo.dispose();
    return super.close();
  }
}
