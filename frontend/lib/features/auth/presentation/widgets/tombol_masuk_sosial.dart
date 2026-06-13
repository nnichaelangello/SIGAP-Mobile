import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Tombol masuk melalui pihak ketiga (Google & Microsoft).
///
/// Layout horizontal agar hemat ruang vertikal.
/// Dipakai di masuk_page dan daftar_page.
class TombolMasukSosial extends StatelessWidget {
  final VoidCallback onKetukGoogle;
  final VoidCallback onKetukMicrosoft;

  const TombolMasukSosial({
    super.key,
    required this.onKetukGoogle,
    required this.onKetukMicrosoft,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TombolItem(
            onKetuk: onKetukGoogle,
            label: 'Google',
            ikon: _bangunIkonGoogle(),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _TombolItem(
            onKetuk: onKetukMicrosoft,
            label: 'Microsoft',
            ikon: _bangunIkonMicrosoft(),
          ),
        ),
      ],
    );
  }

  /// Huruf "G" biru — identik Google tanpa perlu aset SVG.
  Widget _bangunIkonGoogle() {
    return Text(
      'G',
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF4285F4), // Google Blue — bukan warna SIGAP
      ),
    );
  }

  /// Logo 4-kotak Microsoft — warna resmi brand, bukan SIGAP.
  Widget _bangunIkonMicrosoft() => const _IkonMicrosoft();
}

/// Ikon Microsoft 4-kotak — const widget untuk optimalisasi rebuild.
class _IkonMicrosoft extends StatelessWidget {
  static const _ukuran = 7.0;
  static const _jarak = 1.5;

  const _IkonMicrosoft();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: _ukuran * 2 + _jarak,
      height: _ukuran * 2 + _jarak,
      child: Column(children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          _Kotak(Color(0xFFF25022)),
          SizedBox(width: _jarak),
          _Kotak(Color(0xFF7FBA00)),
        ]),
        SizedBox(height: _jarak),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _Kotak(Color(0xFF00A4EF)),
          SizedBox(width: _jarak),
          _Kotak(Color(0xFFFFB900)),
        ]),
      ]),
    );
  }
}

/// Kotak warna tunggal untuk logo Microsoft.
class _Kotak extends StatelessWidget {
  final Color warna;
  const _Kotak(this.warna);

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 7, height: 7, child: ColoredBox(color: warna));
}

/// Tombol outlined tunggal — ikon kiri + teks.
class _TombolItem extends StatelessWidget {
  final VoidCallback onKetuk;
  final String label;
  final Widget ikon;

  const _TombolItem({
    required this.onKetuk,
    required this.label,
    required this.ikon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onKetuk,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.textDark,
          side: BorderSide(color: Colors.grey.shade200, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ikon,
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
