import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/statement.dart';
import '../../services/statement_providers.dart';
import '../../services/supabase_service.dart';
import '../../utils/i18n.dart';
import '../game/game_screen.dart';
import '../game/realtime_providers.dart';

class LobbyWaitingScreen extends ConsumerStatefulWidget {
  const LobbyWaitingScreen({super.key, required this.lobbyId});

  static const routeName = 'lobby-waiting';
  static const routePath = '/lobby/:lobbyId';

  final String lobbyId;

  @override
  ConsumerState<LobbyWaitingScreen> createState() => _LobbyWaitingScreenState();
}

class _LobbyWaitingScreenState extends ConsumerState<LobbyWaitingScreen> {
  bool _starting = false;
  String? _error;

  Future<void> _startGame(Map<String, dynamic> lobby) async {
    setState(() {
      _starting = true;
      _error = null;
    });

    final service = ref.read(supabaseServiceProvider);
    final localProvider = ref.read(localDeckStatementProvider);
    final rewriteProvider = ref.read(groqRewriteStatementProvider);

    try {
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

      if (!mounted) return;
      context.goNamed(GameScreen.routeName, pathParameters: {'lobbyId': widget.lobbyId});
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lobbyAsync = ref.watch(lobbyStreamProvider(widget.lobbyId));
    final playersAsync = ref.watch(playersStreamProvider(widget.lobbyId));
    final fallbackLanguage = I18n.resolveLanguageCode(Localizations.localeOf(context).languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(I18n.tr('lobby', languageCode: fallbackLanguage))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: lobbyAsync.when(
          data: (lobby) {
            if (lobby == null) {
              return Center(child: Text(I18n.tr('lobby_not_found', languageCode: fallbackLanguage)));
            }
            final languageCode = I18n.resolveLanguageCode(_asString(lobby['language']));

            final currentUserId = Supabase.instance.client.auth.currentUser?.id;
            final isHost = _asString(lobby['host_user_id']) == currentUserId;
            final code = _asString(lobby['code']);
            final status = _asString(lobby['status']);

            if (status == 'in_progress') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.goNamed(GameScreen.routeName, pathParameters: {'lobbyId': widget.lobbyId});
                }
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${I18n.tr('code', languageCode: languageCode)}: $code',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Chip(
                          label: Text(
                            status.toLowerCase() == 'waiting'
                                ? I18n.tr('waiting_status', languageCode: languageCode).toUpperCase()
                                : status.toUpperCase(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: playersAsync.when(
                        data: (players) => ListView.separated(
                          itemCount: players.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final player = players[index];
                            final nickname = _asString(player['nickname']).isEmpty
                                ? I18n.tr('nickname', languageCode: languageCode)
                                : _asString(player['nickname']);
                            final mine = _asString(player['auth_user_id']) == currentUserId;
                            return ListTile(
                              title: Text(
                                mine
                                    ? '$nickname (${I18n.tr('you_are_player', languageCode: languageCode)})'
                                    : nickname,
                              ),
                              subtitle: Text(
                                '${I18n.tr('score', languageCode: languageCode)}: ${_toInt(player['score'])}',
                              ),
                            );
                          },
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, _) => Center(child: Text(error.toString())),
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 8),
                if (isHost)
                  ElevatedButton(
                    onPressed: _starting ? null : () => _startGame(lobby),
                    child: Text(
                      _starting
                          ? I18n.tr('starting', languageCode: languageCode)
                          : I18n.tr('start_game', languageCode: languageCode),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      I18n.tr('waiting_for_host', languageCode: languageCode),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
      ),
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
