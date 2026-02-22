import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/offline_game_cubit.dart';

class OfflineResultsScreen extends StatelessWidget {
  const OfflineResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<OfflineGameCubit, OfflineGameState>(
          builder: (context, state) {
            final session = state.session;
            if (session == null) {
              return Center(
                child: Text(l10n.noGameData,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary)),
              );
            }

            final rounds = session.rounds;

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.gameOver, style: AppTypography.display)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(l10n.roundsCount(rounds.length),
                            style: AppTypography.label
                                .copyWith(color: AppColors.accent)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('·',
                          style: AppTypography.body
                              .copyWith(color: AppColors.textTertiary)),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.playersCount(session.playerCount),
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Round summary
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
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'R${index + 1}',
                                      style: AppTypography.label.copyWith(
                                          color: AppColors.accent),
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
                                  if (round.recycled)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.06),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: const Text('🔄',
                                          style: TextStyle(fontSize: 10)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: havePercent.clamp(1, 99),
                                      child: Container(
                                        height: 6,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    Expanded(
                                      flex: (100 - havePercent).clamp(1, 99),
                                      child: Container(
                                        height: 6,
                                        color: AppColors.iHaveNot,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '✋ $havePercent%',
                                    style: AppTypography.bodySmall
                                        .copyWith(color: AppColors.accent),
                                  ),
                                  Text(
                                    '🙅 ${100 - havePercent}%',
                                    style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textTertiary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (index * 60).ms, duration: 300.ms)
                            .slideX(begin: -0.03);
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Play Again
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: l10n.playAgain,
                      onPressed: () => context.go('/offline/setup'),
                      icon: Icons.replay_rounded,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: l10n.backToHome,
                      isPrimary: false,
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
