import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/game_engine.dart';
import '../../services/supabase_service.dart';
import '../../utils/i18n.dart';
import '../game/realtime_providers.dart';
import '../home/home_screen.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, required this.lobbyId});

  static const routeName = 'results';
  static const routePath = '/results/:lobbyId';

  final String lobbyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallbackLanguage = I18n.resolveLanguageCode(Localizations.localeOf(context).languageCode);
    final lobby = ref.watch(lobbyStreamProvider(lobbyId)).valueOrNull;
    final languageCode = I18n.resolveLanguageCode((lobby?['language'] ?? fallbackLanguage).toString());

    final playersAsync = ref.watch(playersStreamProvider(lobbyId));
    final roundsAsync = ref.watch(roundsStreamProvider(lobbyId));

    return Scaffold(
      appBar: AppBar(title: Text(I18n.tr('results', languageCode: languageCode))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: playersAsync.when(
          data: (players) {
            return roundsAsync.when(
              data: (rounds) {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchAllAnswers(ref, rounds),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final answers = snapshot.data!;
                    final computed = _computeAwards(
                      players: players,
                      rounds: rounds,
                      answers: answers,
                      languageCode: languageCode,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AwardCard(
                          title: I18n.tr('winner', languageCode: languageCode),
                          value: computed.winner,
                          subtitle: I18n.tr('highest_total_score', languageCode: languageCode),
                        ),
                        _AwardCard(
                          title: I18n.tr('fastest', languageCode: languageCode),
                          value: computed.fastest,
                          subtitle: I18n.tr('lowest_avg_response', languageCode: languageCode),
                        ),
                        _AwardCard(
                          title: I18n.tr('bravest', languageCode: languageCode),
                          value: computed.bravest,
                          subtitle: I18n.tr('highest_yes_ratio', languageCode: languageCode),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          I18n.tr('highlights', languageCode: languageCode),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ...computed.highlights.map(
                          (line) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(line),
                            ),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            final lobbyRow = ref.read(lobbyStreamProvider(lobbyId)).valueOrNull;
                            final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                            final isHost = lobbyRow != null &&
                                (lobbyRow['host_user_id'] ?? '').toString() == (currentUserId ?? '');

                            if (isHost) {
                              try {
                                await ref.read(supabaseServiceProvider).cleanupLobby(lobbyId);
                              } catch (_) {
                                // If cleanup fails, still allow navigation out of results.
                              }
                            }

                            if (context.mounted) {
                              context.goNamed(HomeScreen.routeName);
                            }
                          },
                          child: Text(I18n.tr('back_to_home', languageCode: languageCode)),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllAnswers(WidgetRef ref, List<Map<String, dynamic>> rounds) async {
    final roundIds = rounds.map((round) => (round['id'] ?? '').toString()).where((id) => id.isNotEmpty).toList();
    if (roundIds.isEmpty) {
      return const [];
    }

    return ref.read(supabaseServiceProvider).fetchAnswersForRounds(roundIds);
  }

  _ComputedAwards _computeAwards({
    required List<Map<String, dynamic>> players,
    required List<Map<String, dynamic>> rounds,
    required List<Map<String, dynamic>> answers,
    required String languageCode,
  }) {
    if (players.isEmpty) {
      return _ComputedAwards(
        winner: 'N/A',
        fastest: 'N/A',
        bravest: 'N/A',
        highlights: [I18n.tr('no_players_found', languageCode: languageCode)],
      );
    }

    final scoreByPlayer = <String, int>{for (final p in players) _asString(p['id']): 0};
    final responseTimeByPlayer = <String, List<int>>{for (final p in players) _asString(p['id']): []};
    final yesCountByPlayer = <String, int>{for (final p in players) _asString(p['id']): 0};
    final answerCountByPlayer = <String, int>{for (final p in players) _asString(p['id']): 0};
    final soloConfessionsByPlayer = <String, int>{for (final p in players) _asString(p['id']): 0};

    final playersById = <String, Map<String, dynamic>>{
      for (final player in players) _asString(player['id']): player,
    };

    for (final round in rounds) {
      final roundId = _asString(round['id']);
      final roundAnswers = answers.where((a) => _asString(a['round_id']) == roundId).toList(growable: false);

      final engineAnswers = roundAnswers
          .map(
            (a) => PlayerRoundAnswer.fromRaw(
              playerId: _asString(a['player_id']),
              answer: _asString(a['answer']),
              responseTimeMs: _toInt(a['response_time_ms']),
            ),
          )
          .toList(growable: false);

      final deltas = GameEngine.scoreRound(
        answers: engineAnswers,
        totalPlayersInRound: players.length,
      );

      for (final entry in deltas.entries) {
        scoreByPlayer[entry.key] = (scoreByPlayer[entry.key] ?? 0) + entry.value;
      }

      final yesPlayers = roundAnswers.where((a) => _asString(a['answer']) == 'yes').toList(growable: false);
      if (yesPlayers.length == 1) {
        final soloId = _asString(yesPlayers.first['player_id']);
        soloConfessionsByPlayer[soloId] = (soloConfessionsByPlayer[soloId] ?? 0) + 1;
      }

      for (final answer in roundAnswers) {
        final playerId = _asString(answer['player_id']);
        answerCountByPlayer[playerId] = (answerCountByPlayer[playerId] ?? 0) + 1;
        if (_asString(answer['answer']) == 'yes') {
          yesCountByPlayer[playerId] = (yesCountByPlayer[playerId] ?? 0) + 1;
        }
        responseTimeByPlayer[playerId]?.add(_toInt(answer['response_time_ms']));
      }
    }

    String displayName(String playerId) {
      final player = playersById[playerId];
      final nick = _asString(player?['nickname']);
      return nick.isEmpty ? I18n.tr('nickname', languageCode: languageCode) : nick;
    }

    final winnerId = scoreByPlayer.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    final fastestId = responseTimeByPlayer.entries
        .map((entry) {
          final values = entry.value;
          final avg = values.isEmpty ? 999999.0 : values.reduce((a, b) => a + b) / values.length;
          return MapEntry(entry.key, avg);
        })
        .reduce((a, b) => a.value <= b.value ? a : b)
        .key;

    final bravestId = players
        .map((player) {
          final id = _asString(player['id']);
          final answersCount = answerCountByPlayer[id] ?? 0;
          final yesRatio = answersCount == 0 ? 0.0 : (yesCountByPlayer[id] ?? 0) / answersCount;
          final solo = soloConfessionsByPlayer[id] ?? 0;
          final score = yesRatio * 100 + solo * 10;
          return MapEntry(id, score);
        })
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    return _ComputedAwards(
      winner: displayName(winnerId),
      fastest: displayName(fastestId),
      bravest: displayName(bravestId),
      highlights: [
        I18n.tr(
          'won_with_points',
          languageCode: languageCode,
          params: {
            'name': displayName(winnerId),
            'points': (scoreByPlayer[winnerId] ?? 0).toString(),
          },
        ),
        I18n.tr(
          'reacted_fastest',
          languageCode: languageCode,
          params: {'name': displayName(fastestId)},
        ),
        I18n.tr(
          'boldest_profile',
          languageCode: languageCode,
          params: {'name': displayName(bravestId)},
        ),
      ],
    );
  }

  int _toInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  String _asString(Object? value) {
    return (value ?? '').toString();
  }
}

class _ComputedAwards {
  const _ComputedAwards({
    required this.winner,
    required this.fastest,
    required this.bravest,
    required this.highlights,
  });

  final String winner;
  final String fastest;
  final String bravest;
  final List<String> highlights;
}

class _AwardCard extends StatelessWidget {
  const _AwardCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
