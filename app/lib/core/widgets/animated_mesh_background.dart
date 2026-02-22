import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A dynamic, slow-moving mesh gradient background.
/// Uses multiple blurred circles that drift around the screen to create a premium,
/// "live" feeling behind the glassmorphic UI.
class AnimatedMeshBackground extends StatefulWidget {
  const AnimatedMeshBackground({
    super.key,
    required this.colors,
    this.speed = 1.0,
  });

  /// The colors of the glowing orbs. Usually 3-4 colors work best.
  final List<Color> colors;
  
  /// Multiplier for the animation speed.
  final double speed;

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _random = Random();
  
  late List<_MeshOrb> _orbs;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // Long duration for slow drift
    )..repeat();

    // Initialize orbs with random starting positions and unique drift parameters
    _orbs = widget.colors.map((color) {
      return _MeshOrb(
        color: color,
        baseX: _random.nextDouble(),
        baseY: _random.nextDouble(),
        radiusX: 0.15 + _random.nextDouble() * 0.2, // Elliptical movement
        radiusY: 0.15 + _random.nextDouble() * 0.2,
        speedX: (0.5 + _random.nextDouble()) * widget.speed,
        speedY: (0.5 + _random.nextDouble()) * widget.speed,
        phaseX: _random.nextDouble() * 2 * pi,
        phaseY: _random.nextDouble() * 2 * pi,
        size: 0.6 + _random.nextDouble() * 0.5, // Relative to screen size
      );
    }).toList();
  }

  @override
  void didUpdateWidget(covariant AnimatedMeshBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.colors != oldWidget.colors) {
      // Re-assign colors to existing orbs to avoid jumpy transitions
      for (int i = 0; i < widget.colors.length; i++) {
        if (i < _orbs.length) {
          _orbs[i].color = widget.colors[i];
        } else {
          // Add new orb if needed
          _orbs.add(_MeshOrb(
            color: widget.colors[i],
            baseX: _random.nextDouble(),
            baseY: _random.nextDouble(),
            radiusX: 0.15 + _random.nextDouble() * 0.2,
            radiusY: 0.15 + _random.nextDouble() * 0.2,
            speedX: (0.5 + _random.nextDouble()) * widget.speed,
            speedY: (0.5 + _random.nextDouble()) * widget.speed,
            phaseX: _random.nextDouble() * 2 * pi,
            phaseY: _random.nextDouble() * 2 * pi,
            size: 0.6 + _random.nextDouble() * 0.5,
          ));
        }
      }
      if (_orbs.length > widget.colors.length) {
        _orbs.removeRange(widget.colors.length, _orbs.length);
      }
    }
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
        final double t = _controller.value * 2 * pi;
        
        return CustomPaint(
          painter: _MeshPainter(
            orbs: _orbs,
            time: t,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _MeshOrb {
  _MeshOrb({
    required this.color,
    required this.baseX,
    required this.baseY,
    required this.radiusX,
    required this.radiusY,
    required this.speedX,
    required this.speedY,
    required this.phaseX,
    required this.phaseY,
    required this.size,
  });

  Color color;
  final double baseX;
  final double baseY;
  final double radiusX;
  final double radiusY;
  final double speedX;
  final double speedY;
  final double phaseX;
  final double phaseY;
  final double size;

  Offset getPosition(double time, Size constraints) {
    // Calculate Lissajous curve for smooth, pseudo-random drifting
    final double x = baseX + radiusX * sin(time * speedX + phaseX);
    final double y = baseY + radiusY * cos(time * speedY + phaseY);
    
    // Convert normalized coordinates [0, 1] to screen coordinates
    return Offset(
      x.clamp(-0.2, 1.2) * constraints.width,
      y.clamp(-0.2, 1.2) * constraints.height,
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({
    required this.orbs,
    required this.time,
  });

  final List<_MeshOrb> orbs;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the orbs as large, blurred radial gradients
    for (final orb in orbs) {
      final center = orb.getPosition(time, size);
      final radius = size.longestSide * orb.size;

      final paint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [
            orb.color,
            orb.color.withValues(alpha: 0.0),
          ],
          [0.0, 1.0],
        )
        // Add blend mode to allow colors to mix brightly
        ..blendMode = BlendMode.screen;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) {
    // Always repaint since time is constantly ticking
    return oldDelegate.time != time || oldDelegate.orbs != orbs;
  }
}
