import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../offline/cubit/game_config_cubit.dart';
import '../../premium/cubit/premium_cubit.dart';
import '../bloc/lobby_bloc.dart';

/// Create Lobby — dark form surface with glowing accent inputs.
class CreateLobbyScreen extends StatefulWidget {
  const CreateLobbyScreen({super.key});

  @override
  State<CreateLobbyScreen> createState() => _CreateLobbyScreenState();
}

class _CreateLobbyScreenState extends State<CreateLobbyScreen> {
  final _nameController = TextEditingController();
  bool _nsfwEnabled = false;
  bool _isDrinkingGame = false;
  int _maxRounds = AppConstants.maxRoundsFree;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    final config = context.read<GameConfigCubit>().state;
    _nsfwEnabled = config.nsfwEnabled;
    _isDrinkingGame = config.isDrinkingGame;
    _maxRounds = config.maxRounds;
    _categories = List<String>.from(config.categories);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createLobby() {
    if (_nameController.text.trim().isEmpty) return;
    final config = context.read<GameConfigCubit>().state;

    context.read<LobbyBloc>().add(CreateLobbyRequested(
          hostName: _nameController.text.trim(),
          maxRounds: _maxRounds,
          nsfwEnabled: _nsfwEnabled,
          language: config.language,
          categories: _categories,
        ));
  }

  void _togglePremiumFeature({
    required bool isPremium,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    if (!isPremium && value) {
      context.push('/premium');
      return;
    }
    onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = context.watch<PremiumCubit>().state.isPremium;
    final maxRoundsLimit = isPremium
        ? AppConstants.maxRoundsPremium
        : AppConstants.maxRoundsFree;

    return BlocListener<LobbyBloc, LobbyState>(
      listener: (context, state) {
        if (state.status == LobbyBlocStatus.loaded && state.lobby != null) {
          context.go('/lobby/${state.lobby!.id}/waiting');
        }
        if (state.status == LobbyBlocStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? l10n.error)),
          );
        }
      },
      child: Scaffold(
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
            l10n.createLobby,
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.yourName,
                  style: AppTypography.overline.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _nameController,
                  maxLength: 20,
                  style: AppTypography.body,
                  decoration: InputDecoration(
                    hintText: l10n.enterDisplayName,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),
                Divider(color: AppColors.divider),
                const SizedBox(height: AppSpacing.md),

                // ── Rounds ──
                Text(
                  l10n.maxRoundsLabel,
                  style: AppTypography.overline.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.roundsCount(_maxRounds),
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
                        '$_maxRounds',
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
                    value: _maxRounds.toDouble(),
                    min: AppConstants.minRounds.toDouble(),
                    max: maxRoundsLimit.toDouble(),
                    onChanged: (v) {
                      final rounded = (v / 5).round() * 5;
                      setState(() => _maxRounds = rounded.clamp(AppConstants.minRounds, maxRoundsLimit));
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Premium Rules ──
                Text(
                  l10n.premiumRules,
                  style: AppTypography.overline.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // NSFW Toggle
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
                        value: _nsfwEnabled,
                        activeTrackColor: AppColors.secondary,
                        onChanged: (v) => _togglePremiumFeature(
                          isPremium: isPremium,
                          value: v,
                          onChanged: (enabled) =>
                              setState(() => _nsfwEnabled = enabled),
                        ),
                      ),
                    ],
                  ),
                ),

                // Drinking Game Toggle
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
                          Text(l10n.drinkingGameMode,
                              style: AppTypography.label),
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
                        value: _isDrinkingGame,
                        activeTrackColor: AppColors.secondary,
                        onChanged: (v) => _togglePremiumFeature(
                          isPremium: isPremium,
                          value: v,
                          onChanged: (enabled) =>
                              setState(() => _isDrinkingGame = enabled),
                        ),
                      ),
                    ],
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
                  selectedCategories: _categories,
                  isPremium: isPremium,
                  onCategoryToggled: (category) {
                    setState(() {
                      if (_categories.contains(category)) {
                        if (_categories.length > 1) {
                          _categories.remove(category);
                        }
                      } else {
                        _categories.add(category);
                      }
                    });
                  },
                  onPremiumLockedTapped: () => context.push('/premium'),
                ),

                const SizedBox(height: AppSpacing.xl),

                BlocBuilder<LobbyBloc, LobbyState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: l10n.createLobby,
                        isLoading:
                            state.status == LobbyBlocStatus.creating,
                        onPressed: _createLobby,
                        icon: Icons.arrow_forward_rounded,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
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

  static const _freeCategories = ['social', 'party', 'food', 'embarrassing'];
  static const _premiumCategories = [
    'relationships',
    'confessions',
    'risk',
    'moral_gray',
    'deep',
    'sexual'
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
                      : (isLocked ? AppColors.textTertiary : AppColors.textSecondary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (isLocked) ...[
                const SizedBox(width: 4),
                Icon(Icons.lock_rounded, size: 14, color: AppColors.textTertiary),
              ]
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: () {
            if (isLocked) {
              onPremiumLockedTapped();
              return;
            }
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
