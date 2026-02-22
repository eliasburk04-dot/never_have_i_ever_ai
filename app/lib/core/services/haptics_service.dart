import 'package:haptic_feedback/haptic_feedback.dart';

/// Centralized service for managing device vibrations/haptics.
class HapticsService {
  HapticsService._();
  
  static final HapticsService instance = HapticsService._();
  
  bool _isEnabled = true;
  
  bool get isEnabled => _isEnabled;
  
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }
  
  /// Standard light tap for buttons
  Future<void> lightImpact() async {
    if (!_isEnabled) return;
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate) {
      await Haptics.vibrate(HapticsType.light);
    }
  }
  
  /// Medium impact for more significant actions (like swiping a card)
  Future<void> mediumImpact() async {
    if (!_isEnabled) return;
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate) {
      await Haptics.vibrate(HapticsType.medium);
    }
  }
  
  /// Heavy impact for destructive actions or major errors
  Future<void> heavyImpact() async {
    if (!_isEnabled) return;
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate) {
      await Haptics.vibrate(HapticsType.heavy);
    }
  }
  
  /// Success vibration
  Future<void> success() async {
    if (!_isEnabled) return;
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate) {
      await Haptics.vibrate(HapticsType.success);
    }
  }
  
  /// Error vibration
  Future<void> error() async {
    if (!_isEnabled) return;
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate) {
      await Haptics.vibrate(HapticsType.error);
    }
  }
  
  /// Warning vibration
  Future<void> warning() async {
    if (!_isEnabled) return;
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate) {
      await Haptics.vibrate(HapticsType.warning);
    }
  }
}
