import 'package:flutter/material.dart';

/// Model data kontak darurat.
/// Menyimpan informasi orang yang akan menerima notifikasi pemantauan.
class KontakDarurat {
  final String id;
  final String nama;
  final String nomorHp;
  final String inisial;
  final Color warnaAvatar;
  final bool aktif;

  const KontakDarurat({
    required this.id,
    required this.nama,
    required this.nomorHp,
    required this.inisial,
    required this.warnaAvatar,
    this.aktif = true,
  });
}

/// Daftar standar kontak darurat (Sistem / Default).
final daftarKontakDarurat = [
  const KontakDarurat(
    id: '1',
    nama: 'Satgas Kekerasan Kampus',
    nomorHp: '022-1234-5678',
    inisial: 'SK',
    warnaAvatar: Color(0xFF7BA8DC),
  ),
  const KontakDarurat(
    id: '2',
    nama: 'Polisi Terdekat',
    nomorHp: '110',
    inisial: 'PL',
    warnaAvatar: Color(0xFF5B9BD5),
  ),
  const KontakDarurat(
    id: '3',
    nama: 'Ambulans & RS',
    nomorHp: '118',
    inisial: 'RS',
    warnaAvatar: Color(0xFF4A90D9),
  ),
];
