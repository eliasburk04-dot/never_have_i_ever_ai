import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Centralized service for playing subtle UI sounds
class AudioService {
  AudioService._() {
    _init();
  }
  
  static final AudioService instance = AudioService._();
  
  final AudioPlayer _uiPlayer = AudioPlayer();
  
  bool _isMuted = false;
  
  bool get isMuted => _isMuted;
  
  void setMuted(bool muted) {
    _isMuted = muted;
  }

  void _init() {
    // Configure default audio player settings for UI sounds 
    // (low latency, background mixing if needed)
    _uiPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  /// Plays a subtle click/tap sound for buttons
  Future<void> playTap() async {
    if (_isMuted || kIsWeb) return;
    try {
      // In a real app, you would load an asset here. 
      // For now we'll just prepare the structure.
      // await _uiPlayer.play(AssetSource('audio/tap.mp3'));
    } catch (e) {
      debugPrint('Error playing tap sound: $e');
    }
  }

  /// Plays a swoosh or swipe sound for cards
  Future<void> playSwipe() async {
    if (_isMuted || kIsWeb) return;
    try {
      // await _uiPlayer.play(AssetSource('audio/swipe.mp3'));
    } catch (e) {
      debugPrint('Error playing swipe sound: $e');
    }
  }
  
  /// Plays a success or victory sound
  Future<void> playSuccess() async {
    if (_isMuted || kIsWeb) return;
    try {
      // await _uiPlayer.play(AssetSource('audio/success.mp3'));
    } catch (e) {
      debugPrint('Error playing success sound: $e');
    }
  }
}
