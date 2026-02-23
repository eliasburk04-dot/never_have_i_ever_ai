import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_mesh_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/premium_cubit.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(AppLocalizations.of(context)!.premiumLabel,
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
      ),
      body: Stack(
        children: [
          // 1. Dynamic gold mesh background
          const Positioned.fill(
            child: AnimatedMeshBackground(
              colors: [
                AppColors.backgroundElevated,
                Color(0xFF27272A), // Zinc 800 - industrial gray
                Color(0xFF18181B), // Zinc 900 - dark brutalist gray
                AppColors.background,
              ],
              speed: 0.5, // Slow, premium feeling
            ),
          ),

          // 2. Content
          SafeArea(
            child: BlocBuilder<PremiumCubit, PremiumState>(
              builder: (context, state) {
                if (state.isPremium) {
                  return _buildAlreadyPremium(context);
                }
                return _buildUpgradeCTA(context, state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyPremium(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glowing golden star
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.premiumGold.withValues(alpha: 0.25),
                  AppColors.premiumGold.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.premiumGold.withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.star_rounded,
                color: AppColors.premiumGold, size: 52),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.youArePremium,
              style: AppTypography.display
                  .copyWith(color: AppColors.premiumGold)),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.premiumEnjoy,
            style:
                AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeCTA(BuildContext context, PremiumState state) {
    final l10n = AppLocalizations.of(context)!;
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
                              AppColors.premiumGold.withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.premiumGold
                                  .withValues(alpha: 0.3),
                              blurRadius: 32,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.star_rounded,
                            color: AppColors.premiumGold, size: 48),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.7, 0.7),
                            end: const Offset(1, 1),
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(l10n.goPremium, style: AppTypography.display)
                          .animate()
                          .fadeIn(delay: 200.ms),
                      const SizedBox(height: AppSpacing.xl),

                      // Feature list — glass card
                      GlassContainer(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        color: AppColors.surface.withValues(alpha: 0.3),
                        child: Column(
                          children: [
                            const _FeatureRow(
                                icon: Icons.category_rounded,
                                textKey: 'allCategories'),
                            const _FeatureRow(
                                icon: Icons.all_inclusive,
                                textKey: 'unlimitedOfflineRounds'),
                            const _FeatureRow(
                                icon: Icons.timer,
                                textKey: 'upTo100Rounds'),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                      const SizedBox(height: AppSpacing.xl),

                      // Price
                      Text(
                        state.priceString,
                        style: AppTypography.display.copyWith(
                          color: AppColors.premiumGold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.lifetimeOneTime,
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
                            backgroundColor: AppColors.premiumGold,
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
                              : Text(l10n.purchasePremium,
                                  style: AppTypography.button.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                  )),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: () =>
                            context.read<PremiumCubit>().restore(),
                        child: Text(
                          l10n.restorePurchases,
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
  const _FeatureRow({required this.icon, required this.textKey});

  final IconData icon;
  final String textKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = switch (textKey) {
      'allCategories' => l10n.allCategories,
      'unlimitedOfflineRounds' => l10n.unlimitedOfflineRounds,
      'upTo100Rounds' => l10n.upTo100Rounds,
      _ => textKey,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.premiumGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.premiumGold, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(text, style: AppTypography.body),
        ],
      ),
    );
  }
}
