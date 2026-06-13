import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:permission_handler/permission_handler.dart';

/// Halaman panduan izin khusus per merek HP.
///
/// Ditampilkan SEBELUM Pantau Aku diaktifkan, membimbing user
/// mengatur izin spesifik OEM (Xiaomi, Samsung, OPPO, dll)
/// agar overlay dan background service tidak di-kill OS.
///
/// Logika:
/// 1. Deteksi merek HP via device_info_plus
/// 2. Tampilkan langkah-langkah spesifik merek tersebut
/// 3. Sediakan tombol langsung ke pengaturan terkait
/// 4. User bisa skip kalau sudah pernah setup
class PanduanIzinPage extends StatefulWidget {
  const PanduanIzinPage({super.key});

  @override
  State<PanduanIzinPage> createState() => _PanduanIzinPageState();
}

class _PanduanIzinPageState extends State<PanduanIzinPage> {
  String _merekHP = '';
  bool _sedangMemuat = true;

  // Checklist state untuk setiap langkah
  final Map<int, bool> _langkahSelesai = {};

  @override
  void initState() {
    super.initState();
    _deteksiMerekHP();
  }

  Future<void> _deteksiMerekHP() async {
    try {
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        // Normalisasi ke lowercase untuk perbandingan yang konsisten
        final merek = info.manufacturer.toLowerCase();
        if (mounted) {
          setState(() {
            _merekHP = merek;
            _sedangMemuat = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _merekHP = 'unknown';
          _sedangMemuat = false;
        });
      }
    }
  }

