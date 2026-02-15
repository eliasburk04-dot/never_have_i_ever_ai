import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';

/// Universal pressable wrapper that provides:
///   - Scale-down on tap (1.0 → 0.96)
///   - Spring-back release
///   - Optional haptic feedback
///   - Pointer-aware (iPad trackpad hover support)
///
/// Use this for ALL interactive elements — buttons, cards, tiles.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onPressed,
    this.disabled = false,
    this.haptic = true,
    this.scale = AppMotion.pressScale,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool disabled;
  final bool haptic;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.pressDuration,
      reverseDuration: AppMotion.releaseDuration,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.disabled || widget.onPressed == null) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onTap() {
    if (widget.disabled || widget.onPressed == null) return;
    if (widget.haptic) HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = !widget.disabled && widget.onPressed != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isActive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: AnimatedOpacity(
                opacity: widget.disabled ? 0.4 : (_isHovered ? 0.92 : 1.0),
                duration: const Duration(milliseconds: 150),
                child: child,
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
