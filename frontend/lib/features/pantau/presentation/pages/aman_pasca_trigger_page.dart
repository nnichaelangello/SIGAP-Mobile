import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/pantau/data/kontak_darurat_data.dart';
import 'package:sigap_mobile/features/chat/presentation/pages/chat_welcome_page.dart';
import 'package:sigap_mobile/features/lapor/presentation/pages/lapor_isu_page.dart';
import 'package:sigap_mobile/features/lapor/data/datasources/report_remote_data_source.dart';
import 'package:sigap_mobile/features/lapor/data/repositories/report_repository_impl.dart';
import 'package:sigap_mobile/features/lapor/domain/usecases/submit_report_usecase.dart';
import 'package:sigap_mobile/features/lapor/presentation/provider/lapor_isu_provider.dart';

/// Layar Aman Pasca Trigger (Clean UI & Trauma-Informed UX).
/// Fokus pada kejelasan, ketenangan (tanpa animasi berlebihan), dan hierarki visual tegas.
class AmanPascaTriggerPage extends StatefulWidget {
  const AmanPascaTriggerPage({super.key});

  @override
  State<AmanPascaTriggerPage> createState() => _AmanPascaTriggerPageState();
}

class _AmanPascaTriggerPageState extends State<AmanPascaTriggerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  final DateTime _waktuAman = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Animasi masuk yang sangat halus dan linear
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  String _formatWaktu(DateTime dt) {
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return "$jam:$menit WIB";
  }

  void _navigasiKeChatbot() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ChatWelcomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigasiKeLaporIsu() {
    final remoteDataSource = ReportRemoteDataSourceImpl(client: http.Client());
    final repository = ReportRepositoryImpl(remoteDataSource: remoteDataSource);
    final submitUseCase = SubmitReportUseCase(repository);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ChangeNotifierProvider(
            create: (_) => LaporIsuProvider(submitUseCase: submitUseCase),
            child: const LaporIsuPage(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _bangunHeroVisual(),
                          const SizedBox(height: 32),
                          _bangunKotakStatus(),
                          const SizedBox(height: 24),
                          _bangunPesanValidasi(),
                          const SizedBox(height: 32),
                          _bangunMenuLanjutan(),
                          const SizedBox(height: 48), // Bottom padding spacing
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              _bangunSelesaiBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // --- KOMPONEN UI ---

  Widget _bangunHeroVisual() {
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE6F4EA), // Soft Green
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 40,
              color: Color(0xFF137333), // Solid darker green
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Kondisi Aman',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B), // Slate 800
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Tercatat pada ${_formatWaktu(_waktuAman)}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B), // Slate 500
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _bangunKotakStatus() {
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.2, 0.7, curve: Curves.easeOut)),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _entranceController,
                curve: const Interval(0.2, 0.7, curve: Curves.easeOut))),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), // Slate 50
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: Color(0xFF334155), // Slate 700
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sinyal darurat berhasil dikirim. Mereka telah mengetahui lokasimu.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 16),
              Text(
                'Terkirim ke:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: daftarKontakDarurat.map((kontak) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFCBD5E1)), // Slate 300
                    ),
                    child: Text(
                      kontak.nama,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bangunPesanValidasi() {
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.4, 0.9, curve: Curves.easeOut)),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _entranceController,
                curve: const Interval(0.4, 0.9, curve: Curves.easeOut))),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB), // Amber 50
            borderRadius: BorderRadius.circular(12),
            border: const Border(
              left: BorderSide(color: Color(0xFFF59E0B), width: 4), // Amber 500
            ),
          ),
          child: Text(
            'Reaksimu tadi sangat valid. Mengaktifkan fitur ini berarti kamu memprioritaskan keselamatanmu, dan itu pilihan yang tepat.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF92400E), // Amber 900
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bangunMenuLanjutan() {
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Langkah Selanjutnya (Opsional)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          _OpsiCard(
            title: 'Ceritakan Padaku',
            subtitle: 'Legakan pikiran dengan TemanKu AI tanpa dihakimi.',
            icon: Icons.chat_bubble_outline_rounded,
            accentColor: const Color(0xFF6366F1), // Indigo 500
            onTap: _navigasiKeChatbot,
          ),
          const SizedBox(height: 12),
          _OpsiCard(
            title: 'Buat Laporan',
            subtitle: 'Catat detil kejadian jika merasa ada ancaman serius.',
            icon: Icons.edit_note_rounded,
            accentColor: const Color(0xFF2563EB), // Blue 600
            onTap: _navigasiKeLaporIsu,
          ),
        ],
      ),
    );
  }

  Widget _bangunSelesaiBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))), // Slate 100
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                // Selesaikan flow dan kembali ke Home (atau root screen)
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Tutup Layar Ini',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sesi tercatat di Riwayat Layanan',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF94A3B8), // Slate 400
            ),
          ),
        ],
      ),
    );
  }
}

/// Card flat dan clean untuk memandu UX yang jelas.
class _OpsiCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _OpsiCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: accentColor.withValues(alpha: 0.1),
        highlightColor: accentColor.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
