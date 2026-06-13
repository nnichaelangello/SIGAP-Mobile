import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:vibration/vibration.dart';
import 'package:sigap_mobile/features/pantau/services/pantau_aman_flag.dart';

/// Tampilan PRIMARY saat check-in diminta — user harus konfirmasi "aman".
///
/// [kesempatan] mengontrol UI dan durasi:
///   1 = Kesempatan pertama (30 detik) — overlay phase
///   2 = Kesempatan kedua (30 detik) — overlay phase
///   3 = Final countdown (90 detik) — fase terakhir, getaran agresif
///
/// Timer dihitung dari [waktuMulaiCheckin] (timestamp nyata),
/// bukan selalu mulai dari awal.
class PantauCheckInView extends StatefulWidget {
  final VoidCallback onKonfirmasiAman;
  final VoidCallback onDarurat;
  final VoidCallback onTimeout;
  final int timeoutDetik;
  final int kesempatan; // 1, 2, atau 3
  final DateTime waktuMulaiCheckin;

  const PantauCheckInView({
    super.key,
    required this.onKonfirmasiAman,
    required this.onDarurat,
    required this.onTimeout,
    required this.waktuMulaiCheckin,
    this.timeoutDetik = 30,
    this.kesempatan = 1,
  });

  @override
  State<PantauCheckInView> createState() => _PantauCheckInViewState();
}

