import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pressable.dart';
import '../../../domain/repositories/i_auth_repository.dart';

/// Language selector — dark glass tiles with flag + label.
///
/// Layout: Centred column with staggered fade-in (60ms per tile).
/// Interaction: Pressable scale 0.96, haptic, navigate on tap.
class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  Future<void> _selectLanguage(
      BuildContext context, String langCode, String label) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);

    final authRepo = getIt<IAuthRepository>();
    await authRepo.updateProfile(preferredLanguage: langCode);

    if (context.mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Choose your\nlanguage',
                style: AppTypography.h1,
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You can change this later in settings',
                style: AppTypography.bodySmall,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: AppSpacing.xxl),
              _LanguageTile(
                flag: '🇬🇧',
                label: 'English',
                onTap: () => _selectLanguage(context, 'en', 'English'),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08),
              const SizedBox(height: AppSpacing.md),
              _LanguageTile(
                flag: '🇩🇪',
                label: 'Deutsch',
                onTap: () => _selectLanguage(context, 'de', 'Deutsch'),
              ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.08),
              const SizedBox(height: AppSpacing.md),
              _LanguageTile(
                flag: '🇪🇸',
                label: 'Español',
                onTap: () => _selectLanguage(context, 'es', 'Español'),
              ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.08),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.flag,
    required this.label,
    required this.onTap,
  });

  final String flag;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTypography.h3),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
