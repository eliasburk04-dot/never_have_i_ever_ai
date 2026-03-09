import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/game_setup_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/game_setup_chips.dart';
import '../../../l10n/app_localizations.dart';
import '../../offline/cubit/game_config_cubit.dart';
import '../../premium/cubit/premium_cubit.dart';
import '../bloc/lobby_bloc.dart';

class CreateLobbyScreen extends StatefulWidget {
  const CreateLobbyScreen({super.key});

  @override
  State<CreateLobbyScreen> createState() => _CreateLobbyScreenState();
}

class _CreateLobbyScreenState extends State<CreateLobbyScreen> {
  final _nameController = TextEditingController();
  bool _nsfwEnabled = false;
  int _maxRounds = AppConstants.maxRoundsFree;
  List<String> _categories = [];
  String? _selectedPackId;

  @override
  void initState() {
    super.initState();
    final config = context.read<GameConfigCubit>().state;
    _nsfwEnabled = config.nsfwEnabled;
    _maxRounds = config.maxRounds;
    _categories = List<String>.from(config.categories);
    _selectedPackId = config.selectedPackId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createLobby() {
    if (_nameController.text.trim().isEmpty) return;

    if (!GameSetupConfig.canStartGame(
      categories: _categories,
      selectedPackId: _selectedPackId,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one category or creator pack.'),
        ),
      );
      return;
    }

    final config = context.read<GameConfigCubit>().state;

    context.read<LobbyBloc>().add(
      CreateLobbyRequested(
        hostName: _nameController.text.trim(),
        maxRounds: _maxRounds,
        nsfwEnabled: _nsfwEnabled,
        language: config.language,
        categories: _categories,
        selectedPackId: _selectedPackId,
      ),
    );
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
                  decoration: InputDecoration(hintText: l10n.enterDisplayName),
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(color: AppColors.divider),
                const SizedBox(height: AppSpacing.md),
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
                      setState(
                        () => _maxRounds = rounded.clamp(
                          AppConstants.minRounds,
                          maxRoundsLimit,
                        ),
                      );
                    },
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.categoriesLabel,
                  style: AppTypography.overline.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                CategoryGrid(
                  selectedCategories: _categories,
                  isPremium: isPremium,
                  onCategoryToggled: (category) {
                    setState(() {
                      if (_categories.contains(category)) {
                        _categories.remove(category);
                      } else {
                        _categories.add(category);
                      }
                    });
                  },
                  onPremiumLockedTapped: () => context.push('/premium'),
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
                  selectedPackId: _selectedPackId,
                  isPremium: isPremium,
                  onPackSelected: (packId) {
                    setState(() {
                      _selectedPackId = _selectedPackId == packId
                          ? null
                          : packId;
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
                        isLoading: state.status == LobbyBlocStatus.creating,
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
