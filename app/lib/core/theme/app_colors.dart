import 'package:flutter/material.dart';

/// Premium dark-mode-first color system.
///
/// Layers (back → front): background → backgroundElevated → surface → surfaceElevated
/// Accent: Deep indigo continuum with escalation intensity support.
/// Glow: Used only on interactive surfaces and escalation feedback.
class AppColors {
  AppColors._();

  // ── Background Layers ──────────────────────────────────
  static const background = Color(0xFF0B0B14);
  static const backgroundElevated = Color(0xFF12121E);
  static const surface = Color(0xFF1A1A2E);
  static const surfaceElevated = Color(0xFF22223A);

  // ── Accent System ──────────────────────────────────────
  static const primary = Color(0xFF6366F1);
  static const primaryLight = Color(0xFF818CF8);
  static const accent = Color(0xFF6366F1);
  static const accentLight = Color(0xFF818CF8);
  static const accentDeep = Color(0xFF4338CA);
  static const secondary = Color(0xFFF59E0B);
  static const secondaryMuted = Color(0xFF78560A);

  // ── Text ───────────────────────────────────────────────
  static const textPrimary = Color(0xFFF1F1F6);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textTertiary = Color(0xFF6B7280);

  // ── Semantic ───────────────────────────────────────────
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);

  // ── Dividers / Borders ─────────────────────────────────
  static const divider = Color(0xFF2A2A40);
  static const border = Color(0xFF353550);

  // ── Tone Escalation ────────────────────────────────────
  static const toneSafe = Color(0xFF22C55E);
  static const toneDeeper = Color(0xFFFBBF24);
  static const toneSecretive = Color(0xFFF97316);
  static const toneFreaky = Color(0xFFEF4444);

  // ── Answer Buttons ─────────────────────────────────────
  static const iHave = Color(0xFF166534);        // deep green
  static const iHavePressed = Color(0xFF14532D); // pressed green
  static const iHaveNot = Color(0xFF7F1D1D);     // deep red
  static const iHaveNotPressed = Color(0xFF991B1B); // pressed red
  static const iHaveText = Color(0xFFFFFFFF);
  static const iHaveNotText = Color(0xFFFFFFFF);
  static const iHaveGlow = Color(0xFF22C55E);    // green glow
  static const iHaveNotGlow = Color(0xFFEF4444); // red glow
  static const iHaveBorder = Color(0xFF22C55E);
  static const iHaveNotBorder = Color(0xFFEF4444);

  // ── Player Status Row Backgrounds ──────────────────────
  static const playerRowHave = Color(0xFF0D2818);
  static const playerRowHaveNot = Color(0xFF2A0D0D);

  // ── Glow helpers ───────────────────────────────────────
  static Color glowAccent([double opacity = 0.25]) =>
      accent.withValues(alpha: opacity);

  static Color glowTone(String tone, [double opacity = 0.2]) {
    switch (tone) {
      case 'deeper':
        return toneDeeper.withValues(alpha: opacity);
      case 'secretive':
        return toneSecretive.withValues(alpha: opacity);
      case 'freaky':
        return toneFreaky.withValues(alpha: opacity);
      default:
        return toneSafe.withValues(alpha: opacity);
    }
  }

  // ── Escalation Background Tints ────────────────────────
  static Color escalationBackground(String tone) {
    switch (tone) {
      case 'deeper':
        return const Color(0xFF0F0D18);
      case 'secretive':
        return const Color(0xFF120D15);
      case 'freaky':
        return const Color(0xFF150D12);
      default:
        return background;
    }
  }

  // ── Misc ───────────────────────────────────────────────
  static const overlay = Color(0xCC000000);
  static const shimmer = Color(0xFF2A2A40);
}
