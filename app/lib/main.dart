import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import 'app.dart';
import 'core/bloc_observer.dart';
import 'core/service_locator.dart';
import 'core/services/native_iap_service.dart';
import 'domain/repositories/i_premium_repository.dart';
import 'services/local_question_pool.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final log = Logger();

  // BLoC debug observer
  Bloc.observer = AppBlocObserver();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Setup dependency injection
  setupServiceLocator();

  // Initialize native IAP service (timeout so simulator doesn't block launch)
  await NativeIapService.instance.initialize().timeout(
    const Duration(seconds: 5),
    onTimeout: () {
      log.w('IAP initialization timed out — store may be unavailable');
    },
  );

  // Keep startup non-blocking so iOS never sits on a white launch screen.
  await _initializeStorage(log);

  runApp(const NhieApp());

  unawaited(_initializePostLaunchServices(log));
}

Future<void> _initializeStorage(Logger log) async {
  try {
    await Hive.initFlutter().timeout(const Duration(seconds: 8));
    await Hive.openBox<String>(
      'offlineSessions',
    ).timeout(const Duration(seconds: 8));
    await Hive.openBox('appSettings').timeout(const Duration(seconds: 8));
  } catch (e) {
    log.w('Storage initialization degraded mode: $e');
  }
}

Future<void> _initializePostLaunchServices(Logger log) async {
  // Initialize local question pool for offline mode
  try {
    await getIt<LocalQuestionPool>().initialize().timeout(
      const Duration(seconds: 8),
    );
    log.i('Local question pool loaded');
  } catch (e) {
    log.w('Failed to load local question pool: $e');
  }

  // Initialize in-app purchases (StoreKit 2)
  try {
    await getIt<IPremiumRepository>().initialize().timeout(
      const Duration(seconds: 8),
    );
    log.i('In-app purchases initialized');
  } catch (e) {
    log.w('Failed to initialize IAP — purchases may be unavailable: $e');
  }
}
