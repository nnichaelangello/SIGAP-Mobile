import 'package:flutter/material.dart';

/// Model data untuk setiap slide onboarding.
/// [gambarPath] opsional — jika null, widget akan render ilustrasi icon.
/// [alignmentGambar] mengatur posisi crop gambar (default: tengah).
class OnboardingItem {
  final String? gambarPath;
  final IconData ikonFallback;
  final String judul;
  final String deskripsi;
  final Color warnaAksen;
  final Alignment alignmentGambar;

  const OnboardingItem({
    this.gambarPath,
    required this.ikonFallback,
    required this.judul,
    required this.deskripsi,
    required this.warnaAksen,
    this.alignmentGambar = Alignment.center,
  });

  /// Cek apakah slide ini pakai gambar asset
  bool get pakaiGambar => gambarPath != null;
}

/// Daftar konten slide onboarding.
const daftarOnboarding = [
  OnboardingItem(
    gambarPath: 'assets/images/onboarding/onboarding_1.png',
    ikonFallback: Icons.shield_rounded,
    judul: 'Selamat datang di SIGAP',
    deskripsi: 'Aplikasi yang memeluk keberanianmu, mengubah setiap cerita '
        'menjadi langkah nyata yang terdukung.',
    warnaAksen: Color(0xFF7BA8DC),
    alignmentGambar: Alignment(0.35, 0),
  ),
  OnboardingItem(
    gambarPath: 'assets/images/onboarding/onboarding_2.png',
    ikonFallback: Icons.shield_rounded,
    judul: 'Laporkan dengan Aman',
    deskripsi: 'Sampaikan laporan secara rahasia dengan perlindungan identitas '
        'dan proses yang terjaga.',
    warnaAksen: Color(0xFF5B9BD5),
    alignmentGambar: Alignment(0.45, 0),
  ),
  OnboardingItem(
    gambarPath: 'assets/images/onboarding/onboarding_3.png',
    ikonFallback: Icons.groups_rounded,
    judul: 'Didampingi dengan Nyata',
    deskripsi: 'Laporanmu tidak berhenti di sistem. Tim terkait akan '
        'menindaklanjuti dan mendampingimu dengan aman, '
        'profesional, dan penuh kepedulian.',
    warnaAksen: Color(0xFF4A90D9),
    alignmentGambar: Alignment(0.1, 0),
  ),
  OnboardingItem(
    gambarPath: 'assets/images/onboarding/onboarding_4.png',
    ikonFallback: Icons.volunteer_activism_rounded,
    judul: 'Bersama, Kita Lebih Kuat',
    deskripsi: 'SIGAP berdiri bersamamu untuk memastikan setiap langkah '
        'memiliki arah dan perlindungan.',
    warnaAksen: Color(0xFF3F7FC4),
    alignmentGambar: Alignment(-0.1, 0),
  ),
];
