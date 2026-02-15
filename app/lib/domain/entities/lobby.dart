import 'package:equatable/equatable.dart';

/// The intensity tone of the current game phase.
enum ToneLevel { safe, deeper, secretive, freaky }

/// Status of a lobby.
enum LobbyStatus { waiting, playing, finished, cancelled }

/// Domain entity for a game lobby.
class Lobby extends Equatable {
  const Lobby({
    required this.id,
    required this.code,
    required this.hostId,
    required this.status,
    required this.language,
    required this.maxRounds,
    required this.currentRound,
    required this.nsfwEnabled,
    required this.boldnessScore,
    required this.currentTone,
    required this.roundTimeoutSeconds,
    this.createdAt,
    this.endedAt,
  });

  final String id;
  final String code;
  final String hostId;
  final LobbyStatus status;
  final String language;
  final int maxRounds;
  final int currentRound;
  final bool nsfwEnabled;
  final double boldnessScore;
  final ToneLevel currentTone;
  final int roundTimeoutSeconds;
  final DateTime? createdAt;
  final DateTime? endedAt;

  bool get isWaiting => status == LobbyStatus.waiting;
  bool get isPlaying => status == LobbyStatus.playing;
  bool get isFinished =>
      status == LobbyStatus.finished || status == LobbyStatus.cancelled;

  Lobby copyWith({
    LobbyStatus? status,
    int? currentRound,
    double? boldnessScore,
    ToneLevel? currentTone,
    String? hostId,
  }) {
    return Lobby(
      id: id,
      code: code,
      hostId: hostId ?? this.hostId,
      status: status ?? this.status,
      language: language,
      maxRounds: maxRounds,
      currentRound: currentRound ?? this.currentRound,
      nsfwEnabled: nsfwEnabled,
      boldnessScore: boldnessScore ?? this.boldnessScore,
      currentTone: currentTone ?? this.currentTone,
      roundTimeoutSeconds: roundTimeoutSeconds,
      createdAt: createdAt,
      endedAt: endedAt,
    );
  }

  factory Lobby.fromMap(Map<String, dynamic> map) {
    final hostId = (map['host_id'] ??
            map['hostId'] ??
            map['host_user_id'] ??
            map['hostUserId']) as String?;
    final statusName = (map['status'] ?? 'waiting') as String;
    return Lobby(
      id: map['id'] as String,
      code: map['code'] as String,
      hostId: hostId ?? '',
      status: LobbyStatus.values.byName(statusName),
      language: map['language'] as String? ?? 'en',
      maxRounds: (map['max_rounds'] ?? map['maxRounds']) as int? ?? 20,
      currentRound: (map['current_round'] ?? map['currentRound']) as int? ?? 0,
      nsfwEnabled:
          (map['nsfw_enabled'] ?? map['nsfwEnabled']) as bool? ?? false,
      boldnessScore:
          ((map['boldness_score'] ?? map['boldnessScore']) as num?)
                  ?.toDouble() ??
              0.0,
      currentTone: ToneLevel.values.byName(
        (map['current_tone'] ?? map['currentTone']) as String? ?? 'safe',
      ),
      roundTimeoutSeconds:
          (map['round_timeout_seconds'] ?? map['roundTimeoutSeconds']) as int? ??
              30,
      createdAt: (map['created_at'] ?? map['createdAt']) != null
          ? DateTime.parse(
              (map['created_at'] ?? map['createdAt']) as String,
            )
          : null,
      endedAt: (map['ended_at'] ?? map['endedAt']) != null
          ? DateTime.parse((map['ended_at'] ?? map['endedAt']) as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        hostId,
        status,
        language,
        maxRounds,
        currentRound,
        nsfwEnabled,
        boldnessScore,
        currentTone,
      ];
}
