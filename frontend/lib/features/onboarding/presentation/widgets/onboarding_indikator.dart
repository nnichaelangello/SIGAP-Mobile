import 'package:flutter/material.dart';

/// Widget dot indikator halaman onboarding.
/// Menampilkan dot aktif (lebar, berwarna) dan dot pasif (kecil, abu-abu).
class OnboardingIndikator extends StatelessWidget {
  final int jumlahHalaman;
  final int halamanAktif;
  final Color warnaAktif;

  const OnboardingIndikator({
    super.key,
    required this.jumlahHalaman,
    required this.halamanAktif,
    required this.warnaAktif,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(jumlahHalaman, (index) {
        final bool aktif = index == halamanAktif;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: aktif ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: aktif ? warnaAktif : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
