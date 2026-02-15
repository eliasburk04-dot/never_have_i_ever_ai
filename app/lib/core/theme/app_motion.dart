/// Motion constants for the entire app.
///
/// Every animation in the product references these values.
/// Do NOT use magic numbers elsewhere.
class AppMotion {
  AppMotion._();

  // ── Press Effect ──────────────────────────────────────
  /// Scale on tap-down (1.0 → this value).
  static const double pressScale = 0.96;

  /// Duration of press-down animation.
  static const Duration pressDuration = Duration(milliseconds: 100);

  /// Duration of release spring-back.
  static const Duration releaseDuration = Duration(milliseconds: 180);

  // ── Page Transitions ──────────────────────────────────
  /// Default page transition duration.
  static const Duration pageTransition = Duration(milliseconds: 350);

  /// Reverse page transition.
  static const Duration pageTransitionReverse = Duration(milliseconds: 300);

  // ── Micro-animations ──────────────────────────────────
  /// Fade-in for staggered list items.
  static const Duration staggerDelay = Duration(milliseconds: 60);

  /// Standard fade-in.
  static const Duration fadeIn = Duration(milliseconds: 300);

  /// Question card entrance.
  static const Duration cardEntrance = Duration(milliseconds: 400);

  /// Scale entrance for question card.
  static const double cardEntranceScale = 0.92;

  /// Loading shimmer cycle.
  static const Duration shimmerCycle = Duration(milliseconds: 1500);

  // ── Escalation ────────────────────────────────────────
  /// Background ambient shift duration.
  static const Duration escalationShift = Duration(milliseconds: 800);

  /// Card glow pulse duration per cycle.
  static const Duration glowPulse = Duration(milliseconds: 2000);

  // ── Spring/Elastic ────────────────────────────────────
  /// Splash emoji & celebration scale.
  static const Duration elasticEntrance = Duration(milliseconds: 600);
}
