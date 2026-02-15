import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'offline_player.dart';

// ─── OfflineRound ──────────────────────────────────────────

/// A single round played in offline mode.
class OfflineRound {
  const OfflineRound({
    required this.roundNumber,
    required this.questionText,
    this.questionId,
    required this.tone,
    required this.intensity,
    required this.haveCount,
    required this.haveNotCount,
    required this.totalPlayers,
    this.recycled = false,
    this.category,
    this.subcategory,
  });

  final int roundNumber;
  final String questionText;
  final String? questionId;
  final String tone;
  final int intensity;
  final int haveCount;
  final int haveNotCount;
  final int totalPlayers;
  final bool recycled;
  final String? category;
  final String? subcategory;

  double get haveRatio =>
      totalPlayers > 0 ? haveCount / totalPlayers : 0.0;

  Map<String, dynamic> toMap() => {
        'roundNumber': roundNumber,
        'questionText': questionText,
        'questionId': questionId,
        'tone': tone,
        'intensity': intensity,
        'haveCount': haveCount,
        'haveNotCount': haveNotCount,
        'totalPlayers': totalPlayers,
        'recycled': recycled,
        'category': category,
        'subcategory': subcategory,
      };

  factory OfflineRound.fromMap(Map<String, dynamic> map) => OfflineRound(
        roundNumber: map['roundNumber'] as int,
        questionText: map['questionText'] as String,
        questionId: map['questionId'] as String?,
        tone: map['tone'] as String,
        intensity: map['intensity'] as int,
        haveCount: map['haveCount'] as int,
        haveNotCount: map['haveNotCount'] as int,
        totalPlayers: map['totalPlayers'] as int,
        recycled: map['recycled'] as bool? ?? false,
        category: map['category'] as String?,
        subcategory: map['subcategory'] as String?,
      );
}

// ─── OfflineSession ────────────────────────────────────────

/// Full state of an offline pass-and-play game session.
/// Persisted to Hive as a JSON string.
class OfflineSession extends Equatable {
  const OfflineSession({
    required this.id,
    required this.players,
    required this.maxRounds,
    required this.currentRound,
    required this.language,
    required this.nsfwEnabled,
    required this.boldnessScore,
    required this.currentTone,
    this.rounds = const [],
    this.usedQuestionIds = const [],
    this.isComplete = false,
    this.createdAt,
  });

  final String id;
  final List<OfflinePlayer> players;
  final int maxRounds;
  final int currentRound;
  final String language;
  final bool nsfwEnabled;
  final double boldnessScore;
  final String currentTone;
  final List<OfflineRound> rounds;
  final List<String> usedQuestionIds;
  final bool isComplete;
  final DateTime? createdAt;

  int get playerCount => players.length;

  OfflineSession copyWith({
    List<OfflinePlayer>? players,
    int? currentRound,
    double? boldnessScore,
    String? currentTone,
    List<OfflineRound>? rounds,
    List<String>? usedQuestionIds,
    bool? isComplete,
  }) {
    return OfflineSession(
      id: id,
      players: players ?? this.players,
      maxRounds: maxRounds,
      currentRound: currentRound ?? this.currentRound,
      language: language,
      nsfwEnabled: nsfwEnabled,
      boldnessScore: boldnessScore ?? this.boldnessScore,
      currentTone: currentTone ?? this.currentTone,
      rounds: rounds ?? this.rounds,
      usedQuestionIds: usedQuestionIds ?? this.usedQuestionIds,
      isComplete: isComplete ?? this.isComplete,
      createdAt: createdAt,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory OfflineSession.fromJson(String json) =>
      OfflineSession.fromMap(jsonDecode(json) as Map<String, dynamic>);

  Map<String, dynamic> toMap() => {
        'id': id,
        'players': players.map((p) => p.toMap()).toList(),
        'maxRounds': maxRounds,
        'currentRound': currentRound,
        'language': language,
        'nsfwEnabled': nsfwEnabled,
        'boldnessScore': boldnessScore,
        'currentTone': currentTone,
        'rounds': rounds.map((r) => r.toMap()).toList(),
        'usedQuestionIds': usedQuestionIds,
        'isComplete': isComplete,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory OfflineSession.fromMap(Map<String, dynamic> map) {
    return OfflineSession(
      id: map['id'] as String,
      players: (map['players'] as List)
          .map((p) => OfflinePlayer.fromMap(p as Map<String, dynamic>))
          .toList(),
      maxRounds: map['maxRounds'] as int,
      currentRound: map['currentRound'] as int,
      language: map['language'] as String,
      nsfwEnabled: map['nsfwEnabled'] as bool,
      boldnessScore: (map['boldnessScore'] as num).toDouble(),
      currentTone: map['currentTone'] as String,
      rounds: (map['rounds'] as List)
          .map((r) => OfflineRound.fromMap(r as Map<String, dynamic>))
          .toList(),
      usedQuestionIds: List<String>.from(map['usedQuestionIds'] as List),
      isComplete: map['isComplete'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        players,
        maxRounds,
        currentRound,
        language,
        nsfwEnabled,
        boldnessScore,
        currentTone,
        rounds,
        usedQuestionIds,
        isComplete,
        createdAt,
      ];
}
