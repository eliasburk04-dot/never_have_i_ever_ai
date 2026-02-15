import 'package:flutter_test/flutter_test.dart';

import 'package:nhie_app/features/premium/cubit/premium_cubit.dart';

void main() {
  group('PremiumState', () {
    test('initial state', () {
      const state = PremiumState();
      expect(state.isPremium, false);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
      expect(state.priceString, '\$4.99');
    });

    test('copyWith preserves fields', () {
      final state = const PremiumState().copyWith(
        isPremium: true,
        isLoading: false,
        priceString: '\$3.99',
      );
      expect(state.isPremium, true);
      expect(state.isLoading, false);
      expect(state.priceString, '\$3.99');
    });

    test('error state', () {
      final state = const PremiumState().copyWith(
        errorMessage: 'Purchase failed',
        isLoading: false,
      );
      expect(state.errorMessage, 'Purchase failed');
    });

    test('equatable props include priceString', () {
      const a = PremiumState(priceString: '\$4.99');
      const b = PremiumState(priceString: '\$4.99');
      const c = PremiumState(priceString: '\$9.99');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
