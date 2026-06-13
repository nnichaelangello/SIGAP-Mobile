import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/lapor/presentation/provider/lapor_isu_provider.dart';

class Step4Pelaku extends StatelessWidget {
  const Step4Pelaku({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            "Siapa Pelakunya?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Pilih salah satu (Otomatis lanjut setelah memilih)",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          Consumer<LaporIsuProvider>(builder: (context, provider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Lingkungan Akademik"),
                _buildGrid(context: context, provider: provider, items: [
                  _PelakuItem("Dosen", "dosen", Icons.school),
                  _PelakuItem("Mahasiswa", "mahasiswa", Icons.school_outlined),
                  _PelakuItem("Tendik", "tenaga_kependidikan", Icons.badge),
                  _PelakuItem("Alumni", "alumni", Icons.workspace_premium),
                ]),

                const SizedBox(height: 24),
                _buildSectionTitle("Layanan Kampus"),
                _buildGrid(context: context, provider: provider, items: [
                  _PelakuItem("Satpam", "petugas_keamanan", Icons.security),
                  _PelakuItem("Kebersihan", "petugas_kebersihan",
                      Icons.cleaning_services),
                  _PelakuItem("Kantin", "staf_kantin", Icons.storefront),
                  _PelakuItem("Tamu", "tamu", Icons.directions_walk),
                ]),

                const SizedBox(height: 24),
                _buildSectionTitle("Relasi Personal"),
                _buildGrid(context: context, provider: provider, items: [
                  _PelakuItem("Pacar", "pacar", Icons.favorite),
                  _PelakuItem("Mantan", "mantan_pacar", Icons.heart_broken),
                  _PelakuItem("Teman", "teman", Icons.group),
                  _PelakuItem(
                      "Tak Dikenal", "orang_tidak_dikenal", Icons.person_off,
                      isEmergency: true),
                ]),

                const SizedBox(height: 24),
                _buildLainnya(context, provider),

                const SizedBox(height: 40),
                // Tidak ada tombol Next karena sistem Auto-Advance
              ],
            );
          }),
        ]));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppConstants.textDark,
        ),
      ),
    );
  }

  Widget _buildGrid({
    required BuildContext context,
    required LaporIsuProvider provider,
    required List<_PelakuItem> items,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5, // Lebar persegi panjang
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = provider.pelakuKekerasan == item.value;

        return GestureDetector(
          onTap: () {
            provider.setPelakuKekerasan(item.value);
            // Delay for ripple effect then AUTO ADVANCE
            Future.delayed(const Duration(milliseconds: 300), () {
              provider.nextStep();
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppConstants.primaryColor
                  : (item.isEmergency ? Colors.red.shade50 : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppConstants.primaryColor
                    : (item.isEmergency
                        ? Colors.red.shade200
                        : Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: isSelected
                      ? Colors.white
                      : (item.isEmergency
                          ? Colors.red.shade700
                          : AppConstants.primaryColor),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (item.isEmergency
                            ? Colors.red.shade700
                            : AppConstants.textDark),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLainnya(BuildContext context, LaporIsuProvider provider) {
    final isSelected = provider.pelakuKekerasan == "lainnya";

    return GestureDetector(
      onTap: () {
        provider.setPelakuKekerasan("lainnya");
        Future.delayed(const Duration(milliseconds: 300), () {
          provider.nextStep();
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? AppConstants.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.more_horiz,
              color: isSelected ? Colors.white : AppConstants.primaryColor,
            ),
            const SizedBox(width: 12),
            Text(
              "Lainnya (Sebutkan di detail)",
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppConstants.textDark,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _PelakuItem {
  final String title;
  final String value;
  final IconData icon;
  final bool isEmergency;

  _PelakuItem(this.title, this.value, this.icon, {this.isEmergency = false});
}
