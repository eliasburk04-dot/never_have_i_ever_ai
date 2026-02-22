import 'package:flutter/material.dart';

/// Premium dark-mode-first color system.
///
/// Layers (back → front): background → backgroundElevated → surface → surfaceElevated
/// Accent: Deep indigo continuum with escalation intensity support.
/// Glow: Used only on interactive surfaces and escalation feedback.
class AppColors {
  AppColors._();

  // ── Background Layers ──────────────────────────────────
  static const background = Color(0xFF000000); // Pure stark black
  static const backgroundElevated = Color(0xFF09090B); // Very dark gray
  static const surface = Color(0xFF18181B); // Brutalist gray surface
  static const surfaceElevated = Color(0xFF27272A); // Lighter gray structure
  
  // ── Glass Surfaces ─────────────────────────────────────
  static const glassSurface = Color(0x18FFFFFF); // slightly milkier raw glass
  static const glassBorder = Color(0x33FFFFFF); // harsher structural borders

  // ── Accent System ──────────────────────────────────────
  // ── Accent System ──────────────────────────────────────
  // Brutalism emphasizes stark high-contrast forms rather than colorful hues.
  // Using pure whites and industrial silvers.
  static const primary = Color(0xFFE4E4E7);
  static const primaryLight = Color(0xFFFFFFFF);
  static const accent = Color(0xFFFAFAFA);
  static const accentLight = Color(0xFFFFFFFF);
  static const accentDeep = Color(0xFFA1A1AA);
  
  // Premium Gold is replaced by an Industrial Chrome/Titanium
  static const secondary = Color(0xFFD4D4D8);
  static const secondaryMuted = Color(0xFF52525B);
  
  // ── Premium Gold ───────────────────────────────────────
  static const premiumGold = Color(0xFFFFD700);

  // ── Text ───────────────────────────────────────────────
  static const textPrimary = Color(0xFFFFFFFF); // High-contrast white
  static const textSecondary = Color(0xFFA1A1AA); // Industrial gray
  static const textTertiary = Color(0xFF71717A); // Deep gray

  // ── Semantic ───────────────────────────────────────────
  static const error = Color(0xFFF87171);
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);

  // ── Dividers / Borders ─────────────────────────────────
  // ── Dividers / Borders ─────────────────────────────────
  static const divider = Color(0x44FFFFFF);
  static const border = Color(0x66FFFFFF); // Sharper borders

  // ── Tone Escalation (Stark Industrial Tones) ───────────
  // Instead of playful vibrant colors, we use raw warning colors:
  static const toneSafe = Color(0xFFA1A1AA);      // Gray/Silver
  static const toneDeeper = Color(0xFFEAB308);    // Raw caution yellow
  static const toneSecretive = Color(0xFF7C3AED); // High voltage purple (or solid sharp white)
  static const toneFreaky = Color(0xFFDC2626);    // Danger red

  // ── Answer Buttons ─────────────────────────────────────
  // ── Answer Buttons ─────────────────────────────────────
  // Stark brutalist contrast for answers.
  static const iHave = Color(0xFF000000);        // Black core
  static const iHavePressed = Color(0xFF27272A); 
  static const iHaveNot = Color(0xFFFFFFFF);     // White core
  static const iHaveNotPressed = Color(0xFFE4E4E7); 
  static const iHaveText = Color(0xFFFFFFFF);    // White text on black
  static const iHaveNotText = Color(0xFF000000); // Black text on white
  static const iHaveGlow = Color(0x33FFFFFF);    
  static const iHaveNotGlow = Color(0x00000000); 
  static const iHaveBorder = Color(0xFFFFFFFF);  // Hard white border
  static const iHaveNotBorder = Color(0xFF000000); // Hard black border

  // ── Player Status Row Backgrounds ──────────────────────
  static const playerRowHave = Color(0xFF18181B); // Dark gray
  static const playerRowHaveNot = Color(0xFF27272A); // Lighter gray

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
        return const Color(0xFF0A0800); // faint yellow tint
      case 'secretive':
        return const Color(0xFF070010); // faint purple tint
      case 'freaky':
        return const Color(0xFF0A0000); // very faint red tint
      default:
        return const Color(0xFF000000); // Absolute black
    }
  }

  // ── Misc ───────────────────────────────────────────────
  static const overlay = Color(0xCC000000);
  static const shimmer = Color(0xFF2A2A40);
}
