import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Tampilan saat pemantauan aktif — countdown timer.
/// Scroll-safe: menggunakan SingleChildScrollView, bukan Spacer.
class PantauAktifView extends StatelessWidget {
  final int sisaDetik;
  final int intervalMenit;
  final String? lokasiUser;
  final VoidCallback onHentikan;
  final VoidCallback onDarurat;

  const PantauAktifView({
    super.key,
    required this.sisaDetik,
    required this.intervalMenit,
    required this.onHentikan,
    required this.onDarurat,
    this.lokasiUser,
  });

  String _formatWaktu(int totalDetik) {
    final menit = totalDetik ~/ 60;
    final detik = totalDetik % 60;
    return '${menit.toString().padLeft(2, '0')}:'
        '${detik.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progres = sisaDetik / (intervalMenit * 60);
    final lebarLayar = MediaQuery.of(context).size.width;
    final paddingH =
        lebarLayar > 480 ? ((lebarLayar - 430) / 2).clamp(24.0, 120.0) : 24.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingH),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Badge status hijau
            _bangunBadge(),

            const SizedBox(height: 40),

            // Lingkaran countdown
            _bangunTimerCircle(progres),

            const SizedBox(height: 28),

            // Info lokasi (opsional)
            if (lokasiUser != null && lokasiUser!.isNotEmpty)
              _bangunInfoLokasi(),

            const SizedBox(height: 60),

            // Tombol hentikan
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: onHentikan,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppConstants.urgentColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'HENTIKAN PANTAUAN',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.urgentColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tombol darurat — user bisa trigger kapan saja
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: onDarurat,
                icon: const Icon(Icons.emergency_rounded, size: 20),
                label: Text(
                  'KIRIM SINYAL DARURAT',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.urgentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _bangunBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppConstants.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppConstants.successColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.successColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'PANTAUAN AKTIF',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppConstants.successColor,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunTimerCircle(double progres) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 175,
            height: 175,
            child: CircularProgressIndicator(
              value: progres,
              strokeWidth: 4,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppConstants.primaryColor,
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatWaktu(sisaDetik),
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w300,
                  color: AppConstants.textDark,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'konfirmasi berikutnya',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bangunInfoLokasi() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded,
              size: 16, color: AppConstants.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lokasiUser!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppConstants.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
