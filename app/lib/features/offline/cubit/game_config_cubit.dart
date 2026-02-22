import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/offline_player.dart';

// ─── State ─────────────────────────────────────────────────

class GameConfigState extends Equatable {
  const GameConfigState({
    this.players = const [],
    this.maxRounds = 20,
    this.nsfwEnabled = false,
    this.language = 'en',
    this.isDrinkingGame = false,
    this.customQuestions = const [],
  });

  final List<OfflinePlayer> players;
  final int maxRounds;
  final bool nsfwEnabled;
  final String language;
  final bool isDrinkingGame;
  final List<String> customQuestions;

  GameConfigState copyWith({
    List<OfflinePlayer>? players,
    int? maxRounds,
    bool? nsfwEnabled,
    String? language,
    bool? isDrinkingGame,
    List<String>? customQuestions,
  }) {
    return GameConfigState(
      players: players ?? this.players,
      maxRounds: maxRounds ?? this.maxRounds,
      nsfwEnabled: nsfwEnabled ?? this.nsfwEnabled,
      language: language ?? this.language,
      isDrinkingGame: isDrinkingGame ?? this.isDrinkingGame,
      customQuestions: customQuestions ?? this.customQuestions,
    );
  }

  @override
  List<Object?> get props => [players, maxRounds, nsfwEnabled, language, isDrinkingGame, customQuestions];
}

// ─── Cubit ─────────────────────────────────────────────────

/// Manages game configuration that persists across "Play Again" cycles.
///
/// Settings are saved to SharedPreferences so they survive app restarts.
/// Player names, rounds, NSFW toggle, and language are all preserved.
class GameConfigCubit extends Cubit<GameConfigState> {
  GameConfigCubit() : super(const GameConfigState());

  /// Load persisted settings from SharedPreferences.
  Future<void> loadPersistedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString('language') ?? 'en';
    final maxRounds = prefs.getInt('maxRounds') ?? 20;
    final nsfwEnabled = prefs.getBool('nsfwEnabled') ?? false;
    final isDrinkingGame = prefs.getBool('isDrinkingGame') ?? false;
    final customQuestions = prefs.getStringList('customQuestions') ?? [];

    // Restore player names if available
    final playerNames = prefs.getStringList('playerNames') ?? [];
    final playerEmojis = prefs.getStringList('playerEmojis') ?? [];

    List<OfflinePlayer> players = [];
    if (playerNames.isNotEmpty) {
      players = List.generate(
        playerNames.length,
        (i) => OfflinePlayer(
          name: playerNames[i],
          emoji: i < playerEmojis.length ? playerEmojis[i] : '😎',
        ),
      );
    }

    emit(GameConfigState(
      players: players,
      maxRounds: maxRounds,
      nsfwEnabled: nsfwEnabled,
      language: language,
      isDrinkingGame: isDrinkingGame,
      customQuestions: customQuestions,
    ));
  }

  void setLanguage(String language) {
    emit(state.copyWith(language: language));
    _persistLanguage(language);
  }

  void setMaxRounds(int rounds) {
    emit(state.copyWith(maxRounds: rounds));
    _persist();
  }

  void setNsfwEnabled(bool enabled) {
    emit(state.copyWith(nsfwEnabled: enabled));
    _persist();
  }

  void setIsDrinkingGame(bool enabled) {
    emit(state.copyWith(isDrinkingGame: enabled));
    _persist();
  }

  void setPlayers(List<OfflinePlayer> players) {
    emit(state.copyWith(players: players));
    _persistPlayers(players);
  }

  void addCustomQuestion(String question) {
    if (question.trim().isEmpty) return;
    final list = List<String>.from(state.customQuestions)..add(question.trim());
    emit(state.copyWith(customQuestions: list));
    _persistCustomQuestions(list);
  }

  void removeCustomQuestion(int index) {
    if (index < 0 || index >= state.customQuestions.length) return;
    final list = List<String>.from(state.customQuestions)..removeAt(index);
    emit(state.copyWith(customQuestions: list));
    _persistCustomQuestions(list);
  }

  // ─── Persistence ─────────────────────────────────────

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxRounds', state.maxRounds);
    await prefs.setBool('nsfwEnabled', state.nsfwEnabled);
    await prefs.setBool('isDrinkingGame', state.isDrinkingGame);
  }

  Future<void> _persistLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }

  Future<void> _persistPlayers(List<OfflinePlayer> players) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'playerNames',
      players.map((p) => p.name).toList(),
    );
    await prefs.setStringList(
      'playerEmojis',
      players.map((p) => p.emoji).toList(),
    );
  }

  Future<void> _persistCustomQuestions(List<String> questions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('customQuestions', questions);
  }
}
