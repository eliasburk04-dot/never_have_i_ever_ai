import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/game_setup_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/game_setup_chips.dart';
import '../../../domain/entities/offline_player.dart';
import '../../../features/premium/cubit/premium_cubit.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/game_config_cubit.dart';
import '../cubit/offline_game_cubit.dart';

class OfflineSetupScreen extends StatefulWidget {
  const OfflineSetupScreen({super.key});

  @override
  State<OfflineSetupScreen> createState() => _OfflineSetupScreenState();
}

class _OfflineSetupScreenState extends State<OfflineSetupScreen> {
  int _playerCount = AppConstants.minPlayers;

  @override
  void initState() {
    super.initState();
    _playerCount = context.read<GameConfigCubit>().state.players.length;
    if (_playerCount < AppConstants.minPlayers) {
      _playerCount = AppConstants.minPlayers;
    }
  }

  int _getMaxPlayersLimit(BuildContext context) {
    final isPremium = context.read<PremiumCubit>().state.isPremium;
    return isPremium ? AppConstants.maxPlayers : 5;
  }

  void _incrementPlayers() {
    final limit = _getMaxPlayersLimit(context);
    if (_playerCount >= limit) {
      if (!context.read<PremiumCubit>().state.isPremium) {
        context.push('/premium');
      }
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _playerCount++);
  }

  void _decrementPlayers() {
    if (_playerCount <= AppConstants.minPlayers) return;
    HapticFeedback.lightImpact();
    setState(() => _playerCount--);
  }

  void _startGame() {
    final configCubit = context.read<GameConfigCubit>();
    final config = configCubit.state;
    final isPremium = context.read<PremiumCubit>().state.isPremium;

    if (!GameSetupConfig.canStartGame(
      categories: config.categories,
      selectedPackId: config.selectedPackId,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one category or creator pack.'),
        ),
      );
      return;
    }

    final players = List.generate(
      _playerCount,
      (i) => OfflinePlayer(name: 'Player ${i + 1}', emoji: '👤'),
    );

    configCubit.setPlayers(players);

    context.read<OfflineGameCubit>().startGame(
      players: players,
      maxRounds: config.maxRounds,
      language: config.language,
      nsfwEnabled: config.nsfwEnabled,
      isPremium: isPremium,
      categories: config.categories,
      selectedPackId: config.selectedPackId,
    );

    context.go('/offline/game');
  }

  void _togglePremiumFeature({
    required bool isPremium,
    required bool value,
    required ValueChanged<bool> onPremiumChanged,
  }) {
    if (!isPremium && value) {
      context.push('/premium');
      return;
    }
    onPremiumChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = context.watch<GameConfigCubit>().state;
    final isPremium = context.watch<PremiumCubit>().state.isPremium;
    final maxRoundsLimit = isPremium
        ? AppConstants.maxRoundsPremium
        : AppConstants.maxRoundsFree;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Setup',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.players,
                            style: AppTypography.overline.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs + 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.playerCount,
                                      style: AppTypography.label,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      isPremium
                                          ? l10n.upToPlayers(
                                              AppConstants.maxPlayers,
                                            )
                                          : l10n.upToPlayersFree(5),
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: _decrementPlayers,
                                      icon: const Icon(
                                        Icons.remove_circle_outline_rounded,
                                      ),
                                      color: AppColors.textTertiary,
                                    ),
                                    SizedBox(
                                      width: 36,
                                      child: Text(
                                        '$_playerCount',
                                        style: AppTypography.h3.copyWith(
                                          color: AppColors.accent,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _incrementPlayers,
                                      icon: const Icon(
                                        Icons.add_circle_outline_rounded,
                                      ),
                                      color: AppColors.accent,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Divider(color: AppColors.divider),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.rounds,
                            style: AppTypography.overline.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.roundsCount(config.maxRounds),
                                style: AppTypography.body,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  '${config.maxRounds}',
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.accent,
                              inactiveTrackColor: AppColors.surface,
                              thumbColor: AppColors.accent,
                              overlayColor: AppColors.accent.withValues(
                                alpha: 0.12,
                              ),
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 10,
                                elevation: 4,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 20,
                              ),
                            ),
                            child: Slider(
                              value: config.maxRounds.toDouble(),
                              min: AppConstants.minRounds.toDouble(),
                              max: maxRoundsLimit.toDouble(),
                              onChanged: (v) {
                                final rounded = (v / 5).round() * 5;
                                context.read<GameConfigCubit>().setMaxRounds(
                                  rounded.clamp(
                                    AppConstants.minRounds,
                                    maxRoundsLimit,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.categoriesLabel,
                            style: AppTypography.overline.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          CategoryGrid(
                            selectedCategories: config.categories,
                            isPremium: isPremium,
                            onCategoryToggled: (category) {
                              final current = List<String>.from(
                                config.categories,
                              );
                              if (current.contains(category)) {
                                current.remove(category);
                              } else {
                                current.add(category);
                              }
                              context.read<GameConfigCubit>().setCategories(
                                current,
                              );
                            },
                            onPremiumLockedTapped: () =>
                                context.push('/premium'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'CREATOR PACKS',
                            style: AppTypography.overline.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          CreatorPackGrid(
                            selectedPackId: config.selectedPackId,
                            isPremium: isPremium,
                            onPackSelected: (packId) {
                              context
                                  .read<GameConfigCubit>()
                                  .toggleSelectedPackId(packId);
                            },
                            onPremiumLockedTapped: () =>
                                context.push('/premium'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            l10n.premiumRules,
                            style: AppTypography.overline.copyWith(
                              color: AppColors.premiumGold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      l10n.nsfwMode,
                                      style: AppTypography.label,
                                    ),
                                    if (!isPremium) ...[
                                      const SizedBox(width: AppSpacing.xs),
                                      Icon(
                                        Icons.lock_rounded,
                                        size: 14,
                                        color: AppColors.textTertiary,
                                      ),
                                    ],
                                  ],
                                ),
                                Switch(
                                  value: config.nsfwEnabled,
                                  activeTrackColor: AppColors.secondary,
                                  onChanged: (v) => _togglePremiumFeature(
                                    isPremium: isPremium,
                                    value: v,
                                    onPremiumChanged: (enabled) => context
                                        .read<GameConfigCubit>()
                                        .setNsfwEnabled(enabled),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: l10n.startGame,
                    onPressed: _startGame,
                    isPrimary: true,
                    icon: Icons.play_arrow_rounded,
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
