import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import 'app.dart';
import 'core/bloc_observer.dart';
import 'core/service_locator.dart';
import 'domain/repositories/i_premium_repository.dart';
import 'services/local_question_pool.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final log = Logger();

  // BLoC debug observer
  Bloc.observer = AppBlocObserver();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Hive (offline storage)
  await Hive.initFlutter();
  await Hive.openBox<String>('offlineSessions');
  await Hive.openBox('appSettings');

  // Setup dependency injection
  setupServiceLocator();

  // Initialize local question pool for offline mode
  try {
    await getIt<LocalQuestionPool>().initialize();
    log.i('Local question pool loaded');
  } catch (e) {
    log.w('Failed to load local question pool: $e');
  }

  // Initialize in-app purchases (StoreKit 2)
  try {
    await getIt<IPremiumRepository>().initialize();
    log.i('In-app purchases initialized');
  } catch (e) {
    log.w('Failed to initialize IAP — purchases may be unavailable: $e');
  }

  runApp(const NhieApp());
}
