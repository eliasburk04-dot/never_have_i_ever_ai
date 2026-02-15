import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../bloc/lobby_bloc.dart';

/// Join Lobby — monospace code input with glow focus state.
class JoinLobbyScreen extends StatefulWidget {
  const JoinLobbyScreen({super.key});

  @override
  State<JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends State<JoinLobbyScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _joinLobby() {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    if (name.isEmpty || code.length != 6) return;

    context.read<LobbyBloc>().add(JoinLobbyRequested(
          code: code,
          playerName: name,
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
        appBar: AppBar(title: const Text('Join Lobby')),
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

                Text('LOBBY CODE', style: AppTypography.overline),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _codeController,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  style: AppTypography.lobbyCode,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'ABC123',
                    hintStyle: AppTypography.lobbyCode.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),

                const Spacer(),

                BlocBuilder<LobbyBloc, LobbyState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'Join Game',
                        isLoading:
                            state.status == LobbyBlocStatus.joining,
                        onPressed: _joinLobby,
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
