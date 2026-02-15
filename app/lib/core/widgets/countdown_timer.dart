import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Circular countdown timer — glowing accent ring on dark surface.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({
    super.key,
    required this.seconds,
    this.onComplete,
    this.size = 52,
  });

  final int seconds;
  final VoidCallback? onComplete;
  final double size;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final remaining = (widget.seconds * (1 - _controller.value)).ceil();
        final progress = 1 - _controller.value;
        final isUrgent = progress <= 0.25;
        final color = isUrgent ? AppColors.error : AppColors.accent;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Text(
                '$remaining',
                style: AppTypography.h3.copyWith(
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
