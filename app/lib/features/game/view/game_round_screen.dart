import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/pressable.dart';
import '../../../domain/entities/player.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/game_bloc.dart';

/// Online Game Round — single-screen layout with question, answer buttons,
/// per-player status list, and host-only "Next Question" button.
///
/// No timer. No intermediate results screen.
class GameRoundScreen extends StatefulWidget {
  const GameRoundScreen({super.key, required this.lobbyId});

  final String lobbyId;

  @override
  State<GameRoundScreen> createState() => _GameRoundScreenState();
}

class _GameRoundScreenState extends State<GameRoundScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GameBloc>().add(GameStarted(widget.lobbyId));
  }

  @override
  Widget build(BuildContext context) {
    final lobbyId = widget.lobbyId;
    return BlocListener<GameBloc, GameState>(
      listener: (context, state) {
        if (state.phase == GamePhase.complete) {
          context.go('/game/$lobbyId/results');
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<GameBloc, GameState>(
            builder: (context, state) {
              switch (state.phase) {
                case GamePhase.loading:
                  return _buildLoading();
                case GamePhase.playing:
                  return _PlayingScreen(
                    state: state,
                    lobbyId: lobbyId,
                  );
                case GamePhase.complete:
                  return const SizedBox.shrink();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.accent.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context)!.gettingNextQuestion,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ─── Playing Screen ──────────────────────────────────────

class _PlayingScreen extends StatelessWidget {
  const _PlayingScreen({
    required this.state,
    required this.lobbyId,
  });

  final GameState state;
  final String lobbyId;

  @override
  Widget build(BuildContext context) {
    final round = state.currentRound;
    if (round == null) return const SizedBox.shrink();

    final tone = round.tone.name;
    final bloc = context.read<GameBloc>();
    final isHost = bloc.isHost;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      color: AppColors.escalationBackground(tone),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Header: round counter + tone badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '${AppLocalizations.of(context)!.rounds} ${state.roundNumber}',
                    style: AppTypography.label
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
                _EscalationBadge(tone: tone),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Question card — the focal point
            _EscalationQuestionCard(
              questionText: round.questionText,
              tone: tone,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Answer buttons — always visible, allow changes
            _AnswerButtons(state: state),

            const SizedBox(height: AppSpacing.lg),

            // Player status list
            Expanded(
              child: _PlayerStatusList(
                players: state.players,
                answers: state.answers,
                currentUserId: bloc.currentUserId,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Host-only "Next Question" button
            if (isHost)
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: state.allAnswered
                      ? AppLocalizations.of(context)!.nextQuestion
                      : AppLocalizations.of(context)!.waitingForAnswers2,
                  onPressed: state.allAnswered && !state.isAdvancing
                      ? () => bloc.add(const HostAdvanceRequested())
                      : null,
                  icon: state.allAnswered
                      ? Icons.arrow_forward_rounded
                      : Icons.hourglass_top_rounded,
                  isLoading: state.isAdvancing,
                ),
              ),

            // Non-host: show waiting indicator when all answered
            if (!isHost && state.allAnswered)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  AppLocalizations.of(context)!.waitingForHostToContinue,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Answer Buttons ──────────────────────────────────────

class _AnswerButtons extends StatelessWidget {
  const _AnswerButtons({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final hasAnswered = state.hasAnswered;
    final myAnswer = state.myAnswer;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        _GameAnswerButton(
          label: l10n.iHave,
          isHave: true,
          isSelected: hasAnswered && myAnswer == true,
          isDimmed: hasAnswered && myAnswer != true,
          onPressed: () {
            HapticFeedback.mediumImpact();
            bloc.add(const AnswerSubmitted(answer: true));
          },
        ),
        const SizedBox(width: AppSpacing.md),
        _GameAnswerButton(
          label: l10n.iHaveNot,
          isHave: false,
          isSelected: hasAnswered && myAnswer == false,
          isDimmed: hasAnswered && myAnswer != false,
          onPressed: () {
            HapticFeedback.mediumImpact();
            bloc.add(const AnswerSubmitted(answer: false));
          },
        ),
      ],
    ).animate().fadeIn(delay: 250.ms, duration: 350.ms).slideY(begin: 0.1);
  }
}

// ─── Player Status List ──────────────────────────────────

class _PlayerStatusList extends StatelessWidget {
  const _PlayerStatusList({
    required this.players,
    required this.answers,
    required this.currentUserId,
  });

  final List<Player> players;
  final Map<String, bool> answers;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final activePlayers =
        players.where((p) => p.isConnected).toList();
    final disconnected =
        players.where((p) => !p.isConnected).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.playersLabel,
            style: AppTypography.overline
                .copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ...activePlayers.map((player) => _PlayerRow(
                      player: player,
                      answer: answers[player.userId],
                      isCurrentUser: player.userId == currentUserId,
                    )),
                ...disconnected.map((player) => _PlayerRow(
                      player: player,
                      answer: null,
                      isCurrentUser: player.userId == currentUserId,
                      isDisconnected: true,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.answer,
    required this.isCurrentUser,
    this.isDisconnected = false,
  });

  final Player player;
  final bool? answer;
  final bool isCurrentUser;
  final bool isDisconnected;

  Color get _backgroundColor {
    if (isDisconnected) return AppColors.surface;
    if (answer == null) return AppColors.surface;
    return answer! ? AppColors.playerRowHave : AppColors.playerRowHaveNot;
  }

  Color get _indicatorColor {
    if (isDisconnected) return AppColors.textTertiary;
    if (answer == null) return AppColors.textTertiary;
    return answer! ? AppColors.iHaveGlow : AppColors.iHaveNotGlow;
  }

  String _statusText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isDisconnected) return l10n.disconnected;
    if (answer == null) return l10n.waiting;
    return answer! ? l10n.iHave : l10n.iHaveNot;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: isCurrentUser
            ? Border.all(
                color: AppColors.accent.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Text(
            player.avatarEmoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${player.displayName}${isCurrentUser ? ' (${AppLocalizations.of(context)!.you})' : ''}',
              style: AppTypography.body.copyWith(
                color: isDisconnected
                    ? AppColors.textTertiary
                    : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _indicatorColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusText(context),
              style: AppTypography.bodySmall.copyWith(
                color: _indicatorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────

/// Escalation-aware question card with dynamic glow.
class _EscalationQuestionCard extends StatelessWidget {
  const _EscalationQuestionCard({
    required this.questionText,
    required this.tone,
  });

  final String questionText;
  final String tone;

  Color get _glowColor {
    switch (tone) {
      case 'deeper':
        return AppColors.toneDeeper;
      case 'secretive':
        return AppColors.toneSecretive;
      case 'freaky':
        return AppColors.toneFreaky;
      default:
        return AppColors.accent;
    }
  }

  double get _glowOpacity {
    switch (tone) {
      case 'deeper':
        return 0.25;
      case 'secretive':
        return 0.35;
      case 'freaky':
        return 0.45;
      default:
        return 0.18;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.12),
            AppColors.accentDeep.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: _glowColor.withValues(alpha: _glowOpacity),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.neverHaveIEver,
            style: AppTypography.overline.copyWith(
              color: AppColors.accentLight.withValues(alpha: 0.6),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            questionText,
            style: AppTypography.question,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }
}

/// Escalation tone badge.
class _EscalationBadge extends StatelessWidget {
  const _EscalationBadge({required this.tone});

  final String tone;

  Color get _color {
    switch (tone) {
      case 'safe':
        return AppColors.toneSafe;
      case 'deeper':
        return AppColors.toneDeeper;
      case 'secretive':
        return AppColors.toneSecretive;
      case 'freaky':
        return AppColors.toneFreaky;
      default:
        return AppColors.toneSafe;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (tone) {
      'deeper' => l10n.deeper,
      'secretive' => l10n.secretive,
      'freaky' => l10n.freaky,
      _ => l10n.safe,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: _color.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.overline.copyWith(
          color: _color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

/// Answer button with green/red styling.
class _GameAnswerButton extends StatelessWidget {
  const _GameAnswerButton({
    required this.label,
    required this.isHave,
    required this.onPressed,
    this.isSelected = false,
    this.isDimmed = false,
  });

  final String label;
  final bool isHave;
  final VoidCallback onPressed;
  final bool isSelected;
  final bool isDimmed;

  @override
  Widget build(BuildContext context) {
    final bgColor = isHave ? AppColors.iHave : AppColors.iHaveNot;
    final glowColor = isHave ? AppColors.iHaveGlow : AppColors.iHaveNotGlow;
    final borderColor =
        isHave ? AppColors.iHaveBorder : AppColors.iHaveNotBorder;

    return Expanded(
      child: Pressable(
        onPressed: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 72,
          decoration: BoxDecoration(
            color: isDimmed ? bgColor.withValues(alpha: 0.3) : bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: borderColor.withValues(alpha: isSelected ? 0.8 : 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.button.copyWith(
                color: isDimmed
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
