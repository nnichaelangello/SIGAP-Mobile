import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/fingerprint/fingerprint_icon_widget.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/fingerprint/success_icon_widget.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/fingerprint/failed_icon_widget.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/fingerprint/confetti_overlay.dart';

/// Halaman Pengaturan Sidik Jari
/// Untuk mendaftarkan dan mengelola sidik jari pengguna
class FingerprintSetupPage extends StatefulWidget {
  const FingerprintSetupPage({super.key});

  @override
  State<FingerprintSetupPage> createState() => _FingerprintSetupPageState();
}

class _FingerprintSetupPageState extends State<FingerprintSetupPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _confettiController;

  // States: idle, scanning, success, failed
  String _currentState = 'idle';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _startScanning() {
    HapticFeedback.mediumImpact();
    setState(() => _currentState = 'scanning');

    // Simulasi scanning (random success/failed untuk demo)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final success = Random().nextBool();
        if (success) {
          _onSuccess();
        } else {
          _onFailed();
        }
      }
    });
  }

  void _onSuccess() {
    HapticFeedback.heavyImpact();
    setState(() => _currentState = 'success');
    _confettiController.forward();
  }

  void _onFailed() {
    HapticFeedback.vibrate();
    setState(() => _currentState = 'failed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildMainContent()),
              _buildFooter(),
            ],
          ),
          // Confetti overlay
          if (_currentState == 'success')
            ConfettiOverlay(controller: _confettiController),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: _currentState == 'success'
          ? const SizedBox.shrink()
          : IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 24,
                color: _currentState == 'failed'
                    ? Colors.red.shade400
                    : Colors.grey.shade800,
              ),
            ),
      title: Text(
        'SIDIK JARI',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon based on state
            _buildStateIcon(),
            const SizedBox(height: 40),
            // Title & Description
            _buildStateContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStateIcon() {
    switch (_currentState) {
      case 'success':
        return const SuccessIconWidget();
      case 'failed':
        return FailedIconWidget(pulseAnimation: _pulseController);
      default:
        return FingerprintIconWidget(
          pulseAnimation: _pulseController,
          isScanning: _currentState == 'scanning',
        );
    }
  }

  Widget _buildStateContent() {
    switch (_currentState) {
      case 'scanning':
        return _buildTextContent(
          title: 'Memindai...',
          subtitle: 'Tahan jari Anda pada sensor',
        );
      case 'success':
        return _buildTextContent(
          title: 'Sidik Jari Berhasil Terdaftar',
          subtitle:
              'Otentikasi biometrik Anda kini aktif untuk mengamankan data privat.',
        );
      case 'failed':
        return _buildTextContent(
          title: 'Pemindaian Gagal',
          subtitle:
              'Sensor tidak dapat mengenali jari Anda. Pastikan sensor bersih dan coba lagi.',
          isError: true,
        );
      default:
        return _buildTextContent(
          title: 'Daftarkan Sidik Jari',
          subtitle:
              'Gunakan otentikasi biometrik untuk akses cepat dan aman ke data privat Anda',
        );
    }
  }

  Widget _buildTextContent({
    required String title,
    required String subtitle,
    bool isError = false,
  }) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade500,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 48),
      child: Column(
        children: [
          if (_currentState == 'success') ...[
            _buildPrimaryButton(
              label: 'Selesai',
              onTap: () => Navigator.pop(context),
              isPrimary: true,
            ),
          ] else if (_currentState == 'failed') ...[
            _buildPrimaryButton(
              label: 'Coba Lagi',
              icon: Icons.refresh_rounded,
              onTap: _startScanning,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Gunakan Metode Lain',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ] else ...[
            _buildScanButton(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Nanti Saja',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    final isScanning = _currentState == 'scanning';
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isScanning ? null : _startScanning,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isScanning
                    ? AppConstants.primaryColor.withValues(alpha: 0.5)
                    : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isScanning) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(AppConstants.primaryColor),
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.fingerprint_rounded,
                      color: AppConstants.primaryColor, size: 22),
                ],
                const SizedBox(width: 10),
                Text(
                  isScanning ? 'Memindai...' : 'Mulai Pemindaian',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? AppConstants.primaryColor
              : AppConstants.primaryColor.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: AppConstants.primaryColor.withValues(alpha: 0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