  /// Ambil data panduan spesifik berdasarkan merek HP
  _DataPanduan _ambilDataPanduan() {
    // Xiaomi / Redmi / POCO (semua pakai MIUI/HyperOS)
    if (_merekHP.contains('xiaomi') ||
        _merekHP.contains('redmi') ||
        _merekHP.contains('poco')) {
      return const _DataPanduan(
        namaUI: 'MIUI / HyperOS',
        ikon: Icons.phone_android_rounded,
        warna: Color(0xFFFF6900), // warna khas Xiaomi
        langkah: [
          _Langkah(
            judul: 'Aktifkan Autostart',
            deskripsi:
                'Buka Pengaturan → Aplikasi → Sigap → Autostart → Aktifkan',
            ikon: Icons.rocket_launch_rounded,
          ),
          _Langkah(
            judul: 'Matikan Pembatasan Baterai',
            deskripsi:
                'Buka Pengaturan → Baterai → Sigap → pilih "Tanpa Pembatasan"',
            ikon: Icons.battery_full_rounded,
          ),
          _Langkah(
            judul: 'Kunci Aplikasi di Recent Apps',
            deskripsi:
                'Buka Recent Apps → tahan card Sigap → ketuk ikon gembok',
            ikon: Icons.lock_rounded,
          ),
          _Langkah(
            judul: 'Izinkan Tampil di Atas Aplikasi Lain',
            deskripsi: 'Buka Pengaturan → Aplikasi → Sigap → Izin Lainnya → '
                'Tampil di Atas Aplikasi Lain → Aktifkan',
            ikon: Icons.layers_rounded,
          ),
        ],
      );
    }

    // Samsung (One UI)
    if (_merekHP.contains('samsung')) {
      return const _DataPanduan(
        namaUI: 'Samsung One UI',
        ikon: Icons.phone_android_rounded,
        warna: Color(0xFF1428A0), // warna khas Samsung
        langkah: [
          _Langkah(
            judul: 'Izinkan Aktivitas Background',
            deskripsi: 'Buka Pengaturan → Aplikasi → Sigap → Baterai → '
                'Aktifkan "Izinkan aktivitas latar belakang"',
            ikon: Icons.battery_full_rounded,
          ),
          _Langkah(
            judul: 'Keluarkan dari Aplikasi Tidur',
            deskripsi:
                'Buka Pengaturan → Perawatan Baterai → Batas penggunaan latar belakang → '
                'pastikan Sigap TIDAK ada di daftar "Aplikasi tidur"',
            ikon: Icons.bedtime_off_rounded,
          ),
          _Langkah(
            judul: 'Izinkan Tampil di Atas Aplikasi Lain',
            deskripsi: 'Buka Pengaturan → Aplikasi → Sigap → '
                'Tampil di atas aplikasi lain → Aktifkan',
            ikon: Icons.layers_rounded,
          ),
        ],
      );
    }

    // OPPO / Realme (ColorOS)
    if (_merekHP.contains('oppo') || _merekHP.contains('realme')) {
      return const _DataPanduan(
        namaUI: 'ColorOS',
        ikon: Icons.phone_android_rounded,
        warna: Color(0xFF1BA784),
        langkah: [
          _Langkah(
            judul: 'Aktifkan Autostart',
            deskripsi: 'Buka Pengaturan → Manajemen Aplikasi → Sigap → '
                'Mulai Otomatis → Aktifkan',
            ikon: Icons.rocket_launch_rounded,
          ),
          _Langkah(
            judul: 'Matikan Optimasi Baterai',
            deskripsi: 'Buka Pengaturan → Baterai → Optimasi Baterai → '
                'Sigap → pilih "Jangan optimalkan"',
            ikon: Icons.battery_full_rounded,
          ),
          _Langkah(
            judul: 'Izinkan Tampil di Atas Aplikasi Lain',
            deskripsi: 'Buka Pengaturan → Manajemen Aplikasi → Sigap → '
                'Tampil di atas → Aktifkan',
            ikon: Icons.layers_rounded,
          ),
        ],
      );
    }

    // Vivo (Funtouch OS)
    if (_merekHP.contains('vivo')) {
      return const _DataPanduan(
        namaUI: 'Funtouch OS',
        ikon: Icons.phone_android_rounded,
        warna: Color(0xFF415FFF),
        langkah: [
          _Langkah(
            judul: 'Aktifkan Autostart',
            deskripsi: 'Buka i Manager → Manajer Aplikasi → Autostart → '
                'Aktifkan untuk Sigap',
            ikon: Icons.rocket_launch_rounded,
          ),
          _Langkah(
            judul: 'Matikan Pembatasan Background',
            deskripsi:
                'Buka Pengaturan → Baterai → Konsumsi Latar Belakang Tinggi → '
                'Izinkan Sigap',
            ikon: Icons.battery_full_rounded,
          ),
          _Langkah(
            judul: 'Izinkan Tampil di Atas Aplikasi Lain',
            deskripsi:
                'Buka Pengaturan → Izin → Tampil di Atas → Sigap → Aktifkan',
            ikon: Icons.layers_rounded,
          ),
        ],
      );
    }

    // Huawei (EMUI / HarmonyOS)
    if (_merekHP.contains('huawei') || _merekHP.contains('honor')) {
      return const _DataPanduan(
        namaUI: 'EMUI / HarmonyOS',
        ikon: Icons.phone_android_rounded,
        warna: Color(0xFFCE0E2D),
        langkah: [
          _Langkah(
            judul: 'Aktifkan Autostart',
            deskripsi:
                'Buka Pengaturan → Aplikasi → Sigap → Manajemen Baterai → '
                'Autostart → Aktifkan',
            ikon: Icons.rocket_launch_rounded,
          ),
          _Langkah(
            judul: 'Tambahkan ke Aplikasi Dilindungi',
            deskripsi: 'Buka Pengaturan → Baterai → Peluncuran Aplikasi → '
                'Sigap → Matikan otomatis (kelola manual)',
            ikon: Icons.shield_rounded,
          ),
          _Langkah(
            judul: 'Izinkan Tampil di Atas Aplikasi Lain',
            deskripsi:
                'Buka Pengaturan → Aplikasi → Sigap → Tampil di atas → Aktifkan',
            ikon: Icons.layers_rounded,
          ),
        ],
      );
    }

    // Default: merek lain (Android stock / Google Pixel)
    return const _DataPanduan(
      namaUI: 'Android',
      ikon: Icons.phone_android_rounded,
      warna: AppConstants.primaryColor,
      langkah: [
        _Langkah(
          judul: 'Matikan Optimasi Baterai',
          deskripsi: 'Buka Pengaturan → Baterai → Optimasi Baterai → '
              'Sigap → pilih "Jangan optimalkan"',
          ikon: Icons.battery_full_rounded,
        ),
        _Langkah(
          judul: 'Izinkan Tampil di Atas Aplikasi Lain',
          deskripsi: 'Buka Pengaturan → Aplikasi → Akses Khusus → '
              'Tampil di atas aplikasi lain → Sigap → Aktifkan',
          ikon: Icons.layers_rounded,
        ),
      ],
    );
  }

