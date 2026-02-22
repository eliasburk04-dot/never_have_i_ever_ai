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
import '../../../core/widgets/pressable.dart';
import '../../../domain/entities/offline_player.dart';
import '../../../features/premium/cubit/premium_cubit.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/game_config_cubit.dart';
import '../cubit/offline_game_cubit.dart';

/// Random emojis assigned to players.
const _avatarEmojis = [
  '😎', '🤩', '🥳', '😜', '🤠', '🦊', '🐱', '🐶',
  '🦄', '🌟', '🎯', '🔥', '💎', '🍕', '🎸', '🎮',
  '🚀', '⚡', '🌈', '🎪',
];

class OfflineSetupScreen extends StatefulWidget {
  const OfflineSetupScreen({super.key});

  @override
  State<OfflineSetupScreen> createState() => _OfflineSetupScreenState();
}

class _OfflineSetupScreenState extends State<OfflineSetupScreen> {
  final _controllers = <TextEditingController>[];
  final _emojis = <String>[];
  bool _initialized = false;

  final _random = Random();
  final _usedEmojis = <String>{};

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final config = context.read<GameConfigCubit>().state;
      if (config.players.isNotEmpty) {
        // Restore persisted players
        for (final p in config.players) {
          _controllers.add(TextEditingController(text: p.name));
          _emojis.add(p.emoji);
          _usedEmojis.add(p.emoji);
        }
      } else {
        // Default: 2 empty players
        _controllers.addAll([
          TextEditingController(),
          TextEditingController(),
        ]);
        _emojis.addAll([_randomEmoji(), _randomEmoji()]);
      }
    }
  }

  int _getMaxPlayersLimit(BuildContext context) {
    final isPremium = context.read<PremiumCubit>().state.isPremium;
    return isPremium ? AppConstants.maxPlayers : 5; // Free users get max 5 players
  }

  String _randomEmoji() {
    final available =
        _avatarEmojis.where((e) => !_usedEmojis.contains(e)).toList();
    if (available.isEmpty) {
      return _avatarEmojis[_random.nextInt(_avatarEmojis.length)];
    }
    final emoji = available[_random.nextInt(available.length)];
    _usedEmojis.add(emoji);
    return emoji;
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    final limit = _getMaxPlayersLimit(context);
    if (_controllers.length >= limit) return;
    HapticFeedback.lightImpact();
    setState(() {
      _controllers.add(TextEditingController());
      _emojis.add(_randomEmoji());
    });
  }

  void _removePlayer(int index) {
    if (_controllers.length <= AppConstants.minPlayers) return;
    HapticFeedback.lightImpact();
    setState(() {
      _usedEmojis.remove(_emojis[index]);
      _controllers[index].dispose();
      _controllers.removeAt(index);
      _emojis.removeAt(index);
    });
  }

  void _startGame() {
    final l10n = AppLocalizations.of(context)!;
    final config = context.read<GameConfigCubit>();

    // Validate names
    final names = _controllers.map((c) => c.text.trim()).toList();
    if (names.any((n) => n.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.allPlayersNeedName,
              style: TextStyle(color: AppColors.textPrimary)),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
      return;
    }

    // Check for duplicates
    if (names.toSet().length != names.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.playerNamesMustBeUnique,
              style: TextStyle(color: AppColors.textPrimary)),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
      return;
    }

    final players = List.generate(
      names.length,
      (i) => OfflinePlayer(name: names[i], emoji: _emojis[i]),
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
          customQuestions: config.state.customQuestions,
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
        title: Text(l10n.offlineMode,
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
                  Text(l10n.players,
                      style: AppTypography.overline
                          .copyWith(color: AppColors.textTertiary)),
                  const SizedBox(height: AppSpacing.sm),

                  // Player list — use a shrink-wrapped, non-scrollable list
                  // (outer SingleChildScrollView handles scrolling)
                  ...List.generate(_controllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                _emojis[index],
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextField(
                                controller: _controllers[index],
                                maxLength: 20,
                                style: AppTypography.body
                                    .copyWith(color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: l10n.playerHint(index + 1),
                                  counterText: '',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintStyle: AppTypography.body.copyWith(
                                      color: AppColors.textTertiary),
                                ),
                              ),
                            ),
                            if (_controllers.length >
                                AppConstants.minPlayers)
                              Pressable(
                                onPressed: () => _removePlayer(index),
                                child: Icon(Icons.close_rounded,
                                    size: 18, color: AppColors.textTertiary),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Add player button
                  if (_controllers.length < _getMaxPlayersLimit(context))
                    Pressable(
                      onPressed: _addPlayer,
                      child: Container(
                        margin: const EdgeInsets.only(top: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded,
                                color: AppColors.accent, size: 20),
                            const SizedBox(width: AppSpacing.xs),
                            Text(l10n.addPlayer,
                                style: AppTypography.label
                                    .copyWith(color: AppColors.accent)),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 200.ms)
                  else if (!isPremium)
                    // Premium upsell button for players > 5
                    Pressable(
                      onPressed: () => context.push('/premium'),
                      child: Container(
                        margin: const EdgeInsets.only(top: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_rounded,
                                color: AppColors.secondary, size: 16),
                            const SizedBox(width: AppSpacing.xs),
                            Text('Unlock Unlimited Players',
                                style: AppTypography.label
                                    .copyWith(color: AppColors.secondary)),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 200.ms),

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

              // LANGUAGE
              Text(l10n.language,
                  style: AppTypography.overline
                      .copyWith(color: AppColors.textTertiary)),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButton<String>(
                  value: config.language,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: AppColors.surfaceElevated,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textPrimary),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('🇺🇸 English')),
                    DropdownMenuItem(value: 'de', child: Text('🇩🇪 Deutsch')),
                    DropdownMenuItem(value: 'es', child: Text('🇪🇸 Español')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      context.read<GameConfigCubit>().setLanguage(v);
                    }
                  },
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

              // Custom Cards (Premium)
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
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('Custom Questions', style: AppTypography.label),
                            if (!isPremium) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Icon(Icons.lock_rounded,
                                  size: 14, color: AppColors.textTertiary),
                            ],
                          ],
                        ),
                        Text(
                          '${config.customQuestions.length}',
                          style: AppTypography.label.copyWith(color: AppColors.accent),
                        ),
                      ],
                    ),
                    if (config.customQuestions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      ...List.generate(config.customQuestions.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '"${config.customQuestions[i]}"',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isPremium)
                                Pressable(
                                  onPressed: () => context.read<GameConfigCubit>().removeCustomQuestion(i),
                                  child: Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Pressable(
                      onPressed: isPremium
                          ? () => _showAddCustomQuestionDialog(context)
                          : () => context.push('/premium'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isPremium
                              ? AppColors.accent.withValues(alpha: 0.1)
                              : AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isPremium ? '+ Add Own Question' : 'Unlock Custom Cards',
                          style: AppTypography.label.copyWith(
                            color: isPremium ? AppColors.accent : AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // NSFW Toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
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
                        Text(l10n.nsfwLabel, style: AppTypography.label),
                        // TODO: Restore premium lock icon after testing
                        // if (!isPremium) ...[
                        //   const SizedBox(width: AppSpacing.xs),
                        //   Icon(Icons.lock_rounded,
                        //       size: 14, color: AppColors.textTertiary),
                        // ],
                      ],
                    ),
                    Switch(
                      value: config.nsfwEnabled,
                      activeTrackColor: AppColors.accent,
                      onChanged: isPremium
                          ? (v) => context.read<GameConfigCubit>().setNsfwEnabled(v)
                          : (_) => context.push('/premium'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Start
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: l10n.startGame,
                  onPressed: _startGame,
                  icon: Icons.play_arrow_rounded,
                ),
              ),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCustomQuestionDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Add Custom Question', style: AppTypography.h3),
        content: TextField(
          controller: controller,
          style: AppTypography.body,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Never have I ever...',
            hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                context.read<GameConfigCubit>().addCustomQuestion(text);
              }
              Navigator.pop(ctx);
            },
            child: Text('Add', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}
