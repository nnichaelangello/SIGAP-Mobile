import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/auth/data/konstanta_auth.dart';

/// Dropdown Program Studi — styling konsisten dengan KolomInputAuth.
///
/// Mengambil data dari [daftarProdi] di konstanta_auth.dart.
/// Hanya ditampilkan untuk peran Mahasiswa dan Dosen.
/// Karyawan menggunakan input teks "Unit Kerja" sebagai gantinya.
class DropdownProdi extends StatelessWidget {
  final String? nilaiTerpilih;
  final ValueChanged<String?> onBerubah;

  const DropdownProdi({
    super.key,
    this.nilaiTerpilih,
    required this.onBerubah,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: nilaiTerpilih,
      decoration: InputDecoration(
        labelText: 'Program Studi',
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppConstants.textSecondary,
        ),
        prefixIcon: Icon(
          Icons.menu_book_rounded,
          size: 20,
          color: AppConstants.textSecondary.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: AppConstants.backgroundColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _bingkai(Colors.grey.shade200),
        enabledBorder: _bingkai(Colors.grey.shade200),
        focusedBorder: _bingkai(AppConstants.primaryColor, lebar: 1.5),
      ),
      style: GoogleFonts.poppins(fontSize: 14, color: AppConstants.textDark),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(14),
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: AppConstants.textSecondary.withValues(alpha: 0.5)),
      items: daftarProdi
          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
          .toList(),
      onChanged: onBerubah,
      validator: (v) => v == null ? 'Program Studi wajib dipilih' : null,
    );
  }

  OutlineInputBorder _bingkai(Color warna, {double lebar = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: warna, width: lebar),
    );
  }
}
