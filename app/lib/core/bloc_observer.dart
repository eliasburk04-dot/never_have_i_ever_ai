import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

/// BLoC observer that logs all state transitions & errors during development.
class AppBlocObserver extends BlocObserver {
  final _log = Logger();

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _log.d(
      '${bloc.runtimeType} → ${transition.event.runtimeType}\n'
      '  from: ${transition.currentState.runtimeType}\n'
      '  to:   ${transition.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _log.e(
      '${bloc.runtimeType} error',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    // Only log Cubit changes (BLoC transitions handled above)
    if (bloc is! Bloc) {
      _log.d(
        '${bloc.runtimeType} changed\n'
        '  from: ${change.currentState.runtimeType}\n'
        '  to:   ${change.nextState.runtimeType}',
      );
    }
  }
}
