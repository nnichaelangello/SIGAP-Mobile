import 'package:flutter/material.dart';

/// Failed fingerprint icon with pulse animation
class FailedIconWidget extends StatelessWidget {
  final AnimationController pulseAnimation;

  const FailedIconWidget({super.key, required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse Ring
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.shade200
                        .withValues(alpha: 0.5 + (pulseAnimation.value * 0.3)),
                    width: 2,
                  ),
                ),
              );
            },
          ),
          // Glow
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.12),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Main Circle
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 24,
                    offset: const Offset(12, 12)),
                const BoxShadow(
                    color: Colors.white,
                    blurRadius: 24,
                    offset: Offset(-12, -12)),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.fingerprint_rounded,
                    size: 80, color: Colors.red.shade400),
                Positioned(
                  right: 35,
                  bottom: 35,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.error_rounded,
                        size: 28, color: Colors.red.shade500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
