import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../bloc/game_bloc.dart';

/// Final Group Summary — cinematic dark results with staggered round cards.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.lobbyId});

  final String lobbyId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<GameBloc, GameState>(
          builder: (context, state) {
            final rounds = state.allRounds;

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Text('Game Over', style: AppTypography.display)
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.08),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${rounds.length} rounds played',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // Round summary list
                  Expanded(
                    child: ListView.separated(
                      itemCount: rounds.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final round = rounds[index];
                        final havePercent =
                            (round.haveRatio * 100).round();

                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusFull),
                                    ),
                                    child: Text(
                                      'R${index + 1}',
                                      style: AppTypography.overline
                                          .copyWith(color: AppColors.accent),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      round.questionText,
                                      style: AppTypography.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: round.haveRatio,
                                  backgroundColor: AppColors.iHaveNot,
                                  valueColor: const AlwaysStoppedAnimation(
                                      AppColors.accent),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '✋ $havePercent%  ·  🙅 ${100 - havePercent}%',
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (index * 60).ms)
                            .slideX(begin: -0.04);
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Back to Home',
                      onPressed: () => context.go('/home'),
                      icon: Icons.home_rounded,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
