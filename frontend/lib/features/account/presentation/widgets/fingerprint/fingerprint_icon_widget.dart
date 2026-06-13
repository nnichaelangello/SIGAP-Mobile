import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Fingerprint icon with pulse animation for idle/scanning states
class FingerprintIconWidget extends StatelessWidget {
  final AnimationController pulseAnimation;
  final bool isScanning;

  const FingerprintIconWidget({
    super.key,
    required this.pulseAnimation,
    required this.isScanning,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Pulse Ring
          if (isScanning)
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (pulseAnimation.value * 0.2),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.primaryColor
                            .withValues(alpha: 0.3 - (pulseAnimation.value * 0.2)),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          // Glow Background
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor
                      .withValues(alpha: isScanning ? 0.25 : 0.1),
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
            child: Icon(
              Icons.fingerprint_rounded,
              size: 96,
              color: isScanning
                  ? AppConstants.primaryColor
                  : AppConstants.primaryColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
