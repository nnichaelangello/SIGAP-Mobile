import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Divider horizontal dengan teks di tengah — "atau masuk dengan".
///
/// Dipakai di masuk_page dan daftar_page.
class DividerAuth extends StatelessWidget {
  final String teks;
  const DividerAuth({super.key, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          teks,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
    ]);
  }
}

/// Tombol utama auth (Masuk / Daftar) — warna SIGAP primary.
///
/// Mengelola state loading internal agar parent lebih ringkas.
class TombolUtamaAuth extends StatelessWidget {
  final String label;
  final bool sedangMemuat;
  final VoidCallback? onTekan;

  const TombolUtamaAuth({
    super.key,
    required this.label,
    this.sedangMemuat = false,
    this.onTekan,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: sedangMemuat ? null : onTekan,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppConstants.primaryColor.withValues(alpha: 0.6),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: sedangMemuat
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
