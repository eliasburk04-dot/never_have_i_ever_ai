import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Pill-shaped escalation indicator with colour-coded glow.
///
/// As escalation increases, the badge subtly glows brighter.
class ToneBadge extends StatelessWidget {
  const ToneBadge({super.key, required this.toneLabel});

  final String toneLabel;

  Color get _color {
    switch (toneLabel.toLowerCase()) {
      case 'safe':
        return AppColors.toneSafe;
      case 'deeper':
        return AppColors.toneDeeper;
      case 'secretive':
        return AppColors.toneSecretive;
      case 'freaky':
        return AppColors.toneFreaky;
      default:
        return AppColors.toneSafe;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: _color.withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        toneLabel.toUpperCase(),
        style: AppTypography.overline.copyWith(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
