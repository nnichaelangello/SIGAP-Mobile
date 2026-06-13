import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Widget header perisai dengan animasi gelombang Radar.
/// Ukuran responsif berdasarkan lebar layar.
class PantauHeader extends StatelessWidget {
  final AnimationController pulseController;

  const PantauHeader({
    super.key,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final lebarLayar = MediaQuery.of(context).size.width;
    // Ukuran shield responsif: HP kecil=96, HP biasa=120, Tablet=128
    final ukuranShield =
        lebarLayar < 380 ? 96.0 : (lebarLayar < 600 ? 120.0 : 128.0);
    final ukuranIcon = ukuranShield * 0.45;
    final ukuranOuter = ukuranShield * 1.25;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          // Area icon perisai dengan Radar Animation
          SizedBox(
            width: ukuranOuter,
            height: ukuranOuter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Gelombang Radar (CustomPainter)
                CustomPaint(
                  size: Size(ukuranOuter, ukuranOuter),
                  painter: _RadarPulsePainter(
                    animation: pulseController,
                    color: AppConstants.primaryColor,
                    baseRadius: ukuranShield / 2,
                    maxRadius: ukuranOuter / 2,
                  ),
                ),

                // Inner circle + icon statis
                Container(
                  width: ukuranShield,
                  height: ukuranShield,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppConstants.primaryColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    size: ukuranIcon,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Sistem Siaga Aktif',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppConstants.textDark,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tentukan interval waktu untuk konfirmasi keamanan Anda secara berkala.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppConstants.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter untuk menggambar riak gelombang (ripple effect)
class _RadarPulsePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final double baseRadius;
  final double maxRadius;

  _RadarPulsePainter({
    required this.animation,
    required this.color,
    required this.baseRadius,
    required this.maxRadius,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final expandDistance = maxRadius - baseRadius;

    for (int i = 0; i < 2; i++) {
      double progress = (animation.value + (i * 0.5)) % 1.0;
      final radius = baseRadius + (expandDistance * progress);
      final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.4;

      if (opacity > 0) {
        final paint = Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, radius, paint);

        final paintFill = Paint()
          ..color = color.withValues(alpha: opacity * 0.15)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, radius, paintFill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPulsePainter oldDelegate) => true;
}
