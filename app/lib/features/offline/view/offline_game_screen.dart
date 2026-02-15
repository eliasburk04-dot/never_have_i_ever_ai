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
import '../cubit/offline_game_cubit.dart';

/// Offline pass-and-play — escalation-aware dark UI.
class OfflineGameScreen extends StatelessWidget {
  const OfflineGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog(context);
      },
      child: BlocListener<OfflineGameCubit, OfflineGameState>(
        listener: (context, state) {
          if (state.phase == OfflineGamePhase.complete) {
            context.go('/offline/results');
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: BlocBuilder<OfflineGameCubit, OfflineGameState>(
              builder: (context, state) {
                switch (state.phase) {
                  case OfflineGamePhase.idle:
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent.withValues(alpha: 0.6),
                      ),
                    );
                  case OfflineGamePhase.showingQuestion:
                    return _QuestionPhase(state: state);
                  case OfflineGamePhase.complete:
                    return const SizedBox.shrink();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('End Game?',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: Text(
          'Your progress will be saved. You can resume later.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Playing',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OfflineGameCubit>().endGame();
              context.go('/home');
            },
            child:
                Text('End Game', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Question Phase ──────────────────────────────────────

class _QuestionPhase extends StatefulWidget {
  const _QuestionPhase({required this.state});
  final OfflineGameState state;

  @override
  State<_QuestionPhase> createState() => _QuestionPhaseState();
}

class _QuestionPhaseState extends State<_QuestionPhase> {
  int _selectedHaveCount = 0;

  @override
  void didUpdateWidget(covariant _QuestionPhase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.roundNumber != oldWidget.state.roundNumber) {
      _selectedHaveCount = 0;
    }
  }

  void _submitAndAdvance() {
    HapticFeedback.mediumImpact();
    context.read<OfflineGameCubit>().submitAndAdvance(_selectedHaveCount);
  }

  void _showExitConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('End Game?',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: Text(
          'Your progress will be saved. You can resume later.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Playing',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OfflineGameCubit>().endGame();
              GoRouter.of(context).go('/home');
            },
            child:
                Text('End Game', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final playerCount = s.playerCount;
    final tone = s.currentTone;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      color: AppColors.escalationBackground(tone),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Header
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
                    'Round ${s.roundNumber} / ${s.maxRounds}',
                    style: AppTypography.label
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
                Pressable(
                  onPressed: () => _showExitConfirm(context),
                  child: Container(
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
                      'End Game',
                      style: AppTypography.label
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ),
                ),
              ],
            ),

            // Tone badge
            const SizedBox(height: AppSpacing.sm),
            _ToneBadge(tone: tone),

            const Spacer(),

            // Question card with escalation glow
            _OfflineQuestionCard(
              text: s.currentQuestionText ?? '',
              tone: tone,
              isRecycled: s.currentQuestionRecycled,
              isAiGenerated: s.isAiGenerated,
            ),

            const Spacer(),

            // "How many said I have?" picker
            Text(
              'How many said "I have"?',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),

            // Number picker
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(playerCount + 1, (i) {
                final isSelected = i == _selectedHaveCount;
                return Pressable(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedHaveCount = i);
                  },
                  scale: 0.94,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.glowAccent(0.2),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$i',
                      style: AppTypography.h3.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'out of $playerCount players',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textTertiary),
            ),

            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Next',
                onPressed: _submitAndAdvance,
                icon: Icons.arrow_forward_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Offline Question Card ───────────────────────────────

class _OfflineQuestionCard extends StatelessWidget {
  const _OfflineQuestionCard({
    required this.text,
    required this.tone,
    required this.isRecycled,
    this.isAiGenerated = false,
  });

  final String text;
  final String tone;
  final bool isRecycled;
  final bool isAiGenerated;

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
        children: [
          Text(
            'NEVER HAVE I EVER',
            style: AppTypography.overline.copyWith(
              color: AppColors.accentLight.withValues(alpha: 0.6),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            text,
            style: AppTypography.question,
            textAlign: TextAlign.center,
          ),
          if (isRecycled) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🔄 Recycled',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textTertiary, fontSize: 12),
              ),
            ),
          ],
          if (isAiGenerated) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🤖 AI Generated',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.accent, fontSize: 12),
              ),
            ),
          ],
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

// ─── Tone Badge ──────────────────────────────────────────

class _ToneBadge extends StatelessWidget {
  const _ToneBadge({required this.tone});
  final String tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      'deeper' => AppColors.toneDeeper,
      'secretive' => AppColors.toneSecretive,
      'freaky' => AppColors.toneFreaky,
      _ => AppColors.toneSafe,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        tone.toUpperCase(),
        style: AppTypography.overline.copyWith(
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
