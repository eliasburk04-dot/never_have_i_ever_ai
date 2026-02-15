import 'dart:async';
import 'dart:math';

import 'package:logger/logger.dart';

import '../core/constants/app_constants.dart';

/// Handles exponential backoff reconnection logic for Realtime channels.
class ReconnectService {
  ReconnectService();

  final _log = Logger();
  int _retryCount = 0;
  Timer? _retryTimer;
  bool _isReconnecting = false;

  /// Whether a reconnection is currently in progress.
  bool get isReconnecting => _isReconnecting;

  /// Current retry count.
  int get retryCount => _retryCount;

  /// Schedule a reconnection with exponential backoff.
  ///
  /// [onReconnect] is called after the delay. Return `true` if successful.
  Future<bool> scheduleReconnect(Future<bool> Function() onReconnect) async {
    if (_retryCount >= AppConstants.maxReconnectRetries) {
      _log.e('Max reconnect retries ($retryCount) reached — giving up');
      reset();
      return false;
    }

    _isReconnecting = true;
    _retryCount++;

    // Exponential backoff with jitter
    final baseDelay = AppConstants.reconnectBaseDelayMs;
    final maxDelay = AppConstants.reconnectMaxDelayMs;
    final exponential = baseDelay * pow(2, _retryCount - 1);
    final jitter = Random().nextInt(baseDelay);
    final delay = min(exponential + jitter, maxDelay);

    _log.i('Reconnect attempt $_retryCount in ${delay}ms');

    final completer = Completer<bool>();

    _retryTimer = Timer(Duration(milliseconds: delay.toInt()), () async {
      try {
        final success = await onReconnect();
        if (success) {
          _log.i('Reconnect successful on attempt $_retryCount');
          reset();
          completer.complete(true);
        } else {
          _isReconnecting = false;
          completer.complete(false);
        }
      } catch (e) {
        _log.e('Reconnect attempt $_retryCount failed', error: e);
        _isReconnecting = false;
        completer.complete(false);
      }
    });

    return completer.future;
  }

  /// Reset retry state (call on successful connection).
  void reset() {
    _retryCount = 0;
    _isReconnecting = false;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Cancel any pending reconnection attempts.
  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
