import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:vibration/vibration.dart';
import 'package:sigap_mobile/features/pantau/services/pantau_aman_flag.dart';

class OverlayCheckinWidget extends StatefulWidget {
  const OverlayCheckinWidget({super.key});

  @override
  State<OverlayCheckinWidget> createState() => _OverlayCheckinWidgetState();
}

class _OverlayCheckinWidgetState extends State<OverlayCheckinWidget> {
  int _durasiCheckin = 30;
  int _sisaDetik = 30;
  Timer? _timer;
  bool _isStarted = false;
  DateTime? _waktuMulai;
  double _opacity = 0.0;
  Timer? _backupTicker;
  Timer? _amanPumpTimer;
  Timer? _timeoutPumpTimer; // FIX: Simpan timer timeout agar bisa di-cancel
  bool _isProcessingInput = false;
  final GlobalKey<_SwipeToConfirmState> _swipeKey =
      GlobalKey<_SwipeToConfirmState>();

  // FIX: Simpan subscription agar bisa di-cancel di dispose()
  StreamSubscription? _overlayListenerSubscription;

  /// Batas maksimal iterasi _amanPumpTimer (60 × 500ms = 30 detik)
  static const int _batasMaxPumpAman = 60;

  @override
  void initState() {
    super.initState();

    // Trigger animasi fade-in awal (hanya jika engine fresh)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && !_isProcessingInput) setState(() => _opacity = 1.0);
      });
    });

    // FIX: Simpan subscription untuk cleanup
    _overlayListenerSubscription =
        FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is! String) return;

      // Balas STATUS_QUERY
      if (event == 'STATUS_QUERY' && _isProcessingInput) {
        try {
          FlutterOverlayWindow.shareData('AMAN');
        } catch (e) {
          debugPrint('[OverlayCheckin] Gagal shareData STATUS_QUERY: $e');
        }
        return;
      }

      if (event.startsWith('START_OVERLAY_CHECKIN')) {
        _prosesStartSignal(event);
      }
    });
  }

  /// FIX: Logika Start dipisah untuk menangani 'Soft Restart' (Engine Reuse)
  void _prosesStartSignal(String event) {
    final parts = event.split(':');
    int? epochMsParsed;

    // Parse timestamp
    if (parts.length >= 2) {
      epochMsParsed = int.tryParse(parts[1]);
    }

    // Parse durasi
    if (parts.length >= 3) {
      final durasi = int.tryParse(parts[2]);
      if (durasi != null && durasi > 0) {
        _durasiCheckin = durasi;
      }
    }

    // Cek Freshness Sinyal
    if (epochMsParsed != null) {
      final requestTime = DateTime.fromMillisecondsSinceEpoch(epochMsParsed);
      final ageSec =
          (DateTime.now().millisecondsSinceEpoch - epochMsParsed) / 1000.0;

      // Jika sinyal terlalu lama (> durasi + 10), abaikan (basi)
      if (ageSec > _durasiCheckin + 10) return;

      // FIX: Deteksi New Session (Soft Restart)
      if (_waktuMulai != null && requestTime.isAfter(_waktuMulai!)) {
        _resetStateUntukSessionBaru();
      }

      _waktuMulai = requestTime;
    } else {
      _waktuMulai = DateTime.now();
    }

    // Jika sudah berjalan untuk session yang sama, abaikan
    if (_isStarted && !_isBaruSajaDiReset) return;
    _isBaruSajaDiReset = false;

    final sisaTerhitung = _hitungSisaDetik();

    if (mounted) {
      setState(() {
        _isStarted = true;
        _sisaDetik = sisaTerhitung;
        _opacity = 1.0;
      });
    }

    // Getar hanya jika sisa waktu masih banyak (bukan late delivery)
    if (sisaTerhitung > 5) {
      try {
        Vibration.vibrate(duration: 400, amplitude: 200);
      } catch (e) {
        debugPrint('[OverlayCheckin] Gagal vibrasi awal: $e');
      }
    }

    if (sisaTerhitung <= 0) {
      _triggerTimeout();
    } else {
      _mulaiCountdown();
    }
  }

  // Helper flag untuk bypass check _isStarted sesaat setelah reset
  bool _isBaruSajaDiReset = false;

  /// Method untuk membersihkan state "Zombie"
  void _resetStateUntukSessionBaru() {
    _timer?.cancel();
    _backupTicker?.cancel();
    _amanPumpTimer?.cancel();
    _timeoutPumpTimer?.cancel(); // FIX: Bunuh timer timeout orphan

    _isStarted = false;
    _isProcessingInput = false;
    _opacity = 0.0;
    _isBaruSajaDiReset = true;

    // FIX: Reset state SwipeToConfirm agar tidak macet "STATUS AMAN"
    _swipeKey.currentState?.reset();

    PantauAmanFlag.hapus();
  }

  int _hitungSisaDetik() {
    if (_waktuMulai == null) return _durasiCheckin;
    final berlalu = DateTime.now().difference(_waktuMulai!).inSeconds;
    return (_durasiCheckin - berlalu).clamp(0, _durasiCheckin);
  }

  void _mulaiCountdown() {
    _timer?.cancel();
    _backupTicker?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _refreshUI();
    });

    _backupTicker = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final sisa = _hitungSisaDetik();
      if (mounted && sisa != _sisaDetik) {
        setState(() => _sisaDetik = sisa);
        if (sisa <= 0) {
          t.cancel();
          _timer?.cancel();
          _triggerTimeout();
        }
      }
    });
  }

  void _refreshUI() {
    final sisa = _hitungSisaDetik();
    if (mounted) {
      setState(() => _sisaDetik = sisa);
    }
    _handleGetaran(sisa);
    if (sisa <= 0) {
      _timer?.cancel();
      _backupTicker?.cancel();
      _triggerTimeout();
    }
  }

  void _handleGetaran(int detikSisa) {
    try {
      if (detikSisa <= 5 && detikSisa > 0) {
        final amplitudo = 200 + ((5 - detikSisa) * 11);
        Vibration.vibrate(
          duration: 300,
          amplitude: amplitudo.clamp(200, 255),
        );
      } else if (detikSisa == 0) {
        Vibration.vibrate(
          pattern: [0, 500, 200, 500],
          intensities: [0, 255, 0, 255],
        );
      } else if (detikSisa > 5 && detikSisa % 10 == 0) {
        Vibration.vibrate(duration: 200, amplitude: 150);
      }
    } catch (e) {
      debugPrint('[OverlayCheckin] Gagal vibrasi (sisa=$detikSisa): $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _backupTicker?.cancel();
    _amanPumpTimer?.cancel();
    _timeoutPumpTimer?.cancel(); // FIX: Pastikan tidak ada timer orphan
    // FIX: Cancel stream subscription — mencegah memory leak
    _overlayListenerSubscription?.cancel();
    super.dispose();
  }

  void _triggerAman() {
    if (_isProcessingInput) return;
    _isProcessingInput = true;
    _timer?.cancel();
    _backupTicker?.cancel();

    try {
      Vibration.vibrate(duration: 50, amplitude: 128);
    } catch (e) {
      debugPrint('[OverlayCheckin] Gagal vibrasi aman: $e');
    }

    setState(() {
      _sisaDetik = 999;
    });

    PantauAmanFlag.tulis();

    try {
      FlutterOverlayWindow.shareData('AMAN');
    } catch (e) {
      debugPrint('[OverlayCheckin] Gagal shareData AMAN: $e');
    }

    // FIX: Batasi pump agar tidak broadcast selamanya
    int pumpCount = 0;
    _amanPumpTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      pumpCount++;
      if (!mounted || pumpCount >= _batasMaxPumpAman) {
        t.cancel();
      } else {
        try {
          FlutterOverlayWindow.shareData('AMAN');
        } catch (e) {
          debugPrint('[OverlayCheckin] Gagal pump AMAN ($pumpCount): $e');
        }
      }
    });

    Future.delayed(const Duration(seconds: 30), () {
      try {
        FlutterOverlayWindow.closeOverlay();
      } catch (e) {
        debugPrint('[OverlayCheckin] Gagal closeOverlay setelah aman: $e');
      }
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _opacity = 0.0);
    });
  }

  void _triggerTimeout() {
    if (_isProcessingInput) return;
    _isProcessingInput = true;
    _timer?.cancel();
    _backupTicker?.cancel();

    setState(() {
      _sisaDetik = 0;
    });

    int attempts = 0;
    // FIX: Simpan timer ke variabel class agar bisa di-cancel saat stop/reset
    _timeoutPumpTimer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (!mounted || attempts > 10) {
        t.cancel();
        try {
          FlutterOverlayWindow.closeOverlay();
        } catch (e) {
          debugPrint('[OverlayCheckin] Gagal closeOverlay timeout: $e');
        }
      } else {
        try {
          FlutterOverlayWindow.shareData('TIMEOUT');
        } catch (e) {
          debugPrint('[OverlayCheckin] Gagal shareData TIMEOUT: $e');
        }
        attempts++;
      }
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _opacity = 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    Color progressColor;
    if (_sisaDetik <= 5) {
      progressColor = AppConstants.urgentColor;
    } else if (_sisaDetik <= 15) {
      progressColor = const Color(0xFFF59E0B);
    } else {
      progressColor = AppConstants.successColor;
    }

    return Material(
      color: Colors.transparent,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _opacity,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Konfirmasi Keamanan',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    Text(
                      '$_sisaDetik dtk',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _sisaDetik / _durasiCheckin,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 16),
                SwipeToConfirm(
                  key: _swipeKey, // FIX: GlobalKey untuk reset dari luar
                  onConfirm: _triggerAman,
                  backgroundColor:
                      AppConstants.successColor.withValues(alpha: 0.1),
                  thumbColor: AppConstants.successColor,
                  textColor: AppConstants.successColor,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Komponen kustom untuk Swipe to Confirm (Menghindari "Kepencet di saku")
class SwipeToConfirm extends StatefulWidget {
  final VoidCallback onConfirm;
  final Color backgroundColor;
  final Color thumbColor;
  final Color textColor;

  const SwipeToConfirm({
    super.key,
    required this.onConfirm,
    this.backgroundColor = const Color(0xFFF1F5F9),
    this.thumbColor = const Color(0xFF10B981),
    this.textColor = const Color(0xFF10B981),
  });

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm> {
  double _position = 0.0;
  bool _isConfirmed = false;
  final double _height = 64.0;
  final double _thumbSize = 52.0;

  /// FIX: Method publik untuk reset dari luar (via GlobalKey)
  void reset() {
    if (mounted) {
      setState(() {
        _position = 0.0;
        _isConfirmed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxPosition =
            maxWidth - _thumbSize - 12; // 6 offset dari kanan-kiri

        return Container(
          width: maxWidth,
          height: _height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: widget.thumbColor.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Teks di tengah
              Center(
                child: AnimatedOpacity(
                  opacity: _isConfirmed ? 0.0 : 1.0 - (_position / maxPosition),
                  duration: const Duration(milliseconds: 100),
                  child: Text(
                    'GESER UNTUK AMAN >>>',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: widget.textColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              // Teks Confirmed
              if (_isConfirmed)
                Center(
                  child: Text(
                    'STATUS AMAN \u2713',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: widget.thumbColor,
                    ),
                  ),
                ),

              // Thumb / Tombol Geser — FIX: onHorizontalDrag mencegah konflik scroll
              AnimatedPositioned(
                duration: _position == 0.0
                    ? const Duration(milliseconds: 300)
                    : Duration.zero,
                curve: Curves.easeOutBack,
                left: 6 + _position,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isConfirmed) return;
                    setState(() {
                      _position += details.delta.dx;
                      if (_position < 0) _position = 0;
                      if (_position > maxPosition) _position = maxPosition;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isConfirmed) return;
                    if (_position > maxPosition * 0.8) {
                      setState(() {
                        _position = maxPosition;
                        _isConfirmed = true;
                      });

                      try {
                        Vibration.vibrate(duration: 50, amplitude: 128);
                      } catch (_) {}

                      widget.onConfirm();
                    } else {
                      setState(() {
                        _position = 0;
                      });
                    }
                  },
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color:
                          _isConfirmed ? Colors.transparent : widget.thumbColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isConfirmed
                          ? null
                          : [
                              BoxShadow(
                                color: widget.thumbColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                    ),
                    child: Center(
                      child: Icon(
                        _isConfirmed
                            ? Icons.check_circle
                            : Icons.keyboard_double_arrow_right_rounded,
                        color: _isConfirmed ? widget.thumbColor : Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
