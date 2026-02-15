import 'package:equatable/equatable.dart';

/// Connection state of a player.
enum PlayerStatus { connected, disconnected, left }

/// Domain entity for a player in a lobby.
class Player extends Equatable {
  const Player({
    required this.id,
    required this.lobbyId,
    required this.userId,
    required this.displayName,
    required this.avatarEmoji,
    required this.status,
    required this.isHost,
  });

  final String id;
  final String lobbyId;
  final String userId;
  final String displayName;
  final String avatarEmoji;
  final PlayerStatus status;
  final bool isHost;

  bool get isConnected => status == PlayerStatus.connected;

  factory Player.fromMap(Map<String, dynamic> map) {
    final statusName = (map['status'] ?? 'connected') as String;
    return Player(
      id: map['id'] as String,
      lobbyId: (map['lobby_id'] ?? map['lobbyId']) as String,
      userId: (map['user_id'] ?? map['userId']) as String,
      displayName:
          (map['display_name'] ?? map['displayName']) as String? ?? 'Player',
      avatarEmoji:
          (map['avatar_emoji'] ?? map['avatarEmoji']) as String? ?? '😎',
      status: PlayerStatus.values.byName(statusName),
      isHost: (map['is_host'] ?? map['isHost']) as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [id, lobbyId, userId, displayName, avatarEmoji, status, isHost];
}