  /// Buka pengaturan battery optimization langsung
  Future<void> _bukaPengaturanBaterai() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_sedangMemuat) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: AppConstants.primaryColor.withValues(alpha: 0.6),
            strokeWidth: 2,
          ),
        ),
      );
    }

    final data = _ambilDataPanduan();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Colors.grey.shade800),
        ),
        centerTitle: true,
        title: Text(
          'Panduan Izin',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Info merek HP
                  _bangunHeaderMerek(data),
                  const SizedBox(height: 24),

                  // Penjelasan singkat
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFE082),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 20, color: Color(0xFFF9A825)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Beberapa HP secara agresif mematikan aplikasi '
                            'di background. Ikuti langkah di bawah agar '
                            'Pantau Aku tetap berjalan saat Anda '
                            'menggunakan aplikasi lain.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF795548),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Daftar langkah-langkah
                  Text(
                    'Langkah-langkah:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...List.generate(data.langkah.length, (i) {
                    return _bangunItemLangkah(i, data.langkah[i], data.warna);
                  }),

                  const SizedBox(height: 16),

                  // Tombol buka pengaturan
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _bukaPengaturanBaterai,
                      icon: const Icon(Icons.settings_rounded, size: 18),
                      label: Text(
                        'Buka Pengaturan Aplikasi',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: data.warna,
                        side: BorderSide(
                            color: data.warna.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar: tombol lanjutkan
          _bangunBottomBar(data),
        ],
      ),
    );
  }

  Widget _bangunHeaderMerek(_DataPanduan data) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: data.warna.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(data.ikon, size: 24, color: data.warna),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HP Anda: ${data.namaUI}',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppConstants.textDark,
              ),
            ),
            Text(
              '${data.langkah.length} langkah diperlukan',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bangunItemLangkah(int index, _Langkah langkah, Color warna) {
    final sudahSelesai = _langkahSelesai[index] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _langkahSelesai[index] = !sudahSelesai;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: sudahSelesai
                ? AppConstants.successColor.withValues(alpha: 0.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sudahSelesai
                  ? AppConstants.successColor.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nomor langkah / checkmark
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: sudahSelesai
                      ? AppConstants.successColor
                      : warna.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: sudahSelesai
                      ? const Icon(Icons.check_rounded,
                          size: 18, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: warna,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langkah.judul,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sudahSelesai
                            ? AppConstants.successColor
                            : AppConstants.textDark,
                        decoration: sudahSelesai
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      langkah.deskripsi,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppConstants.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                langkah.ikon,
                size: 20,
                color: sudahSelesai
                    ? AppConstants.successColor.withValues(alpha: 0.5)
                    : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bangunBottomBar(_DataPanduan data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppConstants.primaryColor.withValues(alpha: 0.85),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'SAYA SUDAH MENGATUR',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Lewati untuk sekarang',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Model data internal ──

class _DataPanduan {
  final String namaUI;
  final IconData ikon;
  final Color warna;
  final List<_Langkah> langkah;

  const _DataPanduan({
    required this.namaUI,
    required this.ikon,
    required this.warna,
    required this.langkah,
  });
}

class _Langkah {
  final String judul;
  final String deskripsi;
  final IconData ikon;

  const _Langkah({
    required this.judul,
    required this.deskripsi,
    required this.ikon,
  });
}
