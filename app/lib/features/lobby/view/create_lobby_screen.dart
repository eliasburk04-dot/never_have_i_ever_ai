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

  @override
  void initState() {
    super.initState();
    final config = context.read<GameConfigCubit>().state;
    _nsfwEnabled = config.nsfwEnabled;
    _isDrinkingGame = config.isDrinkingGame;
    _maxRounds = config.maxRounds;
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
                  ),
                  child: Slider(
                    value: _maxRounds.toDouble(),
                    min: AppConstants.minRounds.toDouble(),
                    max: maxRoundsLimit.toDouble(),
                    divisions:
                        (maxRoundsLimit - AppConstants.minRounds) ~/ 5,
                    label: '$_maxRounds',
                    onChanged: (v) =>
                        setState(() => _maxRounds = v.round()),
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
