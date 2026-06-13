import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/core/services/api_service.dart';
import 'package:sigap_mobile/features/pantau/data/kontak_darurat_data.dart';
import 'package:sigap_mobile/features/pantau/presentation/pages/aman_pasca_trigger_page.dart';
import 'package:sigap_mobile/features/lapor/services/emergency_audio_service.dart';

/// Layar pemberitahuan Bantuan Terkirim.
/// Layar ini berfokus pada ketenangan dan rasa aman.
class TriggerSentPage extends StatefulWidget {
  const TriggerSentPage({super.key});

  @override
  State<TriggerSentPage> createState() => _TriggerSentPageState();
}

class _TriggerSentPageState extends State<TriggerSentPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final bool _adaKoneksiInternet = true;
  final String _lokasiTersegel = "Sistem secara otomatis melacak koordinat GPS terakhir Anda secara presisi.";
  final DateTime _waktuTrigger = DateTime.now();

  // State untuk proses pengiriman "Aku Aman"
  bool _isSendingAman = false;

  @override
  void initState() {
    super.initState();
    // Menggunakan duration 1000ms agar stagger yang dimulai pada 600ms
    // masih memiliki durasi 400ms untuk berjalan hingga selesai
    // (Jika pakai 600ms total, elemen yang di-stagger 600ms menjadi instan 0ms).
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _hitungPaddingH(double lebarLayar) {
    if (lebarLayar <= 480) return 24.0;
    return ((lebarLayar - 430) / 2).clamp(24.0, 120.0);
  }

  String _formatWaktu(DateTime dt) {
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return "$jam:$menit WIB";
  }

  @override
  Widget build(BuildContext context) {
    final lebarLayar = MediaQuery.of(context).size.width;
    final paddingH = _hitungPaddingH(lebarLayar);

    return PopScope(
      canPop: false, // Memblokir swipe-back dan hardware back button
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false, // TIdak ada tombol back
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            'Bantuan Dihubungi',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textDark,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      EdgeInsets.symmetric(horizontal: paddingH, vertical: 32),
                  child: Column(
                    children: [
                      // Section 1: Header (Icon & Teks)
                      _bangunHeader(),

                      const SizedBox(height: 32),

                      // Section 2: Banner Pengiriman
                      _bangunBannerPengiriman(),

                      const SizedBox(height: 32),

                      // Section 3: Daftar Kontak
                      _bangunDaftarKontak(),

                      const SizedBox(height: 32),

                      // Section 4: Lokasi Tersegel
                      _bangunLokasiTersegel(),
                    ],
                  ),
                ),
              ),
              // Section 5: Buttons
              _bangunTombolBawah(paddingH),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bangunHeader() {
    // Icon centang scale in: 0ms -> 400ms (0.0 -> 0.40)
    final iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
      ),
    );

    // Teks header fade + slide: 150ms -> 550ms (0.15 -> 0.55)
    final textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
      ),
    );

    final textSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
      ),
    );

    return Column(
      children: [
        ScaleTransition(
          scale: iconScale,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.successColor.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 36,
              color: AppConstants.successColor,
            ),
          ),
        ),
        const SizedBox(height: 24),
        FadeTransition(
          opacity: textFade,
          child: SlideTransition(
            position: textSlide,
            child: Column(
              children: [
                Text(
                  'Pesan Darurat Terkirim',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kontak daruratmu sedang dihubungi',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppConstants.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bangunBannerPengiriman() {
    // Banner fade in: 300ms -> 700ms (0.30 -> 0.70)
    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.70, curve: Curves.easeOut),
      ),
    );

    final colorBg =
        _adaKoneksiInternet ? const Color(0xFFE3F2FD) : const Color(0xFFFFF8E1);
    final iconData =
        _adaKoneksiInternet ? Icons.wifi_rounded : Icons.sms_rounded;
    final textStr = _adaKoneksiInternet
        ? "Dikirim via WhatsApp"
        : "Internet tidak tersedia — dikirim via SMS";
    final fgColor =
        _adaKoneksiInternet ? const Color(0xFF1976D2) : const Color(0xFFF57C00);

    return FadeTransition(
      opacity: fade,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 18, color: fgColor),
            const SizedBox(width: 8),
            Text(
              textStr,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bangunDaftarKontak() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
            ),
          ),
          child: Text(
            'Dikirim ke:',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppConstants.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(daftarKontakDarurat.length, (i) {
          final kontak = daftarKontakDarurat[i];

          // Stagger card timing:
          // Card 1: 400ms (0.40)
          // Card 2: 500ms (0.50)
          // Card 3: 600ms (0.60)
          // Masing-masing durasi 400ms.
          final startDelay = 0.40 + (0.10 * i);
          final endDelay = (startDelay + 0.40).clamp(0.0, 1.0);

          final cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(startDelay, endDelay, curve: Curves.easeOut),
            ),
          );
          final cardSlide =
              Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
                  .animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(startDelay, endDelay, curve: Curves.easeOut),
            ),
          );

          return FadeTransition(
            opacity: cardFade,
            child: SlideTransition(
              position: cardSlide,
              child: _bangunCardKontak(kontak),
            ),
          );
        }),
      ],
    );
  }

  Widget _bangunCardKontak(KontakDarurat kontak) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: kontak.warnaAvatar.withValues(alpha: 0.15),
            radius: 20,
            child: Text(
              kontak.inisial,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: kontak.warnaAvatar,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kontak.nama,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textDark,
                  ),
                ),
                Text(
                  kontak.nomorHp,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _adaKoneksiInternet
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _adaKoneksiInternet ? "WA \u2713" : "SMS \u2713",
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _adaKoneksiInternet
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFF57C00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunLokasiTersegel() {
    // Fade in akhir, misal dari 600ms -> 1000ms (0.60 -> 1.0)
    final locFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: locFade,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5), // Merah sangat pudar
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            left: BorderSide(
                color: Color(0xFFCC0000), width: 3), // Kiri merah tebal
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: Color(0xFFCC0000),
                ),
                const SizedBox(width: 6),
                Text(
                  'Lokasi Tersegel',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFCC0000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _lokasiTersegel,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppConstants.textDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              _formatWaktu(_waktuTrigger),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bukti forensik tersimpan di perangkat',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bangunTombolBawah(double paddingH) {
    // Tombol muncul mulus setelah semua konten dirender
    final buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: buttonFade,
      child: Container(
        padding: EdgeInsets.fromLTRB(paddingH, 16, paddingH, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSendingAman ? null : _prosesAman,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.successColor,
                  disabledBackgroundColor:
                      AppConstants.successColor.withValues(alpha: 0.6),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSendingAman
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Mengirim konfirmasi...',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Aku Sudah Aman',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Tidak melakukan apa-apa: tetap di layar ini.
              },
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.textSecondary,
              ),
              child: Text(
                'Tetap di sini',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _prosesAman() async {
    setState(() {
      _isSendingAman = true;
    });

    // Resolve incident di backend
    await ApiService.instance.post('/api/emergency/resolve', {});
    
    // Hentikan perekaman audio
    EmergencyAudioService.instance.stopRecording();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AmanPascaTriggerPage(),
      ),
    );
  }
}
