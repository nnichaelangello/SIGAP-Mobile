import 'dart:ui';
import 'package:flutter/material.dart';

/// Extension untuk memberikan efek blur pada widget apapun.
/// Digunakan untuk efek Glassmorphism (glow blobs, lens flare).
extension BlurExtension on Widget {
  Widget blurred({double blur = 20}) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: this,
    );
  }
}
