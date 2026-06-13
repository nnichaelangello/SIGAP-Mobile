import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/features/app_shell/presentation/pages/auth_check_screen.dart';

/// Link "Mode Pengembangan" — dipakai di masuk_page dan daftar_page.
///
/// Shortcut bypass untuk mempercepat testing saat backend
/// belum terhubung. Navigasi ke AuthCheckScreen (pilih peran dev).
class LinkModePengembangan extends StatelessWidget {
  const LinkModePengembangan({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _navigasi(context),
        icon: Icon(Icons.developer_mode_rounded,
            size: 16, color: Colors.grey.shade400),
        label: Text(
          'Mode Pengembangan',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),
    );
  }

  void _navigasi(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthCheckScreen(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
