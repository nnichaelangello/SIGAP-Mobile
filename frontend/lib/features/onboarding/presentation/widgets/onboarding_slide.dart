import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/features/onboarding/data/onboarding_data.dart';

/// Widget untuk satu slide onboarding.
/// Layout mengikuti pola Gojek: gambar rounded di tengah, teks rapat di bawah.
/// Font menggunakan Poppins agar tipografi terasa hidup dan modern.
class OnboardingSlide extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingSlide({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final ukuranLayar = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          // Ruang atas — fleksibel, bisa menyusut kalau layar kecil
          const Flexible(flex: 2, child: SizedBox(height: double.infinity)),

          // Area ilustrasi
          item.pakaiGambar
              ? _bangunGambarAsset(ukuranLayar)
              : _bangunIlustrasiIcon(ukuranLayar),

          // Jarak gambar ke teks
          const SizedBox(height: 16),

          // Judul slide
          Text(
            item.judul,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
              height: 1.25,
            ),
          ),

          const SizedBox(height: 12),

          // Deskripsi slide
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              item.deskripsi,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
          ),

          // Ruang bawah — fleksibel, bisa menyusut
          const Flexible(flex: 1, child: SizedBox(height: double.infinity)),
        ],
      ),
    );
  }

  /// Gambar asset dengan rounded rectangle besar (mirip Gojek).
  Widget _bangunGambarAsset(Size ukuranLayar) {
    return Container(
      width: double.infinity,
      height: ukuranLayar.height * 0.28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Image.asset(
          item.gambarPath!,
          fit: BoxFit.cover,
          alignment: item.alignmentGambar,
        ),
      ),
    );
  }

  /// Fallback: ilustrasi lingkaran bertumpuk + icon.
  Widget _bangunIlustrasiIcon(Size ukuranLayar) {
    final double ukuranLuar = ukuranLayar.width * 0.42;
    final double ukuranTengah = ukuranLuar * 0.75;
    final double ukuranInti = ukuranTengah * 0.7;

    return SizedBox(
      width: ukuranLuar,
      height: ukuranLuar,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: ukuranLuar,
            height: ukuranLuar,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.warnaAksen.withValues(alpha: 0.08),
            ),
          ),
          Container(
            width: ukuranTengah,
            height: ukuranTengah,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.warnaAksen.withValues(alpha: 0.15),
            ),
          ),
          Container(
            width: ukuranInti,
            height: ukuranInti,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.warnaAksen,
                  item.warnaAksen.withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: item.warnaAksen.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Icon(
              item.ikonFallback,
              size: ukuranInti * 0.45,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
