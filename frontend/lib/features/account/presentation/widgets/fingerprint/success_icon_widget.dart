import 'package:flutter/material.dart';

/// Success checkmark icon with glow effect
class SuccessIconWidget extends StatelessWidget {
  const SuccessIconWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Ring
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade100, width: 2),
            ),
          ),
          // Glow
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.15),
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
            child: Icon(Icons.check_circle_outline_rounded,
                size: 80, color: Colors.green.shade500),
          ),
        ],
      ),
    );
  }
}
