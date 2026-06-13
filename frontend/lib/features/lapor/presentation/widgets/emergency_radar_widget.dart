import 'package:flutter/material.dart';

/// Widget animasi radar untuk tampilan darurat
/// Menampilkan efek pulse yang melingkar seperti sinyal sonar
class EmergencyRadarWidget extends StatefulWidget {
  final bool isActive;
  final Color color;

  const EmergencyRadarWidget({
    super.key,
    this.isActive = true,
    required this.color,
  });

  @override
  State<EmergencyRadarWidget> createState() => _EmergencyRadarWidgetState();
}

class _EmergencyRadarWidgetState extends State<EmergencyRadarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isActive) _startAnimation();
  }

  @override
  void didUpdateWidget(EmergencyRadarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startAnimation();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  void _startAnimation() {
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    return CustomPaint(
      painter: _PulseRadarPainter(_controller, widget.color),
      child: const SizedBox(
        width: 320,
        height: 320,
      ),
    );
  }
}

class _PulseRadarPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _PulseRadarPainter(this.animation, this.color) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // 3 Rings expanding smoothly
    for (int i = 0; i < 3; i++) {
      final double startValues = i * 0.33;
      final double progress = (animation.value + startValues) % 1.0;
      final double radius = maxRadius * progress;
      final double opacity = (1.0 - progress).clamp(0.0, 1.0);

      if (opacity > 0) {
        final paint = Paint()
          ..color = color.withValues(alpha: opacity * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PulseRadarPainter oldDelegate) => true;
}
