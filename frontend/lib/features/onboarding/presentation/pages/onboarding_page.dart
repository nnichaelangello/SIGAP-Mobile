import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/onboarding/data/onboarding_data.dart';
import 'package:sigap_mobile/features/onboarding/presentation/widgets/onboarding_indikator.dart';
import 'package:sigap_mobile/features/onboarding/presentation/widgets/onboarding_slide.dart';
import 'package:sigap_mobile/features/auth/presentation/pages/masuk_page.dart';
import 'package:sigap_mobile/features/auth/presentation/pages/daftar_page.dart';

/// Halaman onboarding — tampil pertama kali saat user membuka app.
///
/// Alur: Geser 3 slide → "Mulai Sekarang" → MasukPage (Login)
///                       → "Daftar dulu"    → DaftarPage (Register)
/// Referensi tata letak: Gojek onboarding (PageView + dot + CTA bawah).
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _kontrolerHalaman = PageController();
  int _halamanSaatIni = 0;

  // Animasi untuk tombol CTA agar muncul halus saat pertama render
  late final AnimationController _kontrolerAnimasi;
  late final Animation<double> _animasiMuncul;

  @override
  void initState() {
    super.initState();
    _kontrolerAnimasi = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animasiMuncul = CurvedAnimation(
      parent: _kontrolerAnimasi,
      curve: Curves.easeOut,
    );
    // Delay sedikit agar transisi dari splash terasa natural
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _kontrolerAnimasi.forward();
    });
  }

  @override
  void dispose() {
    _kontrolerHalaman.dispose();
    _kontrolerAnimasi.dispose();
    super.dispose();
  }

  /// Navigasi ke halaman masuk (login)
  void _navigasiKeMasuk() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MasukPage(),
        transitionsBuilder: (_, animasi, __, child) {
          return FadeTransition(opacity: animasi, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  /// Navigasi ke halaman daftar (register)
  void _navigasiKeDaftar() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DaftarPage(),
        transitionsBuilder: (_, animasi, __, child) {
          return FadeTransition(opacity: animasi, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Logo + Badge bahasa (mirip Gojek)
            _bangunHeader(),

            // Konten slide — PageView yang bisa diswipe
            Expanded(
              child: PageView.builder(
                controller: _kontrolerHalaman,
                itemCount: daftarOnboarding.length,
                onPageChanged: (index) {
                  setState(() => _halamanSaatIni = index);
                },
                itemBuilder: (context, index) {
                  return OnboardingSlide(item: daftarOnboarding[index]);
                },
              ),
            ),

            // Area bawah: Indikator + Tombol + Disclaimer
            FadeTransition(
              opacity: _animasiMuncul,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(_animasiMuncul),
                child: _bangunAreaBawah(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header atas: Logo SIGAP di kiri, badge bahasa di kanan
  Widget _bangunHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo SIGAP
          Image.asset(
            'assets/images/logo_sigap.png',
            height: 32,
            fit: BoxFit.contain,
          ),

          // Badge bahasa (dekorasi, belum fungsional)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.translate_rounded,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Bahasa Indonesia',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Area bawah: dot indikator, tombol CTA, disclaimer
  Widget _bangunAreaBawah() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot indikator
          OnboardingIndikator(
            jumlahHalaman: daftarOnboarding.length,
            halamanAktif: _halamanSaatIni,
            warnaAktif: daftarOnboarding[_halamanSaatIni].warnaAksen,
          ),

          const SizedBox(height: 32),

          // Tombol utama: Mulai Sekarang
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _navigasiKeMasuk,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Mulai Sekarang',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Tombol sekunder: Belum punya akun? Daftar dulu
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: _navigasiKeDaftar,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade800,
                side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text.rich(
                TextSpan(
                  text: 'Belum punya akun? ',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                  children: [
                    TextSpan(
                      text: 'Daftar dulu',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Disclaimer ketentuan layanan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text.rich(
              TextSpan(
                text: 'Dengan masuk atau mendaftar, kamu menyetujui ',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: 'Ketentuan layanan',
                    style: GoogleFonts.poppins(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: ' dan '),
                  TextSpan(
                    text: 'Kebijakan privasi',
                    style: GoogleFonts.poppins(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
