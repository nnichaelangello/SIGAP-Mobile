import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tombol icon animasi dengan efek scale saat tap.
/// Dipindahkan dari inline _AnimatedIconButton di chat_page.dart.
/// Reusable — bisa dipakai di fitur lain.
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final bool isGradient;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    required this.backgroundColor,
    required this.iconColor,
    this.isGradient = false,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _onTapDown : null,
      onTapUp: widget.onPressed != null ? _onTapUp : null,
      onTapCancel: widget.onPressed != null ? _onTapCancel : null,
      onTap: () {
        widget.onPressed?.call();
        HapticFeedback.lightImpact();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: widget.isGradient
                ? LinearGradient(
                    colors: [
                      widget.backgroundColor,
                      widget.backgroundColor.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            color: widget.isGradient ? null : widget.backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            color: widget.iconColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}
