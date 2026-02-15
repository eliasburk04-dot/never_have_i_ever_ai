import 'package:get_it/get_it.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/game_repository.dart';
import '../data/repositories/lobby_repository.dart';
import '../data/repositories/offline_session_repository.dart';
import '../data/repositories/premium_repository.dart';
import '../domain/repositories/i_auth_repository.dart';
import '../domain/repositories/i_game_repository.dart';
import '../domain/repositories/i_lobby_repository.dart';
import '../domain/repositories/i_offline_session_repository.dart';
import '../domain/repositories/i_premium_repository.dart';
import '../services/backend_api_service.dart';
import '../services/backend_session_service.dart';
import '../services/local_question_pool.dart';
import '../services/realtime_service.dart';
import '../services/store_kit_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Services
  getIt.registerLazySingleton(() => BackendSessionService());
  getIt.registerLazySingleton(() => BackendApiService(getIt()));
  getIt.registerLazySingleton(() => RealtimeService(getIt()));
  getIt.registerLazySingleton(() => StoreKitService());
  getIt.registerLazySingleton(() => LocalQuestionPool());

  // Repositories
  getIt.registerLazySingleton<IAuthRepository>(
    () => AuthRepository(getIt()),
  );
  getIt.registerLazySingleton<ILobbyRepository>(
    () => LobbyRepository(getIt(), getIt()),
  );
  getIt.registerLazySingleton<IGameRepository>(
    () => GameRepository(getIt(), getIt()),
  );
  getIt.registerLazySingleton<IPremiumRepository>(
    () => PremiumRepository(getIt()),
  );
  getIt.registerLazySingleton<IOfflineSessionRepository>(
    () => OfflineSessionRepository(),
  );
}
