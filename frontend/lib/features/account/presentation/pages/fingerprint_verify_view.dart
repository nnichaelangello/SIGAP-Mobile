import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

class FingerprintVerifyView extends StatelessWidget {
  final String verifyState; // idle, scanning, success, failed
  final int failedAttempts;
  final Animation<double> pulseAnimation;
  final Animation<double> successScaleAnimation;
  final Animation<double> shakeAnimation;
  final VoidCallback onStartVerification;
  final VoidCallback onBack;

  const FingerprintVerifyView({
    super.key,
    required this.verifyState,
    required this.failedAttempts,
    required this.pulseAnimation,
    required this.successScaleAnimation,
    required this.shakeAnimation,
    required this.onStartVerification,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: shakeAnimation,
          builder: (context, child) {
            // Shake effect - horizontal movement using Sine Wave
            final double shakeOffset;
            if (verifyState == 'failed') {
              shakeOffset = 15.0 * math.sin(shakeAnimation.value * math.pi * 3);
            } else {
              shakeOffset = 0.0;
            }
            return Transform.translate(
              offset: Offset(shakeOffset, 0),
              child: child,
            );
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Bar Custom (Fixed positioning via visual ordering)
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 16.0, bottom: 0),
                              child: IconButton(
                                onPressed: onBack,
                                icon: const Icon(Icons.arrow_back_rounded),
                                iconSize: 24,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),

                          const Spacer(), // Push content to center

                          // KONTEN UTAMA
                          _buildMainContent(),

                          const Spacer(), // Push content to center

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title (Header)
        const Text(
          'VERIFIKASI SIDIK JARI',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 40),

        // ICON
        _buildFingerprintIcon(),

        const SizedBox(height: 40),

        // Status Text
        _buildTitle(),
        const SizedBox(height: 12),
        _buildSubtitle(),

        if (failedAttempts > 0 && verifyState != 'success')
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildAttemptsCounter(),
          ),

        const SizedBox(height: 48),

        // Buttons
        if (verifyState != 'success') _buildActionButton(),

        // Test button di-remove
      ],
    );
  }

  Widget _buildFingerprintIcon() {
    // Ukuran fix agar konsisten
    const double iconSize = 120.0;
    const double glowSize = iconSize * 1.33;
    const double ringSize = iconSize * 1.17;
    const double innerIconSize = iconSize * 0.47;

    final styles = _getFingerprintStyles();

    return AnimatedBuilder(
      animation: Listenable.merge([pulseAnimation, successScaleAnimation]),
      builder: (context, child) {
        final scale = verifyState == 'success'
            ? successScaleAnimation.value
            : (verifyState == 'scanning' ? pulseAnimation.value : 1.0);

        return Transform.scale(
          scale: verifyState == 'success' ? 1.0 : scale,
          child: SizedBox(
            width: glowSize,
            height: glowSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: glowSize,
                  height: glowSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: styles.glow
                            .withValues(alpha: verifyState == 'failed' ? 0.5 : 0.3),
                        blurRadius: verifyState == 'failed' ? 60 : 50,
                        spreadRadius: verifyState == 'failed' ? 15 : 10,
                      ),
                    ],
                  ),
                ),

                // Ring Scanning
                if (verifyState == 'scanning')
                  Container(
                    width: ringSize * pulseAnimation.value,
                    height: ringSize * pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.primaryColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),

                // Ring Error
                if (verifyState == 'failed')
                  Container(
                    width: ringSize * 1.0,
                    height: ringSize * 1.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                  ),

                // Main Circle Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: styles.bg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: styles.border,
                      width: verifyState == 'failed' ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: styles.glow.withValues(alpha: 0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: verifyState == 'success'
                      ? ScaleTransition(
                          scale: successScaleAnimation,
                          child: const Icon(Icons.check_rounded,
                              size: innerIconSize, color: Colors.white),
                        )
                      : verifyState == 'failed'
                          ? Icon(Icons.close_rounded,
                              size: innerIconSize, color: styles.icon)
                          : Icon(Icons.fingerprint_rounded,
                              size: innerIconSize, color: styles.icon),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Consolidated Style Logic ---
  ({Color glow, Color bg, Color border, Color icon}) _getFingerprintStyles() {
    switch (verifyState) {
      case 'success':
        return (
          glow: AppConstants.successColor,
          bg: AppConstants.successColor,
          border: AppConstants.successColor.withValues(alpha: 0.8),
          icon: Colors
              .white // Icon color unused in success state (uses check icon)
        );
      case 'failed':
        return (
          glow: AppConstants.errorColor,
          bg: AppConstants.errorColor.withValues(alpha: 0.1),
          border: AppConstants.errorColor.withValues(alpha: 0.8),
          icon: AppConstants.errorColor
        );
      default: // idle, scanning
        return (
          glow: AppConstants.primaryColor,
          bg: Colors.grey.shade50,
          border: verifyState == 'scanning'
              ? AppConstants.primaryColor
              : Colors.grey.shade200,
          icon: verifyState == 'scanning'
              ? AppConstants.primaryColor
              : Colors.grey.shade400
        );
    }
  }

  Widget _buildTitle() {
    String title;
    switch (verifyState) {
      case 'scanning':
        title = 'Memindai...';
        break;
      case 'success':
        title = 'Verifikasi Berhasil!';
        break;
      case 'failed':
        title = 'Verifikasi Gagal';
        break;
      default:
        title = 'Pindai Sidik Jari';
    }
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: verifyState == 'failed'
            ? Colors.red.shade600
            : verifyState == 'success'
                ? AppConstants.successColor
                : Colors.grey.shade900,
      ),
      child: Text(title),
    );
  }

  Widget _buildSubtitle() {
    String subtitle;
    switch (verifyState) {
      case 'scanning':
        subtitle = 'Letakkan jari Anda pada sensor...';
        break;
      case 'success':
        subtitle =
            'Identitas terverifikasi.\nMengarahkan ke halaman buat PIN baru...';
        break;
      case 'failed':
        subtitle =
            'Sidik jari tidak cocok dengan yang terdaftar.\nSilakan coba lagi.';
        break;
      default:
        subtitle =
            'Verifikasi identitas Anda untuk\nmelanjutkan proses reset PIN';
    }
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: TextStyle(
        fontSize: 15,
        color: verifyState == 'failed'
            ? Colors.red.shade400
            : Colors.grey.shade500,
        height: 1.6,
      ),
      child: Text(subtitle, textAlign: TextAlign.center),
    );
  }

  Widget _buildAttemptsCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: Colors.red.shade600),
          const SizedBox(width: 6),
          Text(
            '$failedAttempts percobaan gagal',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final isScanning = verifyState == 'scanning';
    final isFailed = verifyState == 'failed';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isScanning ? null : onStartVerification,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isFailed ? Colors.red.shade500 : AppConstants.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isScanning) ...[
              SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(Colors.grey.shade500))),
              const SizedBox(width: 12),
              Text('Memverifikasi...',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500)),
            ] else ...[
              Icon(isFailed ? Icons.refresh_rounded : Icons.fingerprint_rounded,
                  size: 22),
              const SizedBox(width: 10),
              Text(isFailed ? 'Coba Lagi' : 'Mulai Verifikasi',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
