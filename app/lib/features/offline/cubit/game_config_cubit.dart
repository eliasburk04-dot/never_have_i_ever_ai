import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/creator_packs.dart';
import '../../../core/constants/game_setup_config.dart';
import '../../../domain/entities/offline_player.dart';

const _unsetSelectedPackId = Object();

class GameConfigState extends Equatable {
  const GameConfigState({
    this.players = const [],
    this.maxRounds = 20,
    this.nsfwEnabled = false,
    this.language = 'en',
    this.categories = GameSetupConfig.defaultCategories,
    this.selectedPackId = CreatorPacks.defaultSelectionId,
  });

  final List<OfflinePlayer> players;
  final int maxRounds;
  final bool nsfwEnabled;
  final String language;
  final List<String> categories;
  final String? selectedPackId;

  GameConfigState copyWith({
    List<OfflinePlayer>? players,
    int? maxRounds,
    bool? nsfwEnabled,
    String? language,
    List<String>? categories,
    Object? selectedPackId = _unsetSelectedPackId,
  }) {
    return GameConfigState(
      players: players ?? this.players,
      maxRounds: maxRounds ?? this.maxRounds,
      nsfwEnabled: nsfwEnabled ?? this.nsfwEnabled,
      language: language ?? this.language,
      categories: categories ?? this.categories,
      selectedPackId: selectedPackId == _unsetSelectedPackId
          ? this.selectedPackId
          : selectedPackId as String?,
    );
  }

  @override
  List<Object?> get props => [
    players,
    maxRounds,
    nsfwEnabled,
    language,
    categories,
    selectedPackId,
  ];
}

class GameConfigCubit extends Cubit<GameConfigState> {
  GameConfigCubit() : super(const GameConfigState());

  Future<void> loadPersistedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString('language') ?? 'en';
    final maxRounds = prefs.getInt('maxRounds') ?? 20;
    final nsfwEnabled = prefs.getBool('nsfwEnabled') ?? false;
    final categories =
        prefs.getStringList('categories') ?? GameSetupConfig.defaultCategories;

    final legacyPackIds = prefs.getStringList('selectedPackIds') ?? [];
    final savedPackId =
        prefs.getString('selectedPackId') ??
        (legacyPackIds.isNotEmpty
            ? legacyPackIds.first
            : CreatorPacks.defaultSelectionId);
    final selectedPackId = CreatorPacks.byId(savedPackId) != null
        ? savedPackId
        : null;

    final playerNames = prefs.getStringList('playerNames') ?? [];
    final playerEmojis = prefs.getStringList('playerEmojis') ?? [];

    final players = playerNames.isEmpty
        ? <OfflinePlayer>[]
        : List.generate(
            playerNames.length,
            (i) => OfflinePlayer(
              name: playerNames[i],
              emoji: i < playerEmojis.length ? playerEmojis[i] : '😎',
            ),
          );

    emit(
      GameConfigState(
        players: players,
        maxRounds: maxRounds,
        nsfwEnabled: nsfwEnabled,
        language: language,
        categories: categories,
        selectedPackId: selectedPackId,
      ),
    );
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

  void setCategories(List<String> categories) {
    emit(state.copyWith(categories: categories));
    _persistCategories(categories);
  }

  void setSelectedPackId(String? packId) {
    if (packId != null && CreatorPacks.byId(packId) == null) return;
    emit(state.copyWith(selectedPackId: packId));
    _persistSelectedPackId(packId);
  }

  void toggleSelectedPackId(String packId) {
    final next = state.selectedPackId == packId ? null : packId;
    setSelectedPackId(next);
  }

  void setPlayers(List<OfflinePlayer> players) {
    emit(state.copyWith(players: players));
    _persistPlayers(players);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxRounds', state.maxRounds);
    await prefs.setBool('nsfwEnabled', state.nsfwEnabled);
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

  Future<void> _persistCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('categories', categories);
  }

  Future<void> _persistSelectedPackId(String? packId) async {
    final prefs = await SharedPreferences.getInstance();
    if (packId == null) {
      await prefs.remove('selectedPackId');
      await prefs.setStringList('selectedPackIds', const []);
      return;
    }
    await prefs.setString('selectedPackId', packId);
    await prefs.setStringList('selectedPackIds', [packId]);
  }
}
