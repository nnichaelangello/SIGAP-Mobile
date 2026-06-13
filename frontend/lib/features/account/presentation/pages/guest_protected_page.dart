import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Halaman Tamu Terproteksi (The Guest Gate)
///
/// Halaman ini muncul ketika user tamu (Guest) mencoba mengakses fitur-fitur sensitif:
/// - Detail Akun
/// - Key Management
/// - Sandi & Keamanan
///
/// UX Goals:
/// - Mengubah frustrasi "Access Denied" menjadi motivasi "Join Now".
/// - Menggunakan animasi premium untuk trust.
/// - Layout yang focus pada konversi (Login/Register).
class GuestProtectedPage extends StatelessWidget {
  final String featureName;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onRegisterPressed;

  const GuestProtectedPage({
    super.key,
    this.featureName = "Fitur Keamanan",
    this.onLoginPressed,
    this.onRegisterPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Tema warna khusus untuk halaman gate (Clean & Secure look)
    const Color bgSurface = Colors.white;
    const Color textPrimary = Color(0xFF1F2937); // Dark Blue-Grey
    const Color textSecondary = Color(0xFF6B7280); // Soft Grey

    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: textPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Layout menggunakan Stack untuk visual yang kaya
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              // --- 1. THE HERO ANIMATION ---
              // GIF diletakkan dengan shadow halus di bawahnya untuk depth (Deep UI)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryColor.withValues(alpha: 0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/animations/guest_gate.gif',
                    height: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // --- 2. COMPELLING COPYWRITING ---
              const Text(
                "Akses Terbatas",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Untuk mengakses $featureName, sistem memerlukan verifikasi identitas Anda.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Keamanan data adalah prioritas kami.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryColor,
                ),
              ),

              const Spacer(flex: 2),

              // --- 3. HIGH CONVERSION BUTTONS ---
              // Primary Action: Masuk (Login)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onLoginPressed ??
                      () {
                        // Default navigation to login
                        // Navigator.pushNamed(context, '/login');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Navigasi ke Login Page...')),
                        );
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor:
                        AppConstants.primaryColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Masuk ke Akun",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Secondary Action: Daftar (Register)
              // Desain outline agar hirarki visual jelas
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: onRegisterPressed ??
                      () {
                        // Default navigation to register
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Navigasi ke Register Page...')),
                        );
                      },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side:
                        const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Saya Belum Punya Akun",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
