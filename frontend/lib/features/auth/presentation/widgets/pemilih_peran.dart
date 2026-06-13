import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/auth/data/konstanta_auth.dart';

/// Widget pemilih peran untuk halaman pendaftaran.
///
/// Menggunakan SegmentedButton Material 3 dengan 3 opsi:
/// Mahasiswa, Dosen, Karyawan.
/// Peran admin/psikolog tidak ditampilkan karena bukan self-registration.
class PemilihPeran extends StatelessWidget {
  final PeranPendaftaran peranTerpilih;
  final ValueChanged<PeranPendaftaran> onPeranBerubah;

  const PemilihPeran({
    super.key,
    required this.peranTerpilih,
    required this.onPeranBerubah,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar sebagai',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppConstants.textDark,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<PeranPendaftaran>(
            segments: PeranPendaftaran.values
                .map((p) => ButtonSegment(
                      value: p,
                      label: Text(p.label),
                      icon: Icon(p.ikon, size: 16),
                    ))
                .toList(),
            selected: {peranTerpilih},
            onSelectionChanged: (s) => onPeranBerubah(s.first),
            style: ButtonStyle(
              textStyle: WidgetStatePropertyAll(
                GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              side: WidgetStatePropertyAll(
                BorderSide(
                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }
}
