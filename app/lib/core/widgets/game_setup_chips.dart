import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/creator_packs.dart';
import '../constants/game_setup_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../l10n/app_localizations.dart';

class CreatorPackGrid extends StatelessWidget {
  const CreatorPackGrid({
    super.key,
    required this.selectedPackId,
    required this.isPremium,
    required this.onPackSelected,
    required this.onPremiumLockedTapped,
  });

  final String? selectedPackId;
  final bool isPremium;
  final ValueChanged<String> onPackSelected;
  final VoidCallback onPremiumLockedTapped;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: CreatorPacks.all.map((pack) {
        final isSelected = selectedPackId == pack.id;
        final isLocked = pack.isPremium && !isPremium;

        return ActionChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pack.title,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected
                      ? AppColors.background
                      : (isLocked
                            ? AppColors.textTertiary
                            : AppColors.textSecondary),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (isLocked) ...[
                const SizedBox(width: 4),
                const Icon(Icons.lock_rounded, size: 14),
              ],
            ],
          ),
          backgroundColor: isSelected
              ? AppColors.accent
              : AppColors.surface.withValues(alpha: 0.5),
          side: isLocked
              ? BorderSide(color: AppColors.divider.withValues(alpha: 0.2))
              : BorderSide(
                  color: isSelected ? AppColors.accent : AppColors.divider,
                ),
          onPressed: () {
            if (isLocked) {
              onPremiumLockedTapped();
              return;
            }
            HapticFeedback.selectionClick();
            onPackSelected(pack.id);
          },
        );
      }).toList(),
    );
  }
}

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.selectedCategories,
    required this.isPremium,
    required this.onCategoryToggled,
    required this.onPremiumLockedTapped,
  });

  final List<String> selectedCategories;
  final bool isPremium;
  final ValueChanged<String> onCategoryToggled;
  final VoidCallback onPremiumLockedTapped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget buildChip(String category, bool isPremiumOnly) {
      final isSelected = selectedCategories.contains(category);
      final isLocked = isPremiumOnly && !isPremium;

      return GestureDetector(
        onLongPress: () {
          final message = GameSetupConfig.categoryDescriptionMessage(
            l10n,
            category,
          );
          if (message != null) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message,
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
                GameSetupConfig.categoryLabel(l10n, category),
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected
                      ? AppColors.background
                      : (isLocked
                            ? AppColors.textTertiary
                            : AppColors.textSecondary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (isLocked) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onPressed: () {
            if (isLocked) {
              onPremiumLockedTapped();
              return;
            }
            HapticFeedback.selectionClick();
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
            ...GameSetupConfig.freeCategories.map((c) => buildChip(c, false)),
            ...GameSetupConfig.premiumCategories.map((c) => buildChip(c, true)),
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
