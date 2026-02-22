import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    return isPremium ? AppConstants.maxPlayers : 5; // Free users get max 5 players
  }

  void _incrementPlayers() {
    final limit = _getMaxPlayersLimit(context);
    if (_playerCount >= limit) {
      final isPremium = context.read<PremiumCubit>().state.isPremium;
      if (!isPremium) {
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
    final config = context.read<GameConfigCubit>();

    // Generate dummy players for gameplay logic based on count
    final players = List.generate(
      _playerCount,
      (i) => OfflinePlayer(name: 'Player ${i + 1}', emoji: '👤'),
    );

    // Persist settings for "Play Again"
    config.setPlayers(players);

    // TODO: Restore after testing
    // final isPremium = context.read<PremiumCubit>().state.isPremium;

    context.read<OfflineGameCubit>().startGame(
          players: players,
          maxRounds: config.state.maxRounds,
          language: config.state.language,
          nsfwEnabled: config.state.nsfwEnabled,
          // TODO: Restore after testing
          // isPremium: isPremium,
          isPremium: true, // TEMP: bypassed for NSFW testing
          isDrinkingGame: config.state.isDrinkingGame,
          customQuestions: const [], // Feature removed
        );

    context.go('/offline/game');
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PremiumCubit>().state.isPremium;
    final maxRoundsLimit =
        isPremium ? AppConstants.maxRoundsPremium : AppConstants.maxRoundsFree;
    final l10n = AppLocalizations.of(context)!;
    final config = context.watch<GameConfigCubit>().state;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text('Setup', // Using hardcoded English to replace offlineMode as requested
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.lg * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PLAYERS section
                  // PLAYER COUNT section
                  Text(l10n.players,
                      style: AppTypography.overline
                          .copyWith(color: AppColors.textTertiary)),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people_alt_rounded, color: AppColors.textSecondary, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Player Count', style: AppTypography.label),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _decrementPlayers,
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                              color: AppColors.textTertiary,
                            ),
                            SizedBox(
                              width: 30,
                              child: Text(
                                '$_playerCount',
                                style: AppTypography.h3.copyWith(color: AppColors.accent),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              onPressed: _incrementPlayers,
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              color: AppColors.accent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

              Divider(color: AppColors.divider),
              const SizedBox(height: AppSpacing.sm),

              // ROUNDS
              Text(l10n.rounds,
                  style: AppTypography.overline
                      .copyWith(color: AppColors.textTertiary)),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${config.maxRounds} rounds', style: AppTypography.body),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text('${config.maxRounds}',
                        style: AppTypography.label
                            .copyWith(color: AppColors.accent)),
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
                  min: 5,
                  max: maxRoundsLimit.toDouble(),
                  divisions: (maxRoundsLimit - 5) ~/ 5,
                  label: '${config.maxRounds}',
                  onChanged: (v) =>
                      context.read<GameConfigCubit>().setMaxRounds(v.round()),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              
              // ----------------------------------------------------
              // PREMIUM FEATURES SECTION
              // ----------------------------------------------------
              Text('Premium Rules',
                  style: AppTypography.overline
                      .copyWith(color: AppColors.secondary)),
              const SizedBox(height: AppSpacing.xs),
              
              // Drinking Game Mode Toggle
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: config.isDrinkingGame && !isPremium 
                      ? AppColors.error 
                      : AppColors.divider,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Drinking Game Mode', style: AppTypography.label),
                        if (!isPremium) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Icon(Icons.lock_rounded,
                              size: 14, color: AppColors.textTertiary),
                        ],
                      ],
                    ),
                    Switch(
                      value: config.isDrinkingGame,
                      activeTrackColor: AppColors.secondary,
                      onChanged: isPremium
                          ? (v) => context.read<GameConfigCubit>().setIsDrinkingGame(v)
                          : (_) => context.push('/premium'),
                    ),
                  ],
                ),
              ),

                  ],
                ),
              ),
}
