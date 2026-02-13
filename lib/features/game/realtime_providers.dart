import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_service.dart';

final lobbyStreamProvider =
    StreamProvider.family.autoDispose<Map<String, dynamic>?, String>((ref, lobbyId) {
  return ref.watch(supabaseServiceProvider).subscribeLobby(lobbyId);
});

final playersStreamProvider =
    StreamProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, lobbyId) {
  return ref.watch(supabaseServiceProvider).subscribePlayers(lobbyId);
});

final roundsStreamProvider =
    StreamProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, lobbyId) {
  return ref.watch(supabaseServiceProvider).subscribeRounds(lobbyId);
});

final roundAnswersStreamProvider =
    StreamProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, roundId) {
  return ref.watch(supabaseServiceProvider).subscribeAnswers(roundId);
});
