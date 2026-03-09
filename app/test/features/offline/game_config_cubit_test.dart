import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nhie_app/core/constants/creator_packs.dart';
import 'package:nhie_app/features/offline/cubit/game_config_cubit.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GameConfigCubit creator pack selection', () {
    test('keeps only one selected pack at a time', () {
      final cubit = GameConfigCubit();

      cubit.setSelectedPackId('icebreakers');
      expect(cubit.state.selectedPackId, 'icebreakers');

      cubit.setSelectedPackId('deep_talk');
      expect(cubit.state.selectedPackId, 'deep_talk');
    });

    test('toggleSelectedPackId deselects active pack', () {
      final cubit = GameConfigCubit();

      cubit.setSelectedPackId('icebreakers');
      expect(cubit.state.selectedPackId, 'icebreakers');

      cubit.toggleSelectedPackId('icebreakers');
      expect(cubit.state.selectedPackId, isNull);
    });

    test('ignores unknown pack IDs', () {
      final cubit = GameConfigCubit();
      final before = cubit.state.selectedPackId;

      cubit.setSelectedPackId('does_not_exist');

      expect(cubit.state.selectedPackId, before);
    });

    test('default selected pack is valid', () {
      final cubit = GameConfigCubit();

      expect(cubit.state.selectedPackId, CreatorPacks.defaultSelectionId);
      expect(CreatorPacks.byId(cubit.state.selectedPackId!), isNotNull);
    });
  });

  group('GameConfigCubit categories', () {
    test('allows empty categories list', () {
      final cubit = GameConfigCubit();

      cubit.setCategories(const []);

      expect(cubit.state.categories, isEmpty);
    });
  });
}
