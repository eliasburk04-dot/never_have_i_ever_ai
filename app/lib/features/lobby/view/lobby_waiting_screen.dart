import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pressable.dart';
import '../../../domain/entities/lobby.dart';
import '../../../services/backend_session_service.dart';
import '../bloc/lobby_bloc.dart';

/// Lobby Waiting Room — dark glass code display, animated player chips.
///
/// Code card: monospace, accent border, tap-to-copy with haptic.
/// Player list: staggered fade+slideX entrance per player (60ms delay).
/// Host badge: accent-coloured pill.
class LobbyWaitingScreen extends StatelessWidget {
  const LobbyWaitingScreen({super.key, required this.lobbyId});

  final String lobbyId;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LobbyBloc, LobbyState>(
      listener: (context, state) {
        if (state.lobby?.status == LobbyStatus.playing) {
          context.go('/game/${state.lobby!.id}');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Waiting Room'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              context.read<LobbyBloc>().add(const LeaveLobbyRequested());
              context.go('/home');
            },
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<LobbyBloc, LobbyState>(
            builder: (context, state) {
              final lobby = state.lobby;
              if (lobby == null) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }
              if (lobby.status == LobbyStatus.playing) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    context.go('/game/${lobby.id}');
                  }
                });
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    // Lobby code card
                    Pressable(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: lobby.code));
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied!')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusXl,
                          ),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.glowAccent(0.12),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text('LOBBY CODE', style: AppTypography.overline),
                            const SizedBox(height: AppSpacing.sm),
                            Text(lobby.code, style: AppTypography.lobbyCode),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.copy_rounded,
                                  size: 14,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap to copy',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),

                    const SizedBox(height: AppSpacing.xl),

                    // Players header
                    Row(
                      children: [
                        Text('PLAYERS', style: AppTypography.overline),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                          ),
                          child: Text(
                            '${state.players.length}',
                            style: AppTypography.label.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Player chips
                    Expanded(
                      child: ListView.separated(
                        itemCount: state.players.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final player = state.players[index];
                          final isHost = player.userId == lobby.hostId;

                          return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.12,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          player.displayName.isNotEmpty
                                              ? player.displayName[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: AppTypography.button.copyWith(
                                            color: AppColors.accent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        player.displayName,
                                        style: AppTypography.body,
                                      ),
                                    ),
                                    if (isHost)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusFull,
                                          ),
                                        ),
                                        child: Text(
                                          'HOST',
                                          style: AppTypography.overline
                                              .copyWith(
                                                color: AppColors.accentLight,
                                                fontSize: 10,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(delay: (index * 60).ms)
                              .slideX(begin: -0.06);
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Start button for host, status text for guests
                    Builder(builder: (context) {
                      final session = getIt<BackendSessionService>();
                      final myUserId = session.cachedUserId;
                      // Primary: compare cached userId with lobby hostId.
                      // Fallback: check if *we* are flagged is_host in the
                      // player list (covers serialisation mismatches).
                      final isHost = (myUserId != null &&
                              myUserId.isNotEmpty &&
                              lobby.hostId == myUserId) ||
                          (myUserId != null &&
                              state.players.any(
                                (p) => p.userId == myUserId && p.isHost,
                              ));
                      final hasEnough =
                          state.players.length >= AppConstants.minPlayers;
                      final isStarting =
                          state.status == LobbyBlocStatus.starting;

                      if (!hasEnough) {
                        return Text(
                          'Need at least ${AppConstants.minPlayers} players to start',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        );
                      }

                      if (isHost) {
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isStarting
                                ? null
                                : () {
                                    HapticFeedback.mediumImpact();
                                    context
                                        .read<LobbyBloc>()
                                        .add(const StartGameRequested());
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                            ),
                            child: isStarting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Start Game',
                                    style: AppTypography.button.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ).animate().fadeIn(duration: 300.ms);
                      }

                      // Guest: waiting for host
                      return Text(
                        'Waiting for host to start the game…',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
