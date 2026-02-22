import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/haptics_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'pressable.dart';
import 'glass_container.dart';

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
      onPressed: isLoading ? null : () {
        HapticsService.instance.lightImpact();
        AudioService.instance.playTap();
        if (onPressed != null) onPressed!();
      },
      disabled: isLoading || onPressed == null,
      child: GlassContainer(
        height: 56,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        color: isPrimary ? AppColors.accent : AppColors.surface.withValues(alpha: 0.6),
        borderWidth: isPrimary ? 0 : 1.5,
        intensity: isLoading || onPressed == null ? 0.4 : 1.0,
        child: Center(
          child: isLoading
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: isPrimary ? AppColors.background : Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 20,
                        color: isPrimary ? AppColors.background : Colors.white,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      label,
                      style: AppTypography.button.copyWith(
                        color: isPrimary ? AppColors.background : Colors.white,
                        fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
