import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nhie_app/services/local_question_pool.dart';

const _safeCategories = [
  'social',
  'food',
  'embarrassing',
  'moral_gray',
  'risk',
  'relationships',
  'confessions',
  'deep',
  'party',
];

const _safeSubcategories = [
  'habits',
  'awkward',
  'white_lies',
  'faux_pas',
  'private',
  'public',
  'heartbreak',
  'guilt',
  'status',
  'confidence',
  'timing',
  'social_media',
];

const _nsfwCategories = [
  'sexual',
  'relationships',
  'confessions',
  'deep',
];

const _nsfwSubcategories = [
  'desire',
  'boundaries',
  'secrets',
  'temptation',
  'situationship',
  'flirting',
];

String _buildLargePoolJson() {
  final out = <Map<String, dynamic>>[];
  var id = 1;

  for (var intensity = 1; intensity <= 10; intensity++) {
    for (var i = 0; i < 70; i++) {
      final isNsfw = intensity >= 7 && i % 3 == 0;
      final category = isNsfw
          ? _nsfwCategories[(i + intensity) % _nsfwCategories.length]
          : _safeCategories[(i + intensity) % _safeCategories.length];
      final subcategory = isNsfw
          ? _nsfwSubcategories[(i * 2 + intensity) % _nsfwSubcategories.length]
          : _safeSubcategories[(i * 3 + intensity) % _safeSubcategories.length];
      var energy = intensity >= 8
          ? 'heavy'
          : intensity >= 4
          ? 'medium'
          : 'light';
      if (intensity <= 2 && i % 5 == 0) energy = 'medium';
      if (intensity <= 4 && i % 11 == 0) energy = 'heavy';

      out.add({
        'id': 'q${id.toString().padLeft(4, '0')}',
        'text_en': 'Never have I ever synthetic prompt $id',
        'text_de': 'Ich hab noch nie synthetische Frage $id',
        'text_es': 'Nunca he hecho pregunta sintética $id',
        'category': category,
        'subcategory': subcategory,
        'intensity': intensity,
        'is_nsfw': isNsfw,
        'is_premium': isNsfw,
        'shock_factor': (0.1 + intensity * 0.07).clamp(0.0, 1.0),
        'vulnerability_level': (0.1 + intensity * 0.06).clamp(0.0, 1.0),
        'energy': energy,
      });
      id++;
    }
  }

  return jsonEncode(out);
}

List<String> _tail(List<String> values, int count) {
  if (values.length <= count) return values;
  return values.sublist(values.length - count);
}

void main() {
  group('Question pool simulation', () {
    test(
      '100 rounds: no duplicates, early diversity, no same subcategory back-to-back',
      () {
        final pool = LocalQuestionPool(debugSeed: 1337);
        pool.initializeFromJson(_buildLargePoolJson());

        final usedIds = <String>[];
        final categoriesSeenFirst20 = <String>{};
        final energiesSeenFirst20 = <String>{};
        final subcategories = <String>[];
        final categories = <String>[];
        final energies = <String>[];

        for (var round = 1; round <= 100; round++) {
          final selection = pool.select(
            language: 'en',
            intensityMin: 1,
            intensityMax: 10,
            nsfwEnabled: true,
            isPremium: true,
            usedIds: usedIds,
            roundNumber: round,
            recentCategories: _tail(categories, 2),
            recentSubcategories: _tail(subcategories, 3),
            recentEnergies: _tail(energies, 3),
            categoriesSeenInEarlyWindow: round <= 20
                ? categoriesSeenFirst20.toList()
                : const [],
            energiesSeenInEarlyWindow: round <= 20
                ? energiesSeenFirst20.toList()
                : const [],
            recentlyUsedIds: _tail(usedIds, 10),
            escalationMultiplier: 1.1,
            vulnerabilityBias: 1.05,
          );

          expect(
            selection,
            isNotNull,
            reason: 'Selection missing in round $round',
          );
          final q = selection!.question;

          expect(
            usedIds.contains(q.id),
            isFalse,
            reason: 'Duplicate question in round $round: ${q.id}',
          );

          if (subcategories.isNotEmpty && q.subcategory.isNotEmpty) {
            expect(q.subcategory, isNot(subcategories.last));
          }

          usedIds.add(q.id);
          categories.add(q.category);
          subcategories.add(q.subcategory);
          energies.add(q.energy);

          if (round <= 20) {
            categoriesSeenFirst20.add(q.category);
            energiesSeenFirst20.add(q.energy);
            expect(q.intensity, inInclusiveRange(1, 4));
          }
        }

        expect(usedIds.toSet().length, 100);
        expect(categoriesSeenFirst20.length, greaterThanOrEqualTo(5));
        expect(energiesSeenFirst20.length, greaterThanOrEqualTo(3));
      },
    );

    test('same debug seed is reproducible', () {
      List<String> runSequence(int seed) {
        final pool = LocalQuestionPool(debugSeed: seed);
        pool.initializeFromJson(_buildLargePoolJson());

        final used = <String>[];
        final categories = <String>[];
        final subcategories = <String>[];
        final energies = <String>[];

        for (var round = 1; round <= 30; round++) {
          final pick = pool.select(
            language: 'en',
            intensityMin: 1,
            intensityMax: 10,
            nsfwEnabled: true,
            isPremium: true,
            usedIds: used,
            roundNumber: round,
            recentCategories: _tail(categories, 2),
            recentSubcategories: _tail(subcategories, 3),
            recentEnergies: _tail(energies, 3),
            categoriesSeenInEarlyWindow: const [],
            energiesSeenInEarlyWindow: const [],
            recentlyUsedIds: _tail(used, 10),
          );
          expect(pick, isNotNull);

          used.add(pick!.question.id);
          categories.add(pick.question.category);
          subcategories.add(pick.question.subcategory);
          energies.add(pick.question.energy);
        }

        return used;
      }

      final a = runSequence(777);
      final b = runSequence(777);
      final c = runSequence(778);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('nsfw disabled never returns nsfw questions', () {
      final pool = LocalQuestionPool(debugSeed: 2026);
      pool.initializeFromJson(_buildLargePoolJson());

      final used = <String>[];
      final categories = <String>[];
      final subcategories = <String>[];
      final energies = <String>[];

      for (var round = 1; round <= 80; round++) {
        final pick = pool.select(
          language: 'en',
          intensityMin: 1,
          intensityMax: 10,
          nsfwEnabled: false,
          isPremium: true,
          usedIds: used,
          roundNumber: round,
          recentCategories: _tail(categories, 2),
          recentSubcategories: _tail(subcategories, 3),
          recentEnergies: _tail(energies, 3),
          recentlyUsedIds: _tail(used, 10),
        );

        expect(pick, isNotNull);
        expect(pick!.question.isNsfw, isFalse);

        used.add(pick.question.id);
        categories.add(pick.question.category);
        subcategories.add(pick.question.subcategory);
        energies.add(pick.question.energy);
      }
    });
  });
}
