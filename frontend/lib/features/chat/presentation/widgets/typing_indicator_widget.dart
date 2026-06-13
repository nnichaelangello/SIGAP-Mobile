import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Animasi titik-titik bergerak saat bot sedang mengetik.
/// Dipindahkan dari inline _TypingDots di chat_page.dart.
class TypingDotsWidget extends StatelessWidget {
  const TypingDotsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 200)),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            final bounce = (0.5 - (value - 0.5).abs()) * 2;
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              transform: Matrix4.translationValues(0, -3 * bounce, 0),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor
                    .withValues(alpha: 0.4 + (bounce * 0.6)),
                shape: BoxShape.circle,
              ),
            );
          },
          onEnd: () {},
        );
      }),
    );
  }
}

/// Widget indicator typing bot dengan avatar.
class ChatTypingIndicator extends StatelessWidget {
  const ChatTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            child: ClipOval(
              child: Image.asset(
                'assets/images/chatbot_avatar.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.primaryColor,
                        AppConstants.primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const TypingDotsWidget(),
          ),
        ],
      ),
    );
  }
}
