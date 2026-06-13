import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/app_shell/presentation/pages/main_screen.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/pages/admin_lite_page.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/pages/psikolog_lite_page.dart';

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstants.primaryColor.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // Icon / Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    size: 80,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Akses Pengembangan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pilih status login untuk simulasi alur aplikasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppConstants.textSecondary,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                // Button: Sudah Login
                _buildPremiumButton(
                  context,
                  label: "Sudah Login",
                  icon: Icons.login_rounded,
                  color: AppConstants.primaryColor,
                  textColor: Colors.white,
                  onPressed: () {
                    // Masuk sebagai USER (isGuest default = false)
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const MainScreen(isGuest: false)),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Button: Belum Login
                _buildPremiumButton(
                  context,
                  label: "Belum Login",
                  icon: Icons.app_registration_rounded,
                  color: Colors.white,
                  textColor: AppConstants.primaryColor,
                  isOutlined: true,
                  onPressed: () {
                    // Masuk sebagai GUEST (isGuest = true)
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const MainScreen(isGuest: true)),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // ── Separator Satgas ──
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'atau masuk sebagai Satgas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),

                const SizedBox(height: 16),

                // Button: Masuk sebagai Admin
                _buildPremiumButton(
                  context,
                  label: 'Masuk sebagai Admin',
                  icon: Icons.admin_panel_settings_rounded,
                  color: AppConstants.urgentColor,
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminLitePage(userName: 'Dev'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Button: Masuk sebagai Psikolog
                _buildPremiumButton(
                  context,
                  label: 'Masuk sebagai Psikolog',
                  icon: Icons.psychology_rounded,
                  color: Colors.teal.shade600,
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PsikologLitePage(userName: 'Dev'),
                      ),
                    );
                  },
                ),

                const Spacer(),
                Text(
                  'Sigap Dev v0.1',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        boxShadow: isOutlined
            ? []
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0, // Disabled standard elevation for custom shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isOutlined
                ? BorderSide(
                    color: textColor.withValues(alpha: 0.5), width: 1.5)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
