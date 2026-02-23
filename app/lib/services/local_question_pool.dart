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
  LocalQuestionPool({int? debugSeed}) : _random = Random() {
    beginSession(debugSeed: debugSeed);
  }

  Random _random;
  int _sessionSeed = 0;

  List<LocalQuestion> _all = [];
  final Map<int, List<LocalQuestion>> _byIntensity = {};

  bool get isInitialized => _all.isNotEmpty;
  int get sessionSeed => _sessionSeed;

  /// Starts a new RNG session.
  ///
  /// Production mode uses a secure random seed so session sequences diverge.
  /// Debug mode can pass a deterministic seed for reproducible tests.
  void beginSession({int? debugSeed}) {
    _sessionSeed = debugSeed ?? Random.secure().nextInt(0x7fffffff);
    _random = Random(_sessionSeed);
  }

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
    required List<String> categories,
    int roundNumber = 999,
    List<String> recentCategories = const [],
    List<String> recentSubcategories = const [],
    List<String> recentEnergies = const [],
    List<String> categoriesSeenInEarlyWindow = const [],
    List<String> energiesSeenInEarlyWindow = const [],
    List<String> recentlyUsedIds = const [],
    double escalationMultiplier = 1.0,
    double vulnerabilityBias = 1.0,
  }) {
    int effectiveMin = intensityMin.clamp(1, 10);
    int effectiveMax = intensityMax.clamp(1, 10);
    if (roundNumber <= 20) {
      effectiveMin = effectiveMin.clamp(1, 4);
      effectiveMax = effectiveMax.clamp(1, 4);
      if (effectiveMax < effectiveMin) effectiveMax = effectiveMin;
    }

    final usedSet = usedIds.toSet();
    final recentUsedSet = recentlyUsedIds.toSet();

    // Step 1: Gather candidates in intensity range
    List<LocalQuestion> candidates = [];
    for (int i = effectiveMin; i <= effectiveMax; i++) {
      candidates.addAll(_byIntensity[i] ?? []);
    }

    // Step 2: Filter NSFW + categories as UNION
    // NSFW adds all is_nsfw questions, categories add all questions from those
    // categories. The final pool is the union of both sets.
    if (nsfwEnabled || categories.isNotEmpty) {
      candidates = candidates.where((q) {
        if (nsfwEnabled && q.isNsfw) return true;
        if (categories.isNotEmpty && categories.contains(q.category)) return true;
        return false;
      }).toList();
    }

    // Step 3: Filter premium
    if (!isPremium) {
      candidates = candidates.where((q) => !q.isPremium).toList();
    }

    // Step 4: Exclude already used
    final unused = candidates.where((q) => !usedSet.contains(q.id)).toList();

    if (unused.isNotEmpty) {
      final picked = _pickWithCooldown(
        unused,
        roundNumber: roundNumber,
        recentCategories: recentCategories,
        recentSubcategories: recentSubcategories,
        recentEnergies: recentEnergies,
        categoriesSeenInEarlyWindow: categoriesSeenInEarlyWindow,
        energiesSeenInEarlyWindow: energiesSeenInEarlyWindow,
        escalationMultiplier: escalationMultiplier,
        vulnerabilityBias: vulnerabilityBias,
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
    final expandMin = (effectiveMin - 1).clamp(1, 10);
    final expandMax = (effectiveMax + 1).clamp(1, 10);
    for (int i = expandMin; i <= expandMax; i++) {
      expanded.addAll(_byIntensity[i] ?? []);
    }
    if (nsfwEnabled || categories.isNotEmpty) {
      expanded.removeWhere((q) {
        if (nsfwEnabled && q.isNsfw) return false;
        if (categories.isNotEmpty && categories.contains(q.category)) return false;
        return true;
      });
    }
    if (!isPremium) expanded.removeWhere((q) => q.isPremium);
    
    final expandedUnused = expanded
        .where((q) => !usedSet.contains(q.id))
        .toList();
    if (expandedUnused.isNotEmpty) {
      final picked = _pickWithCooldown(
        expandedUnused,
        roundNumber: roundNumber,
        recentCategories: recentCategories,
        recentSubcategories: recentSubcategories,
        recentEnergies: recentEnergies,
        categoriesSeenInEarlyWindow: categoriesSeenInEarlyWindow,
        energiesSeenInEarlyWindow: energiesSeenInEarlyWindow,
        escalationMultiplier: escalationMultiplier,
        vulnerabilityBias: vulnerabilityBias,
      );
      if (picked != null) {
        return QuestionSelection(
          question: picked,
          text: picked.textForLanguage(language),
          recycled: false,
        );
      }
    }

    // Step 6: Controlled recycle
    final eligibleCount = _eligiblePoolSize(
      nsfwEnabled: nsfwEnabled,
      isPremium: isPremium,
      categories: categories,
    );
    final exhaustionRatio = eligibleCount == 0
        ? 1.0
        : usedSet.length / eligibleCount;
    final canRecycle = roundNumber >= 10 && exhaustionRatio >= 0.70;

    if (canRecycle && candidates.isNotEmpty) {
      final recyclable = candidates
          .where((q) => !recentUsedSet.contains(q.id))
          .toList();
      if (recyclable.isNotEmpty) {
        recyclable.sort((a, b) => a.shockFactor.compareTo(b.shockFactor));
        final lowestShockSlice = max(1, (recyclable.length * 0.35).ceil());
        final recyclePool = recyclable.take(lowestShockSlice).toList();
        final q = _weightedPick(
          recyclePool,
          roundNumber: roundNumber,
          recentCategories: recentCategories,
          recentSubcategories: recentSubcategories,
          recentEnergies: recentEnergies,
          categoriesSeenInEarlyWindow: categoriesSeenInEarlyWindow,
          energiesSeenInEarlyWindow: energiesSeenInEarlyWindow,
          escalationMultiplier: escalationMultiplier,
          vulnerabilityBias: vulnerabilityBias,
          preferLowerShock: true,
        );
        return QuestionSelection(
          question: q,
          text: q.textForLanguage(language),
          recycled: true,
        );
      }
    }

    // Step 7: null — caller should use emergency fallback
    return null;
  }

  int _eligiblePoolSize({
    required bool nsfwEnabled,
    required bool isPremium,
    required List<String> categories,
  }) {
    return _all.where((q) {
      // Union filter: must match NSFW or category
      if (nsfwEnabled || categories.isNotEmpty) {
        final matchesNsfw = nsfwEnabled && q.isNsfw;
        final matchesCategory = categories.isNotEmpty && categories.contains(q.category);
        if (!matchesNsfw && !matchesCategory) return false;
      }
      if (!isPremium && q.isPremium) return false;
      return true;
    }).length;
  }

  /// Apply tiered category cooldown, then weighted pick.
  ///
  /// Tier 1: exclude both recent categories AND subcategories.
  /// Tier 2: only exclude subcategories.
  /// Tier 3: no exclusion — just weighted pick from all.
  LocalQuestion? _pickWithCooldown(
    List<LocalQuestion> pool, {
    required int roundNumber,
    required List<String> recentCategories,
    required List<String> recentSubcategories,
    required List<String> recentEnergies,
    required List<String> categoriesSeenInEarlyWindow,
    required List<String> energiesSeenInEarlyWindow,
    required double escalationMultiplier,
    required double vulnerabilityBias,
  }) {
    if (pool.isEmpty) return null;

    final lastSubcategory = recentSubcategories.isNotEmpty
        ? recentSubcategories.last
        : null;

    // Hard cap: avoid same subcategory back-to-back.
    final noBackToBackSubcategory = pool.where((q) {
      if (lastSubcategory == null || lastSubcategory.isEmpty) return true;
      return q.subcategory.isEmpty || q.subcategory != lastSubcategory;
    }).toList();
    if (noBackToBackSubcategory.isEmpty) return null;

    // Tier 1: Exclude both category AND subcategory repeats
    if (recentCategories.isNotEmpty || recentSubcategories.isNotEmpty) {
      final tier1 = noBackToBackSubcategory.where((q) {
        final catOk = !recentCategories.contains(q.category);
        final subOk =
            q.subcategory.isEmpty ||
            !recentSubcategories.contains(q.subcategory);
        return catOk && subOk;
      }).toList();
      if (tier1.isNotEmpty) {
        return _weightedPick(
          tier1,
          roundNumber: roundNumber,
          recentCategories: recentCategories,
          recentSubcategories: recentSubcategories,
          recentEnergies: recentEnergies,
          categoriesSeenInEarlyWindow: categoriesSeenInEarlyWindow,
          energiesSeenInEarlyWindow: energiesSeenInEarlyWindow,
          escalationMultiplier: escalationMultiplier,
          vulnerabilityBias: vulnerabilityBias,
        );
      }
    }

    // Tier 2: Only exclude subcategory repeats
    if (recentSubcategories.isNotEmpty) {
      final tier2 = noBackToBackSubcategory.where((q) {
        return q.subcategory.isEmpty ||
            !recentSubcategories.contains(q.subcategory);
      }).toList();
      if (tier2.isNotEmpty) {
        return _weightedPick(
          tier2,
          roundNumber: roundNumber,
          recentCategories: recentCategories,
          recentSubcategories: recentSubcategories,
          recentEnergies: recentEnergies,
          categoriesSeenInEarlyWindow: categoriesSeenInEarlyWindow,
          energiesSeenInEarlyWindow: energiesSeenInEarlyWindow,
          escalationMultiplier: escalationMultiplier,
          vulnerabilityBias: vulnerabilityBias,
        );
      }
    }

    // Tier 3: No exclusion
    return _weightedPick(
      noBackToBackSubcategory,
      roundNumber: roundNumber,
      recentCategories: recentCategories,
      recentSubcategories: recentSubcategories,
      recentEnergies: recentEnergies,
      categoriesSeenInEarlyWindow: categoriesSeenInEarlyWindow,
      energiesSeenInEarlyWindow: energiesSeenInEarlyWindow,
      escalationMultiplier: escalationMultiplier,
      vulnerabilityBias: vulnerabilityBias,
    );
  }

  /// Weighted random pick:
  ///
  /// `weight = base_weight + shock*escalation_multiplier + vulnerability*vulnerability_bias + diversity_bonus - repetition_penalty`
  LocalQuestion _weightedPick(
    List<LocalQuestion> pool, {
    required int roundNumber,
    required List<String> recentCategories,
    required List<String> recentSubcategories,
    required List<String> recentEnergies,
    required List<String> categoriesSeenInEarlyWindow,
    required List<String> energiesSeenInEarlyWindow,
    required double escalationMultiplier,
    required double vulnerabilityBias,
    bool preferLowerShock = false,
  }) {
    if (pool.length == 1) return pool.first;

    final esc = escalationMultiplier.clamp(0.4, 2.2).toDouble();
    final vuln = vulnerabilityBias.clamp(0.4, 2.0).toDouble();

    final weights = pool.map((q) {
      const baseWeight = 1.0;
      double diversityBonus = 0.0;
      double repetitionPenalty = 0.0;

      if (!recentCategories.contains(q.category)) diversityBonus += 0.35;
      if (q.subcategory.isNotEmpty &&
          !recentSubcategories.contains(q.subcategory)) {
        diversityBonus += 0.25;
      }
      if (!recentEnergies.contains(q.energy)) diversityBonus += 0.25;

      if (roundNumber <= 20) {
        if (categoriesSeenInEarlyWindow.length < 5 &&
            !categoriesSeenInEarlyWindow.contains(q.category)) {
          diversityBonus += 1.2;
        }
        if (energiesSeenInEarlyWindow.length < 3 &&
            !energiesSeenInEarlyWindow.contains(q.energy)) {
          diversityBonus += 0.9;
        }
      }

      if (recentCategories.isNotEmpty && recentCategories.last == q.category) {
        repetitionPenalty += 0.45;
      }
      if (recentEnergies.isNotEmpty && recentEnergies.last == q.energy) {
        repetitionPenalty += 0.2;
      }
      if (recentSubcategories.isNotEmpty &&
          q.subcategory.isNotEmpty &&
          recentSubcategories.last == q.subcategory) {
        repetitionPenalty += 2.0;
      }

      final formulaWeight =
          baseWeight +
          (q.shockFactor * esc) +
          (q.vulnerabilityLevel * vuln) +
          diversityBonus -
          repetitionPenalty;

      var finalWeight = max(0.05, formulaWeight);
      if (preferLowerShock) {
        final lowShockBoost = (1.25 - q.shockFactor).clamp(0.35, 1.25);
        finalWeight *= lowShockBoost;
      }
      return finalWeight;
    }).toList();

    final totalWeight = weights.fold(0.0, (sum, w) => sum + w);
    var dart = _random.nextDouble() * totalWeight;

    for (int i = 0; i < pool.length; i++) {
      dart -= weights[i];
      if (dart <= 0) return pool[i];
    }
    return pool.last;
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
