import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// AppBar chat premium — Hero avatar + online status indicator.
/// Dipindahkan dari inline _buildAppBar() di chat_page.dart.
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Animation controllers dipassing dari page-level karena
  /// animasi entry harus disinkron dengan body content.
  final Animation<double> headerFadeAnimation;
  final Animation<Offset> headerSlideAnimation;

  const ChatAppBar({
    super.key,
    required this.headerFadeAnimation,
    required this.headerSlideAnimation,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: SlideTransition(
        position: headerSlideAnimation,
        child: FadeTransition(
          opacity: headerFadeAnimation,
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.grey.shade700, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: Row(
        children: [
          Hero(
            tag: 'chatbot_avatar',
            flightShuttleBuilder:
                (flightContext, animation, direction, fromContext, toContext) {
              return FadeTransition(
                opacity: animation,
                child: _buildAvatar(),
              );
            },
            child: _buildAvatar(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SlideTransition(
              position: headerSlideAnimation,
              child: FadeTransition(
                opacity: headerFadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TemanKu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Aktif - Siap Mendengarkan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        SlideTransition(
          position: headerSlideAnimation,
          child: FadeTransition(
            opacity: headerFadeAnimation,
            child: IconButton(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade600),
              onPressed: () {},
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade100, height: 1),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/chatbot_avatar.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
            child: const Icon(Icons.smart_toy_rounded,
                color: AppConstants.primaryColor, size: 24),
          ),
        ),
      ),
    );
  }
}
