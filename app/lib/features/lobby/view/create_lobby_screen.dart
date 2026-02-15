import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
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
  int _maxRounds = AppConstants.maxRoundsFree;
  final String _language = 'en';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createLobby() {
    if (_nameController.text.trim().isEmpty) return;

    context.read<LobbyBloc>().add(CreateLobbyRequested(
          hostName: _nameController.text.trim(),
          maxRounds: _maxRounds,
          nsfwEnabled: _nsfwEnabled,
          language: _language,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LobbyBloc, LobbyState>(
      listener: (context, state) {
        if (state.status == LobbyBlocStatus.loaded && state.lobby != null) {
          context.go('/lobby/${state.lobby!.id}/waiting');
        }
        if (state.status == LobbyBlocStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Error')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Create Lobby')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR NAME', style: AppTypography.overline),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _nameController,
                  maxLength: 20,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    hintText: 'Enter your display name',
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                Text('MAX ROUNDS', style: AppTypography.overline),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _maxRounds.toDouble(),
                        min: 5,
                        max: AppConstants.maxRoundsFree.toDouble(),
                        divisions: 9,
                        label: '$_maxRounds',
                        onChanged: (v) =>
                            setState(() => _maxRounds = v.round()),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text('$_maxRounds',
                          style: AppTypography.h3
                              .copyWith(color: AppColors.accent)),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NSFW Mode', style: AppTypography.body),
                          const SizedBox(height: 2),
                          Text(
                            '18+ questions included',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                      Switch(
                        value: _nsfwEnabled,
                        onChanged: (v) =>
                            setState(() => _nsfwEnabled = v),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                BlocBuilder<LobbyBloc, LobbyState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'Create Lobby',
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
