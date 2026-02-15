import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'pressable.dart';

/// Primary elevated button with glow, press scale, and dark surface.
///
/// States: Default → Pressed (scale 0.96, glow dim) → Disabled (0.4 opacity) → Loading
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: isLoading ? null : onPressed,
      disabled: isLoading || onPressed == null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 56,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.border, width: 1.5),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.glowAccent(0.25),
                    blurRadius: AppSpacing.glowBlur,
                    spreadRadius: AppSpacing.glowSpread,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 20,
                        color: isPrimary
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      label,
                      style: AppTypography.button.copyWith(
                        color: isPrimary
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The big "I Have" / "I Have Not" answer buttons — game-critical.
///
/// Deep indigo for "I Have", dark surface for "I Have Not".
/// Selected state gains glow ring. Press scale via [Pressable].
class AnswerButton extends StatelessWidget {
  const AnswerButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.isHave,
    this.isDisabled = false,
    this.isSelected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isHave;
  final bool isDisabled;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final bgColor = isHave ? AppColors.iHave : AppColors.iHaveNot;
    final textColor = isHave ? AppColors.iHaveText : AppColors.iHaveNotText;
    final borderColor =
        isSelected ? AppColors.accentLight : AppColors.border;

    return Expanded(
      child: Pressable(
        onPressed: isDisabled ? null : onPressed,
        disabled: isDisabled,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 72,
          decoration: BoxDecoration(
            color: isDisabled ? bgColor.withValues(alpha: 0.3) : bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.glowAccent(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.button.copyWith(color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}
