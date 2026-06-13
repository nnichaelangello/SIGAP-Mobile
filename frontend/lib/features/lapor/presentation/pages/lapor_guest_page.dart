import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/app_shell/presentation/pages/auth_check_screen.dart';
// Note: Nanti arahkan ke login screen yang sebenarnya jika sudah ada,
// sementara kita arahkan ke AuthCheckScreen atau trigger callback login.

class LaporGuestPage extends StatelessWidget {
  const LaporGuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // --- HERO ANIMATION (GIF) ---
              // Menggunakan Container dengan rounded corners dan shadow subtle
              // untuk menghaluskan tampilan GIF yang mungkin backgroundnya kasar
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/animations/security_gate.gif',
                    height: 250,
                    fit: BoxFit.contain, // Pastikan proporsi terjaga
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // --- TYPEGRAPHY & MESSAGING ---
              const Text(
                "Akses Pelaporan Terproteksi",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Fitur Lapor adalah layanan vital yang membutuhkan verifikasi identitas untuk memastikan setiap laporan ditangani dengan serius dan aman.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppConstants.textSecondary,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // --- ACTION BUTTONS ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Login/Auth Screen
                    // Reset ke screen awal
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AuthCheckScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Masuk ke Akun Saya",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navigate to Register
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AuthCheckScreen()),
                  );
                },
                child: const Text(
                  "Belum punya akun? Daftar sekarang",
                  style: TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
