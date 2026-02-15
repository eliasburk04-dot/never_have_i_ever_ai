import 'package:equatable/equatable.dart';

/// A lightweight player for offline pass-and-play mode.
/// Only a name + emoji — no server user ID needed.
class OfflinePlayer extends Equatable {
  const OfflinePlayer({
    required this.name,
    required this.emoji,
    this.haveCount = 0,
    this.totalRoundsPlayed = 0,
  });

  final String name;
  final String emoji;
  final int haveCount;
  final int totalRoundsPlayed;

  double get haveRatio =>
      totalRoundsPlayed > 0 ? haveCount / totalRoundsPlayed : 0.0;

  OfflinePlayer copyWith({
    int? haveCount,
    int? totalRoundsPlayed,
  }) {
    return OfflinePlayer(
      name: name,
      emoji: emoji,
      haveCount: haveCount ?? this.haveCount,
      totalRoundsPlayed: totalRoundsPlayed ?? this.totalRoundsPlayed,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'emoji': emoji,
        'haveCount': haveCount,
        'totalRoundsPlayed': totalRoundsPlayed,
      };

  factory OfflinePlayer.fromMap(Map<String, dynamic> map) => OfflinePlayer(
        name: map['name'] as String,
        emoji: map['emoji'] as String,
        haveCount: map['haveCount'] as int? ?? 0,
        totalRoundsPlayed: map['totalRoundsPlayed'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [name, emoji, haveCount, totalRoundsPlayed];
}
