import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Subtle confetti celebration overlay
class ConfettiOverlay extends StatelessWidget {
  final AnimationController controller;

  const ConfettiOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (controller.value == 0) return const SizedBox.shrink();
        return IgnorePointer(
          child: CustomPaint(
            painter: _ConfettiPainter(
              progress: controller.value,
              colors: [
                AppConstants.primaryColor,
                Colors.green.shade400,
                Colors.amber.shade400,
                Colors.blue.shade300,
              ],
            ),
            size: MediaQuery.of(context).size,
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.colors})
      : particles = List.generate(25, (i) => _ConfettiParticle(i, colors));

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: (1 - progress) * 0.8)
        ..style = PaintingStyle.fill;

      final x = particle.startX * size.width;
      final y = particle.startY * size.height +
          (progress * size.height * particle.speed);
      final rotation = progress * particle.rotation * 2 * pi;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      if (particle.isCircle) {
        canvas.drawCircle(Offset.zero, particle.size, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 0.6),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConfettiParticle {
  final double startX;
  final double startY;
  final double speed;
  final double rotation;
  final double size;
  final Color color;
  final bool isCircle;

  _ConfettiParticle(int index, List<Color> colors)
      : startX = Random(index).nextDouble(),
        startY = Random(index * 2).nextDouble() * 0.3 - 0.3,
        speed = 0.3 + Random(index * 3).nextDouble() * 0.5,
        rotation = Random(index * 4).nextDouble() * 4,
        size = 4 + Random(index * 5).nextDouble() * 6,
        color = colors[Random(index * 6).nextInt(colors.length)],
        isCircle = Random(index * 7).nextBool();
}
