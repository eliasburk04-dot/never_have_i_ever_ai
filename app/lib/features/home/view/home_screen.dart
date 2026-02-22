import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/animated_mesh_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/app_localizations.dart';
import '../../offline/cubit/offline_game_cubit.dart';
import '../../premium/cubit/premium_cubit.dart';

/// Home screen — dark immersive hub with ambient glow behind title.
///
/// Hierarchy: Title group (centred) → 3 action buttons (bottom third).
/// Premium & Settings icons top-right, subtle opacity.
/// All buttons use [Pressable] for tactile feedback.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── 1. Dynamic Background ──────────────────────────
          const Positioned.fill(
            child: AnimatedMeshBackground(
              colors: [
                AppColors.accentDeep,
                AppColors.primary,
                AppColors.backgroundElevated,
                AppColors.secondaryMuted,
              ],
              speed: 0.8,
            ),
          ),

          // ── 2. Content ──────────────────────────────────────
          SafeArea(
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
                        // Top bar — settings & premium (Glass surface)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GlassContainer(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              borderRadius: BorderRadius.circular(30),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  BlocBuilder<PremiumCubit, PremiumState>(
                                    builder: (context, state) {
                                      final isPremium = state.isPremium;
                                      return Pressable(
                                        onPressed: () =>
                                            context.push('/premium'),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isPremium
                                                ? AppColors.premiumGold
                                                      .withValues(alpha: 0.15)
                                                : Colors.transparent,
                                            shape: BoxShape.circle,
                                            boxShadow: isPremium
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.premiumGold
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      blurRadius: 16,
                                                      spreadRadius: 2,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Icon(
                                            Icons.star_rounded,
                                            color: isPremium
                                                ? AppColors.premiumGold
                                                : AppColors.textPrimary,
                                            size: 22,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Pressable(
                                    onPressed: () => context.push('/settings'),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        color: Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.settings_rounded,
                                        color: AppColors.textPrimary,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Ambient glow + title
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xl,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.accent.withValues(alpha: 0.08),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                        'Never Have\nI Ever',
                                        style: AppTypography.display,
                                        textAlign: TextAlign.center,
                                      )
                                      .animate()
                                      .fadeIn(duration: 500.ms)
                                      .slideY(
                                        begin: 0.08,
                                        curve: Curves.easeOutCubic,
                                      ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    l10n.appSubtitle,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ).animate().fadeIn(
                                    delay: 200.ms,
                                    duration: 400.ms,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Action buttons — frosted container
                        GlassContainer(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          width: double.infinity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppButton(
                                    label: l10n.playOffline,
                                    onPressed: () =>
                                        context.push('/offline/setup'),
                                    isPrimary:
                                        true, // Make Offline the vibrant primary action
                                    icon: Icons.wifi_off_rounded,
                                  )
                                  .animate()
                                  .fadeIn(delay: 300.ms, duration: 350.ms)
                                  .slideY(begin: 0.12),
                              const SizedBox(height: AppSpacing.md),
                              AppButton(
                                    label: l10n.createLobby,
                                    onPressed: () =>
                                        context.push('/lobby/create'),
                                    isPrimary: false,
                                    icon: Icons.add_rounded,
                                  )
                                  .animate()
                                  .fadeIn(delay: 380.ms, duration: 350.ms)
                                  .slideY(begin: 0.12),
                              const SizedBox(height: AppSpacing.md),
                              AppButton(
                                    label: l10n.joinLobby,
                                    onPressed: () =>
                                        context.push('/lobby/join'),
                                    isPrimary: false,
                                    icon: Icons.login_rounded,
                                  )
                                  .animate()
                                  .fadeIn(delay: 460.ms, duration: 350.ms)
                                  .slideY(begin: 0.12),

                              // Resume banner
                              Builder(
                                builder: (context) {
                                  final activeId = context
                                      .read<OfflineGameCubit>()
                                      .activeSessionId;
                                  if (activeId == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.md,
                                    ),
                                    child:
                                        Pressable(
                                          onPressed: () async {
                                            final cubit = context
                                                .read<OfflineGameCubit>();
                                            final resumed = await cubit
                                                .resumeSession(activeId);
                                            if (resumed && context.mounted) {
                                              context.go('/offline/game');
                                            }
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(
                                              AppSpacing.md,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accent
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppSpacing.radiusMd,
                                                  ),
                                              border: Border.all(
                                                color: AppColors.accent
                                                    .withValues(alpha: 0.2),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.play_arrow_rounded,
                                                  color: AppColors.accentLight,
                                                  size: 20,
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.xs,
                                                ),
                                                Text(
                                                  l10n.resumeOfflineGame,
                                                  style: AppTypography
                                                      .buttonSmall
                                                      .copyWith(
                                                        color: AppColors
                                                            .accentLight,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ).animate().fadeIn(
                                          delay: 540.ms,
                                          duration: 350.ms,
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
