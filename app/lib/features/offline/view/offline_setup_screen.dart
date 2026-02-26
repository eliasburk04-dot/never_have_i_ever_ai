import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
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
      isDrinkingGame: config.isDrinkingGame,
      customQuestions: const [],
      categories: config.categories,
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
                          _CategoryGrid(
                            selectedCategories: config.categories,
                            isPremium: isPremium,
                            onCategoryToggled: (category) {
                              final current = List<String>.from(
                                config.categories,
                              );
                              if (current.contains(category)) {
                                current.remove(category);
                                context.read<GameConfigCubit>().setCategories(
                                  current,
                                );
                              } else {
                                current.add(category);
                                context.read<GameConfigCubit>().setCategories(
                                  current,
                                );
                              }
                            },
                            onPremiumLockedTapped: () =>
                                context.push('/premium'),
                          ),
                          const SizedBox(height: AppSpacing.md),
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
                                      l10n.drinkingGameMode,
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
                                  value: config.isDrinkingGame,
                                  activeTrackColor: AppColors.secondary,
                                  onChanged: (v) => _togglePremiumFeature(
                                    isPremium: isPremium,
                                    value: v,
                                    onPremiumChanged: (enabled) => context
                                        .read<GameConfigCubit>()
                                        .setIsDrinkingGame(enabled),
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

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.selectedCategories,
    required this.isPremium,
    required this.onCategoryToggled,
    required this.onPremiumLockedTapped,
  });

  final List<String> selectedCategories;
  final bool isPremium;
  final ValueChanged<String> onCategoryToggled;
  final VoidCallback onPremiumLockedTapped;

  // Free vs Premium Categories
  static const _freeCategories = ['social', 'party', 'food', 'embarrassing'];
  static const _premiumCategories = [
    'relationships',
    'confessions',
    'risk',
    'moral_gray',
    'deep',
    'sexual',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String getL10nLabel(String cat) {
      return switch (cat) {
        'social' => l10n.catSocial,
        'party' => l10n.catParty,
        'food' => l10n.catFood,
        'embarrassing' => l10n.catEmbarrassing,
        'relationships' => l10n.catRelationships,
        'confessions' => l10n.catConfessions,
        'risk' => l10n.catRisk,
        'moral_gray' => l10n.catMoralGray,
        'deep' => l10n.catDeep,
        'sexual' => l10n.catSexual,
        _ => cat,
      };
    }

    String getL10nDesc(String cat) {
      return switch (cat) {
        'social' => l10n.catDescSocial,
        'party' => l10n.catDescParty,
        'food' => l10n.catDescFood,
        'embarrassing' => l10n.catDescEmbarrassing,
        'relationships' => l10n.catDescRelationships,
        'confessions' => l10n.catDescConfessions,
        'risk' => l10n.catDescRisk,
        'moral_gray' => l10n.catDescMoralGray,
        'deep' => l10n.catDescDeep,
        'sexual' => l10n.catDescSexual,
        _ => '',
      };
    }

    Widget buildChip(String category, bool isPremiumOnly) {
      final isSelected = selectedCategories.contains(category);
      final isLocked = isPremiumOnly && !isPremium;

      return GestureDetector(
        onLongPress: () {
          final desc = getL10nDesc(category);
          if (desc.isNotEmpty) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${getL10nLabel(category)}: $desc',
                  style: AppTypography.bodySmall.copyWith(color: Colors.white),
                ),
                backgroundColor: AppColors.surface,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        child: ActionChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                getL10nLabel(category),
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected
                      ? AppColors.background
                      : (isLocked
                            ? AppColors.textTertiary
                            : AppColors.textSecondary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (isLocked) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ],
          ),
          backgroundColor: isSelected
              ? AppColors.primary
              : AppColors.surface.withValues(alpha: 0.5),
          side: isLocked
              ? BorderSide(color: AppColors.divider.withValues(alpha: 0.2))
              : isSelected
              ? BorderSide(color: AppColors.primary)
              : BorderSide(color: AppColors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onPressed: () {
            if (isLocked) {
              onPremiumLockedTapped();
              return;
            }
            HapticFeedback.selectionClick();
            onCategoryToggled(category);
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ..._freeCategories.map((c) => buildChip(c, false)),
            ..._premiumCategories.map((c) => buildChip(c, true)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.doubleTapHint,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary.withValues(alpha: 0.6),
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
