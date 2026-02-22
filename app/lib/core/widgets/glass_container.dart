import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius,
    this.borderWidth = 1.0,
    this.intensity = 1.0,
    this.color,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final double borderWidth;
  
  /// Controls how opaque the glass is (1.0 = normal glass, 0.0 = completely transparent)
  final double intensity;
  
  /// Optional base color for the glass tint. Defaults to AppColors.glassSurface
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final defaultRadius = BorderRadius.circular(AppSpacing.radiusXl);
    final effectiveRadius = borderRadius ?? defaultRadius;
    final baseColor = color ?? AppColors.glassSurface;
    
    // Calculate effective opacity based on intensity
    final effectiveColor = baseColor.withValues(
      alpha: (baseColor.a * intensity).clamp(0.0, 1.0),
    );

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: effectiveRadius,
            border: Border.all(
              color: AppColors.glassBorder.withValues(
                alpha: (AppColors.glassBorder.a * intensity).clamp(0.0, 1.0),
              ),
              width: borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
