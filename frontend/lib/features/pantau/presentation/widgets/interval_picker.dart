import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget pemilih interval waktu konfirmasi.
/// Menampilkan semua opsi dari list secara dinamis menggunakan grid 2 kolom.
class IntervalPicker extends StatelessWidget {
  final int intervalDipilih;
  final List<int> opsiInterval;
  final ValueChanged<int> onPilih;

  /// Batas maksimal interval custom (8 jam)
  static const int _batasMaxMenit = 480;

  const IntervalPicker({
    super.key,
    required this.intervalDipilih,
    required this.opsiInterval,
    required this.onPilih,
  });

  @override
  Widget build(BuildContext context) {
    // Tampilkan semua opsi + card custom dalam grid 2 kolom
    final totalItems = opsiInterval.length + 1; // +1 untuk card custom
    final jumlahBaris = (totalItems / 2).ceil();

    return Column(
      children: List.generate(jumlahBaris, (barisIndex) {
        final indexKiri = barisIndex * 2;
        final indexKanan = indexKiri + 1;

        return Padding(
          padding:
              EdgeInsets.only(bottom: barisIndex < jumlahBaris - 1 ? 12 : 0),
          child: Row(
            children: [
              // Kolom kiri — selalu ada karena totalItems >= 1
              Expanded(
                child: indexKiri < opsiInterval.length
                    ? _bangunCardOpsi(opsiInterval[indexKiri])
                    : _bangunCardCustom(context),
              ),
              const SizedBox(width: 12),
              // Kolom kanan — bisa berisi opsi, card custom, atau kosong
              Expanded(
                child: indexKanan < opsiInterval.length
                    ? _bangunCardOpsi(opsiInterval[indexKanan])
                    : indexKanan == opsiInterval.length
                        ? _bangunCardCustom(context)
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _bangunCardOpsi(int menit) {
    final terpilih = menit == intervalDipilih;
    const Color safetyBlue = Color(0xFF7BA8DC);

    return GestureDetector(
      onTap: () => onPilih(menit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: terpilih ? safetyBlue.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: terpilih ? safetyBlue : Colors.grey.shade200,
            width: terpilih ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$menit',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: terpilih ? safetyBlue : Colors.grey.shade900,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Menit',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: terpilih ? safetyBlue : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            if (terpilih)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: safetyBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bangunCardCustom(BuildContext context) {
    return GestureDetector(
      onTap: () => _tampilkanModalAturWaktu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: Colors.grey.shade300,
                  radius: 12,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_calendar_outlined,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Atur Waktu',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _tampilkanModalAturWaktu(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    String? pesanError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Atur Waktu Khusus',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close_rounded,
                              color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masukkan interval 1–$_batasMaxMenit menit.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w600),
                      onChanged: (_) {
                        // Hapus pesan error saat user mengetik ulang
                        if (pesanError != null) {
                          setModalState(() => pesanError = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Misal: 15',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        suffixText: 'Menit',
                        suffixStyle: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7BA8DC)),
                        errorText: pesanError,
                        errorStyle: GoogleFonts.poppins(fontSize: 11),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color(0xFF7BA8DC), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final val = int.tryParse(controller.text.trim());
                          if (val == null) {
                            setModalState(
                                () => pesanError = 'Masukkan angka yang valid');
                            return;
                          }
                          if (val < 1 || val > _batasMaxMenit) {
                            setModalState(() => pesanError =
                                'Interval harus antara 1–$_batasMaxMenit menit');
                            return;
                          }
                          onPilih(val);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7BA8DC),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Terapkan',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    Path metricPath = Path();
    for (PathMetric measurePath in path.computeMetrics()) {
      double distance = 0;
      while (distance < measurePath.length) {
        metricPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth;
        distance += dashSpace;
      }
    }
    canvas.drawPath(metricPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
