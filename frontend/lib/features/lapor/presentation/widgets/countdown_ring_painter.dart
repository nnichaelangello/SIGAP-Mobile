import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom Painter untuk Countdown Ring yang smooth
/// Dipisahkan untuk modularitas dan reusability
class CountdownRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isPulse;

  CountdownRingPainter({
    required this.progress,
    required this.color,
    this.isPulse = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    // Background track (subtle)
    final trackPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(center, radius, trackPaint);

    // Active arc
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;

    if (!isPulse) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        paint,
      );
    } else {
      // Pulse Ring saat active (Full circle breathing)
      final pulsePaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 + (math.sin(DateTime.now().millisecond / 100) * 2);
      canvas.drawCircle(center, radius, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