class _PantauCheckInViewState extends State<PantauCheckInView>
    with WidgetsBindingObserver {
  late int _sisaDetik;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _hitungSisaDariTimestamp();

    if (_sisaDetik <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTimeout();
      });
    } else {
      _mulaiTimerCheckin();
    }
  }

  void _hitungSisaDariTimestamp() {
    final detikBerlalu =
        DateTime.now().difference(widget.waktuMulaiCheckin).inSeconds;
    _sisaDetik =
        (widget.timeoutDetik - detikBerlalu).clamp(0, widget.timeoutDetik);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (!mounted) return; // Guard 1: widget masih ada

      _timer?.cancel(); // Selalu cancel timer dulu

      // ── Cek flag AMAN dari overlay (file-based, SYNCHRONOUS) ──
      // Jika user sudah tekan AMAN di overlay, flag ada di file system.
      // Langsung konfirmasi — JANGAN restart timer atau trigger vibrasi.
      if (PantauAmanFlag.adaSync()) {
        // Tidak hapus flag di sini — biarkan PantauPage yang hapus
        // setelah _konfirmasiAman() selesai diproses.
        widget.onKonfirmasiAman();
        return;
      }

      _hitungSisaDariTimestamp();

      if (_sisaDetik <= 0) {
        _handleVibrasi(0);
        // Tunda 1 detik sebelum timeout untuk memberi kesempatan
        // _konfirmasiAman() menyelesaikan setState dan unmount widget ini.
        // Jika widget ter-unmount dalam 1 detik, callback tidak akan dipanggil.
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            // Guard 2: cek ulang setelah delay
            widget.onTimeout();
          }
        });
      } else {
        setState(() {});
        _mulaiTimerCheckin();
      }
    }
  }

  void _mulaiTimerCheckin() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      final detikBerlalu =
          DateTime.now().difference(widget.waktuMulaiCheckin).inSeconds;
      final targetSisa =
          (widget.timeoutDetik - detikBerlalu).clamp(0, widget.timeoutDetik);

      if (targetSisa != _sisaDetik) {
        setState(() {
          _sisaDetik = targetSisa;
        });

        _handleVibrasi(_sisaDetik);

        if (_sisaDetik <= 0) {
          t.cancel();
          widget.onTimeout();
        }
      }
    });
  }

  void _handleVibrasi(int sisaDetik) {
    try {
      if (widget.kesempatan >= 3) {
        // ── FINAL COUNTDOWN (90 dtk) — getaran agresif ──
        if (sisaDetik == 0) {
          Vibration.vibrate(
            pattern: [0, 1000, 500, 1000],
            intensities: [0, 255, 0, 255],
          );
        } else if (sisaDetik <= 5) {
          // SOS tiap detik di 5 detik terakhir
          Vibration.vibrate(
            pattern: [0, 100, 80, 100, 80, 100],
            intensities: [0, 255, 0, 255, 0, 255],
          );
        } else if (sisaDetik <= 10 && sisaDetik > 5) {
          // Keras menjelang habis
          Vibration.vibrate(
            pattern: [0, 500, 200, 500],
            intensities: [0, 255, 0, 255],
          );
        } else if (sisaDetik <= 30 && sisaDetik % 5 == 0) {
          // Getar tiap 5 detik, intensitas naik
          final amplitudo = 180 + ((30 - sisaDetik) * 2);
          Vibration.vibrate(
            duration: 300,
            amplitude: amplitudo.clamp(180, 255),
          );
        } else if (sisaDetik > 30 && sisaDetik % 10 == 0) {
          // Getar tiap 10 detik, halus
          Vibration.vibrate(duration: 250, amplitude: 150);
        }
      } else {
        // ── OVERLAY PHASE (30 dtk) — getaran ringan ──
        if (sisaDetik == 0) {
          Vibration.vibrate(
            pattern: [0, 500, 200, 500],
            intensities: [0, 255, 0, 255],
          );
        } else if (sisaDetik <= 5 && sisaDetik > 0) {
          // Getar terus-menerus di 5 detik terakhir
          final amplitudo = 200 + ((5 - sisaDetik) * 11);
          Vibration.vibrate(
            duration: 300,
            amplitude: amplitudo.clamp(200, 255),
          );
        } else if (sisaDetik % 10 == 0) {
          // Pengingat tiap 10 detik
          Vibration.vibrate(duration: 200, amplitude: 150);
        }
      }
    } catch (e) {
      debugPrint('[PantauCheckInView] Gagal vibrasi (sisa=$sisaDetik): $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Helper UI per kesempatan ──

  Color get _badgeColor {
    if (widget.kesempatan >= 3) return const Color(0xFF991B1B);
    if (widget.kesempatan == 2) return const Color(0xFFB91C1C);
    return AppConstants.urgentColor;
  }

  String get _badgeText {
    if (widget.kesempatan >= 3) return 'BANTUAN AKAN DIKIRIM';
    if (widget.kesempatan == 2) return 'PERINGATAN TERAKHIR';
    return 'KONFIRMASI DIPERLUKAN';
  }

  String get _countdownText {
    if (widget.kesempatan >= 3) {
      return 'Bantuan otomatis dikirim dalam $_sisaDetik detik';
    }
    if (widget.kesempatan == 2) {
      return 'Sisa waktu respons: $_sisaDetik detik';
    }
    return 'Konfirmasi dalam $_sisaDetik detik';
  }

  @override
  Widget build(BuildContext context) {
    final lebarLayar = MediaQuery.of(context).size.width;
    final paddingH =
        lebarLayar > 480 ? ((lebarLayar - 430) / 2).clamp(24.0, 120.0) : 24.0;

    // Background merah muda untuk final countdown
    final bgColor =
        widget.kesempatan >= 3 ? const Color(0xFFFEF2F2) : Colors.white;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _sisaDetik / widget.timeoutDetik,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(
              _sisaDetik <= 5
                  ? AppConstants.urgentColor
                  : widget.kesempatan >= 3
                      ? AppConstants.urgentColor
                      : AppConstants.primaryColor,
            ),
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: paddingH),
                child: Column(
                  children: [
                    const SizedBox(height: 36),

                    _bangunBadge(),

                    const SizedBox(height: 16),

                    Text(
                      _countdownText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _sisaDetik <= 5
                            ? AppConstants.urgentColor
                            : AppConstants.textSecondary,
                        fontWeight:
                            _sisaDetik <= 5 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _badgeColor.withValues(alpha: 0.08),
                      ),
                      child: Icon(
                        widget.kesempatan >= 3
                            ? Icons.warning_rounded
                            : Icons.security_rounded,
                        size: 56,
                        color: _badgeColor,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Apakah Anda Aman?',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textDark,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.kesempatan >= 3
                            ? 'Ini kesempatan terakhir. Jika tidak merespons, '
                                'sinyal darurat akan dikirim secara otomatis.'
                            : widget.kesempatan == 2
                                ? 'Anda belum merespons konfirmasi sebelumnya. '
                                    'Tekan tombol di bawah untuk membatalkan pengiriman bantuan.'
                                : 'Tekan tombol di bawah untuk konfirmasi bahwa '
                                    'Anda dalam keadaan aman.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppConstants.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Tombol "Saya Aman"
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: widget.onKonfirmasiAman,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.successColor,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor:
                              AppConstants.successColor.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'SAYA AMAN',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Tombol darurat
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: widget.onDarurat,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color:
                                AppConstants.urgentColor.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'KIRIM SINYAL DARURAT',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.urgentColor,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _badgeColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.kesempatan >= 2) ...[
            Icon(Icons.warning_rounded, size: 14, color: _badgeColor),
            const SizedBox(width: 6),
          ] else ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _badgeColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            _badgeText,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _badgeColor,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
