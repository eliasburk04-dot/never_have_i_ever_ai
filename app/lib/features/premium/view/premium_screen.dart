import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../cubit/premium_cubit.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Premium',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: BlocBuilder<PremiumCubit, PremiumState>(
          builder: (context, state) {
            if (state.isPremium) {
              return _buildAlreadyPremium(context);
            }
            return _buildUpgradeCTA(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildAlreadyPremium(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gold glow icon
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  blurRadius: 32,
                ),
              ],
            ),
            child: const Icon(Icons.star_rounded,
                color: AppColors.secondary, size: 48),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('You\'re Premium',
              style: AppTypography.display
                  .copyWith(color: AppColors.secondary)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enjoy unlimited AI rounds,\nlonger games & ad-free play.',
            style:
                AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeCTA(BuildContext context, PremiumState state) {
    return BlocListener<PremiumCubit, PremiumState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - AppSpacing.lg * 2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top content
                  Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),

                      // Premium icon with gold glow
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              AppColors.secondary.withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary
                                  .withValues(alpha: 0.2),
                              blurRadius: 32,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.star_rounded,
                            color: AppColors.secondary, size: 48),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.7, 0.7),
                            end: const Offset(1, 1),
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Go Premium', style: AppTypography.display)
                          .animate()
                          .fadeIn(delay: 200.ms),
                      const SizedBox(height: AppSpacing.xl),

                      // Feature list — glass card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            _FeatureRow(
                                icon: Icons.all_inclusive,
                                text: 'Unlimited AI rounds'),
                            _FeatureRow(
                                icon: Icons.timer,
                                text: 'Up to 100 rounds per game'),
                            _FeatureRow(
                                icon: Icons.auto_awesome,
                                text: 'Priority AI generation'),
                            _FeatureRow(
                                icon: Icons.block,
                                text: 'Ad-free experience'),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                      const SizedBox(height: AppSpacing.xl),

                      // Price
                      Text(
                        state.priceString,
                        style: AppTypography.display.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Lifetime · One-time purchase',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textTertiary)),
                    ],
                  ),

                  // Bottom CTA
                  Column(
                    children: [
                      const SizedBox(height: AppSpacing.xl),

                      if (state.errorMessage != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            state.errorMessage!,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Purchase button — gold accent
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: state.isLoading
                              ? null
                              : () =>
                                  context.read<PremiumCubit>().purchase(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull),
                            ),
                            elevation: 0,
                          ),
                          child: state.isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color:
                                        Colors.black.withValues(alpha: 0.6),
                                  ),
                                )
                              : Text('Purchase Premium',
                                  style: AppTypography.button
                                      .copyWith(color: Colors.black)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: () =>
                            context.read<PremiumCubit>().restore(),
                        child: Text(
                          'Restore Purchases',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(text, style: AppTypography.body),
        ],
      ),
    );
  }
}
