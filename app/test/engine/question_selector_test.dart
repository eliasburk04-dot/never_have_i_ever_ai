import 'package:flutter_test/flutter_test.dart';
import 'package:nhie_app/services/local_question_pool.dart';

const _testJson = '''
[
  {"id":"q1","text_en":"Q1 en","text_de":"Q1 de","text_es":"Q1 es","category":"social","subcategory":"faux_pas","intensity":1,"is_nsfw":false,"is_premium":false,"shock_factor":0.1,"vulnerability_level":0.1,"energy":"light"},
  {"id":"q2","text_en":"Q2 en","text_de":"Q2 de","text_es":"Q2 es","category":"food","subcategory":"habits","intensity":2,"is_nsfw":false,"is_premium":false,"shock_factor":0.2,"vulnerability_level":0.1,"energy":"light"},
  {"id":"q3","text_en":"Q3 en","text_de":"Q3 de","text_es":"Q3 es","category":"social","subcategory":"white_lies","intensity":3,"is_nsfw":false,"is_premium":false,"shock_factor":0.3,"vulnerability_level":0.2,"energy":"medium"},
  {"id":"q4","text_en":"Q4 en","text_de":"Q4 de","text_es":"Q4 es","category":"relationships","subcategory":"dating","intensity":5,"is_nsfw":false,"is_premium":false,"shock_factor":0.4,"vulnerability_level":0.3,"energy":"medium"},
  {"id":"q5","text_en":"Q5 en","text_de":"Q5 de","text_es":"Q5 es","category":"sexual","subcategory":"casual","intensity":8,"is_nsfw":true,"is_premium":true,"shock_factor":0.6,"vulnerability_level":0.4,"energy":"heavy"},
  {"id":"q6","text_en":"Q6 en","text_de":"Q6 de","text_es":"Q6 es","category":"sexual","subcategory":"risky","intensity":9,"is_nsfw":true,"is_premium":true,"shock_factor":0.7,"vulnerability_level":0.5,"energy":"heavy"}
]
''';

void main() {
  late LocalQuestionPool pool;

  setUp(() {
    pool = LocalQuestionPool();
    pool.initializeFromJson(_testJson);
  });

  group('LocalQuestionPool', () {
    test('loads questions and sets isInitialized', () {
      expect(pool.isInitialized, true);
    });

    test('selects question in intensity range', () {
      final result = pool.select(
        language: 'en',
        intensityMin: 1,
        intensityMax: 3,
        nsfwEnabled: false,
        isPremium: false,
        usedIds: [],
      );
      expect(result, isNotNull);
      expect(result!.question.intensity, inInclusiveRange(1, 3));
      expect(result.recycled, false);
    });

    test('returns text in correct language', () {
      final result = pool.select(
        language: 'de',
        intensityMin: 1,
        intensityMax: 1,
        nsfwEnabled: false,
        isPremium: false,
        usedIds: [],
      );
      expect(result, isNotNull);
      expect(result!.text, 'Q1 de');
    });

    test('filters out NSFW questions when nsfw disabled', () {
      final result = pool.select(
        language: 'en',
        intensityMin: 8,
        intensityMax: 9,
        nsfwEnabled: false,
        isPremium: true,
        usedIds: [],
      );
      // q5 and q6 are NSFW, should be filtered
      expect(result, isNull);
    });

    test('includes NSFW questions when nsfw enabled and premium', () {
      final result = pool.select(
        language: 'en',
        intensityMin: 8,
        intensityMax: 9,
        nsfwEnabled: true,
        isPremium: true,
        usedIds: [],
      );
      expect(result, isNotNull);
      expect(result!.question.isNsfw, true);
    });

    test('filters out premium questions when not premium', () {
      final result = pool.select(
        language: 'en',
        intensityMin: 8,
        intensityMax: 9,
        nsfwEnabled: true,
        isPremium: false,
        usedIds: [],
      );
      expect(result, isNull);
    });

    test('excludes used question IDs', () {
      // Only q1 is in intensity 1
      final result = pool.select(
        language: 'en',
        intensityMin: 1,
        intensityMax: 1,
        nsfwEnabled: false,
        isPremium: false,
        usedIds: ['q1'],
      );
      // q1 excluded, expanded range should find q2 (intensity 2, ±1)
      // or null if strict. Let's check: expanded is 0-2 clamped to 1-2
      expect(result, isNotNull);
      expect(result!.question.id, isNot('q1'));
    });

    test('recycles when all candidates are used', () {
      final result = pool.select(
        language: 'en',
        intensityMin: 1,
        intensityMax: 3,
        nsfwEnabled: false,
        isPremium: false,
        usedIds: ['q1', 'q2', 'q3', 'q4'], // q4 is intensity 5, won't match. All 1-3 used.
      );
      // expanded range 0-4 → 1-4: q4 is also used. So recycle from original candidates
      expect(result, isNotNull);
      expect(result!.recycled, true);
    });

    test('returns null for empty pool', () {
      final emptyPool = LocalQuestionPool();
      emptyPool.initializeFromJson('[]');
      final result = emptyPool.select(
        language: 'en',
        intensityMin: 1,
        intensityMax: 3,
        nsfwEnabled: false,
        isPremium: false,
        usedIds: [],
      );
      expect(result, isNull);
    });
  });
}
