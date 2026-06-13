import 'package:flutter/material.dart';

/// Peran yang tersedia saat pendaftaran akun baru.
///
/// Berbeda dari role database (satgas_admin, satgas_psikolog, rektor)
/// yang hanya bisa di-assign oleh administrator sistem.
/// Enum ini khusus untuk self-registration.
enum PeranPendaftaran {
  mahasiswa,
  dosen,
  karyawan;

  String get label => switch (this) {
        mahasiswa => 'Mahasiswa',
        dosen => 'Dosen',
        karyawan => 'Karyawan',
      };

  IconData get ikon => switch (this) {
        mahasiswa => Icons.school_rounded,
        dosen => Icons.auto_stories_rounded,
        karyawan => Icons.work_outline_rounded,
      };

  /// Label field identitas — berubah sesuai konteks peran.
  String get labelIdentitas => switch (this) {
        mahasiswa => 'NIM',
        dosen => 'NIDN',
        karyawan => 'NIK',
      };

  String get contohIdentitas => switch (this) {
        mahasiswa => 'Contoh: 1202230023',
        dosen => 'Contoh: 0123456789',
        karyawan => 'Contoh: 198701012345',
      };

  String get petunjukEmail => switch (this) {
        mahasiswa => 'nama@student.telkomuniversity.ac.id',
        _ => 'nama@telkomuniversity.ac.id',
      };

  /// Mahasiswa dan Dosen punya Program Studi,
  /// Karyawan punya Unit Kerja (input bebas).
  bool get perluProdi => this != karyawan;
}

/// Program studi di Telkom University Surabaya.
/// Urutan sesuai data akademik kampus.
const daftarProdi = [
  'Sistem Informasi',
  'Teknologi Informasi',
  'Informatika',
  'Rekayasa Perangkat Lunak',
  'Sains Data',
  'Teknik Elektro',
  'Teknik Industri',
  'Teknik Komputer',
  'Teknik Logistik',
  'Teknik Telekomunikasi',
  'Bisnis Digital',
];
