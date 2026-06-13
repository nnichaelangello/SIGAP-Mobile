import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Login prompt view shown when user is not logged in
class LoginPromptView extends StatelessWidget {
  final AnimationController shakeController;
  final bool showLoginPrompt;
  final VoidCallback onLoginPressed;

  const LoginPromptView({
    super.key,
    required this.shakeController,
    required this.showLoginPrompt,
    required this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Icon(Icons.shield_outlined,
                  size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              'Akses Terbatas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda harus login terlebih dahulu\nuntuk mengakses pengaturan keamanan',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade500, height: 1.5),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: shakeController,
              builder: (context, child) {
                final shake = Tween(begin: 0.0, end: 1.0)
                    .chain(CurveTween(curve: Curves.elasticIn))
                    .evaluate(shakeController);
                return Transform.translate(
                  offset: Offset(10 * shake * (shake > 0.5 ? -1 : 1), 0),
                  child: child,
                );
              },
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onLoginPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Masuk atau Daftar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            if (showLoginPrompt) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Text(
                      'Silakan login terlebih dahulu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
