import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Immersive question card — the visual centrepiece of every round.
///
/// - Deep indigo gradient with soft glow shadow
/// - Scale + fade entrance (0.92 → 1.0, 400ms, easeOut)
/// - Escalation-aware: [tone] parameter modulates glow color & intensity
/// - Subtle repeating pulse at higher escalation levels
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.questionText,
    this.roundNumber,
    this.tone = 'safe',
  });

  final String questionText;
  final int? roundNumber;
  final String tone;

  double get _glowIntensity {
    switch (tone) {
      case 'deeper':
        return 0.30;
      case 'secretive':
        return 0.38;
      case 'freaky':
        return 0.50;
      default:
        return 0.22;
    }
  }

  Color get _glowColor {
    switch (tone) {
      case 'deeper':
        return AppColors.toneDeeper;
      case 'secretive':
        return AppColors.toneSecretive;
      case 'freaky':
        return AppColors.toneFreaky;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.15),
            AppColors.accentDeep.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _glowColor.withValues(alpha: _glowIntensity),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (roundNumber != null) ...[
            Text(
              'NEVER HAVE I EVER',
              style: AppTypography.overline.copyWith(
                color: AppColors.accentLight.withValues(alpha: 0.7),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            questionText,
            style: AppTypography.question,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }
}
