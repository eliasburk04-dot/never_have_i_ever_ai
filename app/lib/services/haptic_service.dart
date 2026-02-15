import 'package:flutter/services.dart';

/// Centralized haptic feedback for game interactions.
class HapticService {
  HapticService._();

  /// Light tap — button presses, navigation.
  static void lightTap() => HapticFeedback.lightImpact();

  /// Medium impact — answer submitted.
  static void answerSubmitted() => HapticFeedback.mediumImpact();

  /// Heavy impact — round complete, game events.
  static void heavyImpact() => HapticFeedback.heavyImpact();

  /// Selection tick — slider, toggle.
  static void selectionTick() => HapticFeedback.selectionClick();

  /// Success vibration — lobby created, game started.
  static void success() => HapticFeedback.mediumImpact();

  /// Error vibration — failed action.
  static void error() => HapticFeedback.heavyImpact();

  /// Notify — new player joined, new round.
  static void notify() => HapticFeedback.lightImpact();
}
