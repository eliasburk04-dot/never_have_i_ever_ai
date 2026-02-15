import 'package:flutter_test/flutter_test.dart';

import 'package:nhie_app/services/reconnect_service.dart';

void main() {
  group('ReconnectService', () {
    late ReconnectService service;

    setUp(() {
      service = ReconnectService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state', () {
      expect(service.isReconnecting, false);
      expect(service.retryCount, 0);
    });

    test('scheduleReconnect increments retryCount', () async {
      await service.scheduleReconnect(() async => true);
      // After success, retryCount resets to 0
      expect(service.retryCount, 0);
      expect(service.isReconnecting, false);
    });

    test('reset clears state', () {
      service.reset();
      expect(service.retryCount, 0);
      expect(service.isReconnecting, false);
    });

    test('scheduleReconnect returns true on success', () async {
      final result = await service.scheduleReconnect(() async => true);
      expect(result, true);
    });

    test('scheduleReconnect returns false on failure', () async {
      final result = await service.scheduleReconnect(() async => false);
      expect(result, false);
    });
  });
}
