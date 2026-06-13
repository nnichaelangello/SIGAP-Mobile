import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/pantau/domain/status_pantauan.dart';
import 'package:sigap_mobile/features/pantau/presentation/pages/pantau_kontak_page.dart';
import 'package:sigap_mobile/features/pantau/presentation/widgets/pantau_header.dart';
import 'package:sigap_mobile/features/pantau/presentation/widgets/interval_picker.dart';
import 'package:sigap_mobile/features/pantau/presentation/widgets/pantau_aktif_view.dart';
import 'package:sigap_mobile/features/pantau/presentation/widgets/pantau_checkin_view.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sigap_mobile/features/pantau/services/pantau_aman_flag.dart';
import 'package:sigap_mobile/features/pantau/presentation/pages/panduan_izin_page.dart';
import 'package:sigap_mobile/features/pantau/services/pantau_service.dart';

class PantauPage extends StatefulWidget {
  const PantauPage({super.key});

  @override
  State<PantauPage> createState() => _PantauPageState();
}

class _PantauPageState extends State<PantauPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _intervalDipilih = 45;
  final List<int> _opsiInterval = [2, 5, 10, 15, 30, 45, 60];

  late AnimationController _pulseController;
  final TextEditingController _lokasiController = TextEditingController();

  bool _sudahTampilPanduan = false;
  bool _sedangMengaktifkan = false;
  static const int _batasKarakter = 100;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseController.repeat();

    // Dengarkan perubahan state untuk sinkronisasi animasi UI
    PantauService.instance.stateStream.listen((state) {
      if (mounted) _sinkronkanPulseController(state);
    });
  }

  void _sinkronkanPulseController(StatusPantauan status) {
    if (status is Persiapan) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat();
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _lokasiController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Periksa flag aman setelah lock screen/background
      if (PantauService.instance.currentState is CheckInDiminta &&
          PantauAmanFlag.adaSync()) {
        PantauService.instance.konfirmasiAmanLokal();
      }
    }
  }

  Future<void> _mintaPermisiOverlay() async {
    try {
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) {
        await FlutterOverlayWindow.requestPermission();
      }
    } catch (e) {
      debugPrint('[PantauPage] Gagal minta izin overlay: $e');
    }
  }

  void _aktifkanPantauan() async {
    // FIX: Cegah double-tap dan beri visual feedback
    if (_sedangMengaktifkan) return;
    setState(() => _sedangMengaktifkan = true);

    try {
      await _mintaPermisiOverlay();
      await [
        Permission.notification,
        Permission.systemAlertWindow,
        Permission.ignoreBatteryOptimizations,
      ].request();

      if (!_sudahTampilPanduan && mounted) {
        _sudahTampilPanduan = true;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PanduanIzinPage()),
        );
      }

      if (!mounted) return;

      HapticFeedback.mediumImpact();

      // Mendelegasikan start ke service singleton
      await PantauService.instance.startWatch(_intervalDipilih);
    } catch (e) {
      debugPrint('[PantauPage] Gagal mengaktifkan pantauan: $e');
      if (mounted) {
        _tampilkanSnackbar(
            'Gagal mengaktifkan pantauan', AppConstants.urgentColor);
      }
    } finally {
      if (mounted) {
        setState(() => _sedangMengaktifkan = false);
      }
    }
  }

  void _hentikanPantauan() {
    HapticFeedback.mediumImpact();
    PantauService.instance.stopWatch();
    _tampilkanSnackbar('Pantauan dihentikan', const Color(0xFF333333));
  }

  void _tampilkanSnackbar(String pesan, Color warna) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StatusPantauan>(
        stream: PantauService.instance.stateStream,
        initialData: PantauService.instance.currentState,
        builder: (context, snapshot) {
          final status = snapshot.requireData;

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _bangunAppBar(status),
            body: SafeArea(
              child: switch (status) {
                Persiapan() => _bangunTampilanPersiapan(),
                Aktif(sisaDetik: final sisa, intervalDetik: final interval) =>
                  PantauAktifView(
                    sisaDetik: sisa,
                    intervalMenit: interval ~/ 60,
                    lokasiUser: _lokasiController.text,
                    onHentikan: _hentikanPantauan,
                    onDarurat: () {
                      PantauService.instance.pushDarurat();
                    },
                  ),
                CheckInDiminta(
                  kesempatan: final kesempatan,
                  waktuMulai: final waktuMulai
                ) =>
                  PantauCheckInView(
                    key: ValueKey(
                        'checkin_${kesempatan}_${waktuMulai.millisecondsSinceEpoch}'),
                    onKonfirmasiAman:
                        PantauService.instance.konfirmasiAmanLokal,
                    onDarurat: () {
                      PantauService.instance.pushDarurat();
                    },
                    onTimeout: () {
                      // Timeout ditangani stream service
                    },
                    kesempatan: kesempatan,
                    timeoutDetik: kesempatan >= 3 ? 90 : 30,
                    waktuMulaiCheckin: waktuMulai,
                  ),
                DaruratTerkirim() => const SizedBox
                    .shrink(), // Langsung dinavigasi via GlobalNavigatorKey
              },
            ),
          );
        });
  }

  PreferredSizeWidget _bangunAppBar(StatusPantauan status) {
    final adalahPersiapan = status is Persiapan;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () {
          if (!adalahPersiapan) {
            _tampilkanDialogKeluar();
          } else {
            Navigator.pop(context);
          }
        },
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            size: 20, color: Colors.grey.shade800),
      ),
      centerTitle: true,
      title: Text(
        'Pantau Aku',
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade900,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        if (adalahPersiapan)
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PantauKontakPage()),
            ),
            icon: Icon(Icons.settings_outlined,
                size: 22, color: Colors.grey.shade800),
          ),
      ],
    );
  }

  double _hitungPaddingH(double lebarLayar) {
    if (lebarLayar <= 480) return 24;
    return ((lebarLayar - 430) / 2).clamp(24.0, 120.0);
  }

  Widget _bangunTampilanPersiapan() {
    final lebarLayar = MediaQuery.of(context).size.width;
    final paddingH = _hitungPaddingH(lebarLayar);

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PantauHeader(
                pulseController: _pulseController,
              ),
              const SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: paddingH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Interval Waktu',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntervalPicker(
                      intervalDipilih: _intervalDipilih,
                      opsiInterval: _opsiInterval,
                      onPilih: (v) => setState(() => _intervalDipilih = v),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Detail Lokasi / Situasi',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _bangunTextareaLokasi(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _bangunBottomBar(paddingH),
        ),
      ],
    );
  }

  Widget _bangunTextareaLokasi() {
    return TextField(
      controller: _lokasiController,
      maxLines: 5,
      maxLength: _batasKarakter,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.poppins(fontSize: 14, color: AppConstants.textDark),
      decoration: InputDecoration(
        hintText:
            'Tuliskan detail lokasi Anda saat ini atau tujuan perjalanan...',
        hintStyle:
            GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppConstants.primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _bangunBottomBar(double paddingH) {
    return Container(
      padding: EdgeInsets.fromLTRB(paddingH, 24, paddingH, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Kontak darurat akan menerima notifikasi otomatis beserta '
            'lokasi terakhir Anda jika Anda tidak merespons '
            'notifikasi check-in.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade500,
                height: 1.6,
                fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              // FIX: Disable saat sedang mengaktifkan (cegah double-tap)
              onPressed: _sedangMengaktifkan ? null : _aktifkanPantauan,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppConstants.primaryColor.withValues(alpha: 0.85),
                disabledBackgroundColor:
                    AppConstants.primaryColor.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _sedangMengaktifkan
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'MENGAKTIFKAN...',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2),
                        ),
                      ],
                    )
                  : Text(
                      'AKTIFKAN PANTAUAN',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _tampilkanDialogKeluar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppConstants.urgentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded,
                  size: 28, color: AppConstants.urgentColor),
            ),
            const SizedBox(height: 16),
            Text('Hentikan Pantauan?',
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textDark)),
            const SizedBox(height: 8),
            Text(
              'Kontak darurat tidak akan\nmenerima notifikasi keamanan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppConstants.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Batal',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // FIX: Urutan yang benar agar tidak setState setelah unmount.
                      // 1. Tutup dialog
                      Navigator.pop(ctx);
                      // 2. Keluar halaman PantauPage
                      Navigator.pop(context);
                      // 3. Cleanup di background (service + overlay) didelegasikan
                      PantauService.instance.stopWatch();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.urgentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Hentikan',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
