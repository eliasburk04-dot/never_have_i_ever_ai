import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/app_localizations.dart';
import '../../offline/cubit/game_config_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _languageLabel(String code) {
    switch (code) {
      case 'de':
        return '🇩🇪 Deutsch';
      case 'es':
        return '🇪🇸 Español';
      default:
        return '🇬🇧 English';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = context.watch<GameConfigCubit>().state;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.settings,
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // LANGUAGE
          Text(l10n.language,
              style: AppTypography.overline
                  .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButton<String>(
              value: config.language,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: AppColors.surfaceElevated,
              style: AppTypography.body
                  .copyWith(color: AppColors.textPrimary),
              icon: Icon(Icons.expand_more_rounded,
                  color: AppColors.textTertiary),
              items: ['en', 'de', 'es']
                  .map((l) => DropdownMenuItem(
                        value: l,
                        child: Text(_languageLabel(l),
                            style: AppTypography.body
                                .copyWith(color: AppColors.textPrimary)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  context.read<GameConfigCubit>().setLanguage(v);
                }
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ACCOUNT
          Text(l10n.account,
              style: AppTypography.overline
                  .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: AppSpacing.sm),
          Pressable(
            onPressed: () => context.push('/premium'),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.premiumGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.star_rounded,
                        color: AppColors.premiumGold, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(l10n.premiumLabel, style: AppTypography.body),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.textTertiary, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ABOUT
          Text(l10n.about2,
              style: AppTypography.overline
                  .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.appTitle, style: AppTypography.body),
                const SizedBox(height: 4),
                Text(
                  l10n.version,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // LEGAL
          Text(l10n.legal,
              style: AppTypography.overline
                  .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: AppSpacing.sm),
          _LegalLink(
            label: l10n.privacyPolicy,
            onTap: () => context.push('/privacy'),
          ),
          const SizedBox(height: AppSpacing.xs),
          _LegalLink(
            label: l10n.termsOfService,
            onTap: () => context.push('/terms'),
          ),
        ],
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textSecondary)),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
