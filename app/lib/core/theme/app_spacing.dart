/// 8pt base spacing grid with vertical rhythm support.
class AppSpacing {
  AppSpacing._();

  // ── Core scale (multiples of 8) ────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // ── Border radius ──────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // ── Elevation shadows ──────────────────────────────────
  /// Level 1 — subtle cards on surface
  static const double shadowBlurSm = 8;
  static const double shadowOffsetSm = 2;

  /// Level 2 — floating elements
  static const double shadowBlurMd = 16;
  static const double shadowOffsetMd = 4;

  /// Level 3 — modals, overlays
  static const double shadowBlurLg = 32;
  static const double shadowOffsetLg = 8;

  /// Level 4 — glow (used with accent colors)
  static const double glowBlur = 24;
  static const double glowSpread = 2;
}
