import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography system — Inter for UI, Space Mono for codes.
///
/// Optimised for German long-string support (soft-wrap friendly sizes).
/// All line heights are explicitly set for vertical rhythm on an 8pt grid.
class AppTypography {
  AppTypography._();

  static TextStyle get _base => GoogleFonts.outfit();

  // ── Display — Splash / Hero ────────────────────────────
  static TextStyle get display => _base.copyWith(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.1,
        letterSpacing: -1.0,
      );

  // ── Headings ───────────────────────────────────────────
  static TextStyle get h1 => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.25,
        letterSpacing: -0.3,
      );

  static TextStyle get h3 => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // ── Question (dominates the game screen) ───────────────
  static TextStyle get question => _base.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.35,
        letterSpacing: -0.2,
      );

  // ── Body ───────────────────────────────────────────────
  static TextStyle get body => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w300,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        color: AppColors.textSecondary,
        height: 1.45,
      );

  // ── Buttons ────────────────────────────────────────────
  static TextStyle get button => _base.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.2,
      );

  static TextStyle get buttonSmall => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.2,
      );

  // ── Lobby code (monospace for readability) ─────────────
  static TextStyle get lobbyCode => GoogleFonts.spaceMono(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: 6.0,
        color: AppColors.accent,
      );

  // ── Labels / Overlines ─────────────────────────────────
  static TextStyle get label => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
        height: 1.4,
      );

  static TextStyle get overline => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
        letterSpacing: 2.0,
        height: 1.4,
      );

  // ── Emoji (large decorative) ───────────────────────────
  static TextStyle get emoji => _base.copyWith(
        fontSize: 56,
      );
}
