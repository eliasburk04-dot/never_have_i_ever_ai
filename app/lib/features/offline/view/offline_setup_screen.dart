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

    final players = List.generate(
      _playerCount,
      (i) => OfflinePlayer(name: 'Player ${i + 1}', emoji: '👤'),
    );

    configCubit.setPlayers(players);

    // TODO: Restore after testing
    // final isPremium = context.read<PremiumCubit>().state.isPremium;
    context.read<OfflineGameCubit>().startGame(
      players: players,
      maxRounds: config.maxRounds,
      language: config.language,
      nsfwEnabled: config.nsfwEnabled,
      // TODO: Restore after testing
      // isPremium: isPremium,
      isPremium: true,
      isDrinkingGame: config.isDrinkingGame,
      customQuestions: const [],
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (AppSpacing.lg * 2),
                ),
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
                              Text(l10n.playerCount, style: AppTypography.label),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                isPremium
                                    ? l10n.upToPlayers(AppConstants.maxPlayers)
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
                            color: AppColors.accent.withValues(alpha: 0.12),
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
                        overlayColor: AppColors.accent.withValues(alpha: 0.12),
                      ),
                      child: Slider(
                        value: config.maxRounds.toDouble(),
                        min: AppConstants.minRounds.toDouble(),
                        max: maxRoundsLimit.toDouble(),
                        divisions:
                            (maxRoundsLimit - AppConstants.minRounds) ~/ 5,
                        label: '${config.maxRounds}',
                        onChanged: (v) => context
                            .read<GameConfigCubit>()
                            .setMaxRounds(v.round()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.premiumRules,
                      style: AppTypography.overline.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                              Text(l10n.nsfwMode, style: AppTypography.label),
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
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: l10n.startGame,
                      onPressed: _startGame,
                      isPrimary: true,
                      icon: Icons.play_arrow_rounded,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
