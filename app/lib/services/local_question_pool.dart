import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

/// A single question from the bundled JSON pool.
class LocalQuestion {
  const LocalQuestion({
    required this.id,
    required this.textEn,
    required this.textDe,
    required this.textEs,
    required this.category,
    required this.intensity,
    required this.isNsfw,
    required this.isPremium,
    this.subcategory = '',
    this.shockFactor = 0.0,
    this.vulnerabilityLevel = 0.0,
    this.energy = 'medium',
  });

  final String id;
  final String textEn;
  final String textDe;
  final String textEs;
  final String category;
  final int intensity;
  final bool isNsfw;
  final bool isPremium;

  /// Fine-grained subcategory for cooldown tracking.
  final String subcategory;

  /// 0.0–1.0 — how shocking / gasp-inducing the question is.
  final double shockFactor;

  /// 0.0–1.0 — how emotionally exposing the question is.
  final double vulnerabilityLevel;

  /// Energy level: "light", "medium", "heavy".
  final String energy;

  String textForLanguage(String lang) {
    switch (lang) {
      case 'de':
        return textDe;
      case 'es':
        return textEs;
      default:
        return textEn;
    }
  }

  factory LocalQuestion.fromJson(Map<String, dynamic> json) => LocalQuestion(
        id: json['id'] as String,
        textEn: json['text_en'] as String,
        textDe: json['text_de'] as String,
        textEs: json['text_es'] as String,
        category: json['category'] as String,
        intensity: json['intensity'] as int,
        isNsfw: json['is_nsfw'] as bool,
        isPremium: json['is_premium'] as bool,
        subcategory: json['subcategory'] as String? ?? '',
        shockFactor: (json['shock_factor'] as num?)?.toDouble() ?? 0.0,
        vulnerabilityLevel:
            (json['vulnerability_level'] as num?)?.toDouble() ?? 0.0,
        energy: json['energy'] as String? ?? 'medium',
      );
}

/// Service that loads and indexes the bundled question pool.
/// Call [initialize] once at app start, then use [select] per round.
class LocalQuestionPool {
  LocalQuestionPool();

  final _random = Random();

  List<LocalQuestion> _all = [];
  final Map<int, List<LocalQuestion>> _byIntensity = {};

  bool get isInitialized => _all.isNotEmpty;

  /// Load questions from the bundled asset.
  Future<void> initialize() async {
    if (_all.isNotEmpty) return;
    final raw = await rootBundle.loadString('assets/questions.json');
    _loadFromRaw(raw);
  }

  /// Initialize from a raw JSON string (for testing).
  void initializeFromJson(String raw) {
    _loadFromRaw(raw);
  }

