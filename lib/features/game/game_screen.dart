import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/statement.dart';
import '../../services/statement_providers.dart';
import '../../services/supabase_service.dart';
import '../../utils/i18n.dart';
import '../results/results_screen.dart';
import 'realtime_providers.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.lobbyId});

  static const routeName = 'game';
  static const routePath = '/game/:lobbyId';

  final String lobbyId;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  static const _roundDuration = Duration(seconds: 6);
  static const _revealDuration = Duration(seconds: 2);

  Timer? _ticker;
  bool _endingRound = false;
  bool _progressing = false;
  bool _submittingAnswer = false;
  String? _lastProgressedRoundId;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted) return;
      setState(() {});
      _handleAutoProgress();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _handleAutoProgress() async {
    final lobbyAsync = ref.read(lobbyStreamProvider(widget.lobbyId));
    final roundsAsync = ref.read(roundsStreamProvider(widget.lobbyId));

    final lobby = lobbyAsync.valueOrNull;
    final rounds = roundsAsync.valueOrNull;

    if (lobby == null || rounds == null || rounds.isEmpty) {
      return;
    }

    if (_asString(lobby['status']) == 'finished') {
      if (!mounted) return;
      context.goNamed(ResultsScreen.routeName, pathParameters: {'lobbyId': widget.lobbyId});
      return;
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isHost = currentUserId != null && _asString(lobby['host_user_id']) == currentUserId;
    if (!isHost) {
      return;
    }

    final currentRound = rounds.last;
    final roundId = _asString(currentRound['id']);
    final endedAtRaw = currentRound['ended_at'];

    if (endedAtRaw == null) {
      final remainingMs = _remainingMilliseconds(currentRound);
      if (remainingMs <= 0 && !_endingRound) {
        _endingRound = true;
        try {
          await ref.read(supabaseServiceProvider).endRound(roundId: roundId);
        } finally {
          _endingRound = false;
        }
      }
      return;
    }

    if (_lastProgressedRoundId == roundId || _progressing) {
      return;
    }

    final endedAt = DateTime.tryParse(_asString(endedAtRaw))?.toUtc();
    if (endedAt == null) {
      return;
    }

    final showRevealFor = DateTime.now().toUtc().difference(endedAt);
    if (showRevealFor < _revealDuration) {
      return;
    }

    _progressing = true;
    try {
      final roundLimit = _toInt(lobby['round_limit'], fallback: 5);
      if (rounds.length >= roundLimit) {
        await ref.read(supabaseServiceProvider).finishGame(widget.lobbyId);
      } else {
        await _startNextRound(lobby);
      }
      _lastProgressedRoundId = roundId;
    } finally {
      _progressing = false;
    }
  }

  Future<void> _startNextRound(Map<String, dynamic> lobby) async {
    final localProvider = ref.read(localDeckStatementProvider);
    final rewriteProvider = ref.read(groqRewriteStatementProvider);
    final service = ref.read(supabaseServiceProvider);

    final language = StatementLanguage.fromCode(_asString(lobby['language']));
    final riskLevel = _toInt(lobby['risk_level'], fallback: 1);

    final statement = await rewriteProvider.nextStatement(
      localProvider: localProvider,
      language: language,
      riskLevel: riskLevel,
    );

    await service.startRound(
      lobbyId: widget.lobbyId,
      statement: statement.text,
      riskLevel: riskLevel,
    );
  }

  Future<void> _submitAnswer({
    required String roundId,
    required String playerId,
    required String answer,
    required int responseTimeMs,
  }) async {
    if (_submittingAnswer) {
      return;
    }

    setState(() => _submittingAnswer = true);
    try {
      await ref.read(supabaseServiceProvider).submitAnswer(
            roundId: roundId,
            playerId: playerId,
            answer: answer,
            responseTimeMs: responseTimeMs,
          );
    } finally {
      if (mounted) {
        setState(() => _submittingAnswer = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lobbyAsync = ref.watch(lobbyStreamProvider(widget.lobbyId));
    final playersAsync = ref.watch(playersStreamProvider(widget.lobbyId));
    final roundsAsync = ref.watch(roundsStreamProvider(widget.lobbyId));
    final fallbackLanguage = I18n.resolveLanguageCode(Localizations.localeOf(context).languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(I18n.tr('game', languageCode: fallbackLanguage))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: lobbyAsync.when(
          data: (lobby) {
            if (lobby == null) {
              return Center(child: Text(I18n.tr('lobby_not_found', languageCode: fallbackLanguage)));
            }
            final languageCode = I18n.resolveLanguageCode(_asString(lobby['language']));

            return roundsAsync.when(
              data: (rounds) {
                if (_asString(lobby['status']) == 'finished') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      context.goNamed(ResultsScreen.routeName, pathParameters: {'lobbyId': widget.lobbyId});
                    }
                  });
                }

                if (rounds.isEmpty) {
                  return Center(child: Text(I18n.tr('preparing_first_round', languageCode: languageCode)));
                }

                final round = rounds.last;
                final roundId = _asString(round['id']);
                final roundEnded = round['ended_at'] != null;
                final statement = _asString(round['statement']);
                final riskLevel = _toInt(round['risk_level'], fallback: 1);

                final answersAsync = ref.watch(roundAnswersStreamProvider(roundId));

                return playersAsync.when(
                  data: (players) {
                    final userId = Supabase.instance.client.auth.currentUser?.id;
                    final me = players.cast<Map<String, dynamic>?>().firstWhere(
                          (player) => _asString(player?['auth_user_id']) == userId,
                          orElse: () => null,
                        );

                    if (me == null) {
                      return Center(child: Text(I18n.tr('you_not_player', languageCode: languageCode)));
                    }

                    final myPlayerId = _asString(me['id']);
                    final myNickname = _asString(me['nickname']).isEmpty
                        ? I18n.tr('you_are_player', languageCode: languageCode)
                        : _asString(me['nickname']);

                    final startedAt = DateTime.tryParse(_asString(round['started_at']))?.toUtc();
                    final remainingSeconds = startedAt == null
                        ? 0
                        : (_remainingMilliseconds(round) / 1000).ceil().clamp(0, 6);

                    return answersAsync.when(
                      data: (answers) {
                        Map<String, dynamic>? myAnswer;
                        for (final answer in answers) {
                          if (_asString(answer['player_id']) == myPlayerId) {
                            myAnswer = answer;
                            break;
                          }
                        }
                        final alreadyAnswered = myAnswer != null;

                        final yesPlayerIds = answers
                            .where((a) => _asString(a['answer']) == 'yes')
                            .map((a) => _asString(a['player_id']))
                            .toSet();

                        final yesNames = players
                            .where((player) => yesPlayerIds.contains(_asString(player['id'])))
                            .map((player) {
                              final nick = _asString(player['nickname']);
                              return nick.isEmpty ? 'Player' : nick;
                            })
                            .toList(growable: false);

                        final responseTimeMs = startedAt == null
                            ? 0
                            : DateTime.now().toUtc().difference(startedAt).inMilliseconds.clamp(0, 600000);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${I18n.tr('risk', languageCode: languageCode)} $riskLevel',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Chip(
                                  label: Text(
                                    '${I18n.tr('timer', languageCode: languageCode)}: $remainingSeconds',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  statement,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (!roundEnded)
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: alreadyAnswered || _submittingAnswer
                                          ? null
                                              : () => _submitAnswer(
                                                roundId: roundId,
                                                playerId: myPlayerId,
                                                answer: 'yes',
                                                responseTimeMs: responseTimeMs,
                                              ),
                                      child: Text(I18n.tr('yes', languageCode: languageCode)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: alreadyAnswered || _submittingAnswer
                                          ? null
                                              : () => _submitAnswer(
                                                roundId: roundId,
                                                playerId: myPlayerId,
                                                answer: 'no',
                                                responseTimeMs: responseTimeMs,
                                              ),
                                      child: Text(I18n.tr('no', languageCode: languageCode)),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Card(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        I18n.tr('round_reveal', languageCode: languageCode),
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        yesNames.isEmpty
                                            ? I18n.tr('no_yes_clicked', languageCode: languageCode)
                                            : I18n.tr(
                                                'yes_list',
                                                languageCode: languageCode,
                                                params: {'names': yesNames.join(', ')},
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              alreadyAnswered
                                  ? I18n.tr(
                                      'locked_in',
                                      languageCode: languageCode,
                                      params: {
                                        'name': myNickname,
                                        'answer': _asString(myAnswer['answer']).toUpperCase(),
                                      },
                                    )
                                  : I18n.tr(
                                      'choose_before_time',
                                      languageCode: languageCode,
                                      params: {'name': myNickname},
                                    ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Card(
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: players.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final player = players[index];
                                    final playerId = _asString(player['id']);
                                    final nick = _asString(player['nickname']).isEmpty
                                        ? I18n.tr('nickname', languageCode: languageCode)
                                        : _asString(player['nickname']);
                                    final answered = answers.any((a) => _asString(a['player_id']) == playerId);
                                    return ListTile(
                                      title: Text(nick),
                                      trailing: Icon(
                                        answered ? Icons.check_circle : Icons.hourglass_bottom,
                                        color: answered ? Colors.green : Colors.orange,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(child: Text(error.toString())),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text(error.toString())),
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

  int _remainingMilliseconds(Map<String, dynamic> round) {
    final startedAt = DateTime.tryParse(_asString(round['started_at']))?.toUtc();
    if (startedAt == null) {
      return 0;
    }

    final elapsed = DateTime.now().toUtc().difference(startedAt).inMilliseconds;
    final remaining = _roundDuration.inMilliseconds - elapsed;
    return remaining > 0 ? remaining : 0;
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
