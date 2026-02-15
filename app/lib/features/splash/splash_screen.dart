import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/repositories/i_auth_repository.dart';

/// Splash screen — cinematic dark entrance with pulsing glow.
///
/// Layout: Centred vertically. Title fades up, subtitle follows.
/// Background: Radial accent glow from centre, fading to [background].
/// Motion: Title slides up 0.15 + fades 500ms, subtitle 300ms delay.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final authRepo = getIt<IAuthRepository>();
    final user = await authRepo.signInAnonymously();

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    if (user != null) {
      context.go('/home');
    } else {
      final retryUser = await authRepo.signInAnonymously();
      if (mounted) {
        context.go(retryUser != null ? '/home' : '/language');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient radial glow behind content
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 1200.ms)
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1.2, 1.2),
                duration: 2000.ms,
                curve: Curves.easeOut,
              ),

          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Never Have\nI Ever',
                  style: AppTypography.display,
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'AI-powered party game',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 1.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent.withValues(alpha: 0.5),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