  void _loadFromRaw(String raw) {
    final list = (jsonDecode(raw) as List)
        .map((e) => LocalQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
    _all = list;
    _byIntensity.clear();
    for (final q in _all) {
      _byIntensity.putIfAbsent(q.intensity, () => []).add(q);
    }
  }

  /// Select a question matching the given criteria with category cooldown
  /// and weighted random selection.
  ///
  /// [recentCategories] — last N categories to cool down (avoid same category).
  /// [recentSubcategories] — last N subcategories to cool down.
  ///
  /// Returns `null` only if the entire pool is empty.
  QuestionSelection? select({
    required String language,
    required int intensityMin,
    required int intensityMax,
    required bool nsfwEnabled,
    required bool isPremium,
    required List<String> usedIds,
    List<String> recentCategories = const [],
    List<String> recentSubcategories = const [],
  }) {
    // Step 1: Gather candidates in intensity range
    List<LocalQuestion> candidates = [];
    for (int i = intensityMin; i <= intensityMax; i++) {
      candidates.addAll(_byIntensity[i] ?? []);
    }

    // Step 2: Filter NSFW
    if (!nsfwEnabled) {
      candidates = candidates.where((q) => !q.isNsfw).toList();
    }

    // Step 3: Filter premium
    if (!isPremium) {
      candidates = candidates.where((q) => !q.isPremium).toList();
    }

    // Step 4: Exclude already used
    final unused =
        candidates.where((q) => !usedIds.contains(q.id)).toList();

    if (unused.isNotEmpty) {
      // Apply category cooldown tiered filtering
      final picked = _pickWithCooldown(
        unused,
        recentCategories: recentCategories,
        recentSubcategories: recentSubcategories,
      );
      if (picked != null) {
        return QuestionSelection(
          question: picked,
          text: picked.textForLanguage(language),
          recycled: false,
        );
      }
    }

    // Step 5: Expand intensity ±1
    final expanded = <LocalQuestion>[];
    for (int i = (intensityMin - 1).clamp(1, 10);
        i <= (intensityMax + 1).clamp(1, 10);
        i++) {
      expanded.addAll(_byIntensity[i] ?? []);
    }
    if (!nsfwEnabled) expanded.removeWhere((q) => q.isNsfw);
    if (!isPremium) expanded.removeWhere((q) => q.isPremium);
    final expandedUnused =
        expanded.where((q) => !usedIds.contains(q.id)).toList();
    if (expandedUnused.isNotEmpty) {
      final picked = _pickWithCooldown(
        expandedUnused,
        recentCategories: recentCategories,
        recentSubcategories: recentSubcategories,
      );
      if (picked != null) {
        return QuestionSelection(
          question: picked,
          text: picked.textForLanguage(language),
          recycled: false,
        );
      }
    }

    // Step 6: Recycle from original candidates (no cooldown applied)
    if (candidates.isNotEmpty) {
      final q = _weightedPick(candidates);
      return QuestionSelection(
        question: q,
        text: q.textForLanguage(language),
        recycled: true,
      );
    }

    // Step 7: null — caller should use emergency fallback
    return null;
  }

  /// Apply tiered category cooldown, then weighted pick.
  ///
  /// Tier 1: exclude both recent categories AND subcategories.
  /// Tier 2: only exclude subcategories.
  /// Tier 3: no exclusion — just weighted pick from all.
  LocalQuestion? _pickWithCooldown(
    List<LocalQuestion> pool, {
    required List<String> recentCategories,
    required List<String> recentSubcategories,
  }) {
    if (pool.isEmpty) return null;

    // Tier 1: Exclude both category AND subcategory repeats
    if (recentCategories.isNotEmpty || recentSubcategories.isNotEmpty) {
      final tier1 = pool.where((q) {
        final catOk = !recentCategories.contains(q.category);
        final subOk = q.subcategory.isEmpty ||
            !recentSubcategories.contains(q.subcategory);
        return catOk && subOk;
      }).toList();
      if (tier1.isNotEmpty) return _weightedPick(tier1);
    }

    // Tier 2: Only exclude subcategory repeats
    if (recentSubcategories.isNotEmpty) {
      final tier2 = pool.where((q) {
        return q.subcategory.isEmpty ||
            !recentSubcategories.contains(q.subcategory);
      }).toList();
      if (tier2.isNotEmpty) return _weightedPick(tier2);
    }

    // Tier 3: No exclusion
    return _weightedPick(pool);
  }

  /// Weighted random pick using shock_factor + vulnerability_level.
  ///
  /// Higher combined values get a slight boost, but all questions have
  /// a base weight to ensure variety.
  LocalQuestion _weightedPick(List<LocalQuestion> pool) {
    if (pool.length == 1) return pool.first;

    // weight = 1.0 + shock_factor + vulnerability_level  (range 1.0 – 3.0)
    final weights = pool.map((q) {
      return 1.0 + q.shockFactor + q.vulnerabilityLevel;
    }).toList();

    final totalWeight = weights.fold(0.0, (sum, w) => sum + w);
    var dart = _random.nextDouble() * totalWeight;

    for (int i = 0; i < pool.length; i++) {
      dart -= weights[i];
      if (dart <= 0) return pool[i];
    }
    return pool.last;
  }

  /// Return up to [limit] candidate questions as JSON maps for the Groq API.
  List<Map<String, dynamic>> candidatesForGroq({
    required String language,
    required int intensityMin,
    required int intensityMax,
    required bool nsfwEnabled,
    required List<String> usedIds,
    int limit = 10,
  }) {
    List<LocalQuestion> candidates = [];
    for (int i = intensityMin; i <= intensityMax; i++) {
      candidates.addAll(_byIntensity[i] ?? []);
    }
    if (!nsfwEnabled) {
      candidates = candidates.where((q) => !q.isNsfw).toList();
    }
    final unused =
        candidates.where((q) => !usedIds.contains(q.id)).toList();
    unused.shuffle(_random);
    return unused.take(limit).map((q) => {
          'id': q.id,
          'text': q.textForLanguage(language),
          'category': q.category,
          'subcategory': q.subcategory,
          'intensity': q.intensity,
          'is_nsfw': q.isNsfw,
          'shock_factor': q.shockFactor,
          'vulnerability_level': q.vulnerabilityLevel,
          'energy': q.energy,
        }).toList();
  }
}

/// Result of a question selection.
class QuestionSelection {
  const QuestionSelection({
    required this.question,
    required this.text,
    required this.recycled,
  });

  final LocalQuestion question;
  final String text;
  final bool recycled;
}
