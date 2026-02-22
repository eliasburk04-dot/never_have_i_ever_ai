import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/animated_mesh_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptics_service.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.endGameTitle,
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: Text(
          l10n.endGameBody,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.keepPlaying,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OfflineGameCubit>().endGame();
              context.go('/home');
            },
            child:
                Text(l10n.endGame, style: TextStyle(color: AppColors.error)),
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
    HapticsService.instance.mediumImpact();
    AudioService.instance.playSwipe();
    context.read<OfflineGameCubit>().submitAndAdvance(_selectedHaveCount);
  }

  void _showExitConfirm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.endGameTitle,
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: Text(
          l10n.endGameBody,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.keepPlaying,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OfflineGameCubit>().endGame();
              GoRouter.of(context).go('/home');
            },
            child:
                Text(l10n.endGame, style: TextStyle(color: AppColors.error)),
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
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // 1. Dynamic background based on tone
        Positioned.fill(
          child: AnimatedMeshBackground(
            colors: [
              AppColors.escalationBackground(tone),
              AppColors.primary.withValues(alpha: 0.6),
              AppColors.escalationBackground(tone).withValues(alpha: 0.8),
              switch (tone) {
                'freaky' => AppColors.toneFreaky,
                'deeper' => AppColors.toneDeeper,
                'secretive' => AppColors.toneSecretive,
                _ => AppColors.accentDeep,
              },
            ],
            speed: tone == 'safe' ? 0.8 : 1.5,
          ),
        ),
        
        // 2. Content
        SafeArea(
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
                    '${l10n.rounds} ${s.roundNumber} / ${s.maxRounds}',
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
                      l10n.endGame,
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
              drinkingRule: s.currentDrinkingRule,
            ),

            const Spacer(),

            // "How many said I have?" picker
            Text(
              l10n.howManySaidIHave,
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
                    HapticsService.instance.lightImpact();
                    AudioService.instance.playTap();
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
                            ? AppColors.background
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.outOfPlayers(playerCount),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textTertiary),
            ),

            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: l10n.next,
                onPressed: _submitAndAdvance,
                icon: Icons.arrow_forward_rounded,
              ),
            ),
          ],
        ),
      ),
      ),
    ],
  );
  }
}

// ─── Offline Question Card ───────────────────────────────

class _OfflineQuestionCard extends StatelessWidget {
  const _OfflineQuestionCard({
    required this.text,
    required this.tone,
    this.isRecycled = false,
    this.drinkingRule,
  });

  final String text;
  final String tone;
  final bool isRecycled;
  final String? drinkingRule;

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
    return GlassContainer(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      color: AppColors.accent.withValues(alpha: 0.05),
      borderWidth: 1.5,
      child: Column(
        children: [
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Text(
              l10n.neverHaveIEver,
              style: AppTypography.overline.copyWith(
                color: AppColors.accentLight.withValues(alpha: 0.6),
                letterSpacing: 3,
              ),
            );
          }),
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
              child: Builder(builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  l10n.recycled,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textTertiary, fontSize: 12),
                );
              }),
            ),
          ],
          if (drinkingRule != null && drinkingRule!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🍺', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      drinkingRule!,
                      style: AppTypography.body.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
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

    final l10n = AppLocalizations.of(context)!;
    final label = switch (tone) {
      'deeper' => l10n.deeper,
      'secretive' => l10n.secretive,
      'freaky' => l10n.freaky,
      _ => l10n.safe,
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
        label.toUpperCase(),
        style: AppTypography.overline.copyWith(
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
