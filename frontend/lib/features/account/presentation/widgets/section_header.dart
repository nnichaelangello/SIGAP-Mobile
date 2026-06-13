import 'package:flutter/material.dart';

/// Widget reusable untuk menampilkan header section dengan theme-aware styling
///
/// Digunakan di AccountPage dan GuestAccountPage untuk konsistensi UI.
///
/// Features:
/// - Theme-aware colors (mendukung light/dark mode)
/// - Accessibility support (semantic labels)
/// - Responsive sizing
/// - Customizable styling
///
/// Example:
/// ```dart
/// SectionHeader(title: 'Pengaturan Akun')
/// ```
class SectionHeader extends StatelessWidget {
  /// Judul section yang akan ditampilkan (akan diubah ke uppercase)
  final String title;

  /// Ukuran kecil untuk sub-section
  final bool isSmall;

  /// Custom text style (optional, akan di-merge dengan default style)
  final TextStyle? style;

  /// Custom padding (optional, default: horizontal 4)
  final EdgeInsetsGeometry? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.isSmall = false,
    this.style,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Default style dengan theme integration
    final defaultStyle = textTheme.labelSmall?.copyWith(
          fontSize: isSmall ? 10 : null,
          fontWeight: FontWeight.bold,
          color: isSmall
              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          letterSpacing: 1.5,
        ) ??
        TextStyle(
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        );

    return Semantics(
      header: true,
      label: 'Section: $title',
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          title.toUpperCase(),
          style: style != null ? defaultStyle.merge(style) : defaultStyle,
        ),
      ),
    );
  }
}
