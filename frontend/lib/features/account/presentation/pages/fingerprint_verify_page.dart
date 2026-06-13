import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/features/account/presentation/pages/create_pin_page.dart';
import 'package:sigap_mobile/features/account/presentation/pages/fingerprint_verify_view.dart';

/// Halaman Verifikasi Sidik Jari untuk Reset PIN
/// Berfungsi sebagai Logic Controller
class FingerprintVerifyPage extends StatefulWidget {
  const FingerprintVerifyPage({super.key});

  @override
  State<FingerprintVerifyPage> createState() => _FingerprintVerifyPageState();
}

class _FingerprintVerifyPageState extends State<FingerprintVerifyPage>
    with TickerProviderStateMixin {
  // State verifikasi
  String _verifyState = 'idle'; // idle, scanning, success, failed
  int _failedAttempts = 0;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _successController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for idle/scanning state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    ); // Removed .repeat() to save resources in idle state

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _successScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startVerification() {
    HapticFeedback.mediumImpact();
    // Start pulsing only when scanning
    _pulseController.repeat(reverse: true);
    setState(() => _verifyState = 'scanning');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Logika sederhana: percobaan pertama gagal, selanjutnya berhasil
        if (_failedAttempts < 1) {
          _onVerificationFailed();
        } else {
          _onVerificationSuccess();
        }
      }
    });
  }

  void _onVerificationSuccess() {
    HapticFeedback.heavyImpact();
    _pulseController.stop();
    setState(() => _verifyState = 'success');
    _successController.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CreatePinPage(),
          ),
        );
      }
    });
  }

  void _onVerificationFailed() {
    // Triple vibrate
    HapticFeedback.vibrate();
    Future.delayed(
        const Duration(milliseconds: 100), () => HapticFeedback.vibrate());
    Future.delayed(
        const Duration(milliseconds: 200), () => HapticFeedback.vibrate());

    _pulseController.stop();
    setState(() {
      _verifyState = 'failed';
      _failedAttempts++;
    });

    _shakeController.forward().then((_) => _shakeController.reset());
    _showErrorSnackbar();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _verifyState = 'idle');
        // Do NOT restart pulse here, wait for user action
      }
    });
  }

  void _showErrorSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verifikasi Gagal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sidik jari tidak cocok. Silakan coba lagi.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Memanggil UI Component yang terpisah
    return FingerprintVerifyView(
      verifyState: _verifyState,
      failedAttempts: _failedAttempts,
      pulseAnimation: _pulseAnimation,
      successScaleAnimation: _successScaleAnimation,
      shakeAnimation: _shakeAnimation,
      onStartVerification: _startVerification,
      onBack: () => Navigator.pop(context),
    );
  }
}
