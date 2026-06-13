import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/lapor/presentation/provider/lapor_isu_provider.dart';

class Step2Kekhawatiran extends StatelessWidget {
  const Step2Kekhawatiran({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            "Nilai tingkat kekhawatiran Anda?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Pilih salah satu di bawah ini",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          Consumer<LaporIsuProvider>(builder: (context, provider, child) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _BuildKekhawatiranCard(
                        icon: Icons.sentiment_neutral,
                        label: "SEDIKIT KHAWATIR",
                        value: "sedikit",
                        selectedValue: provider.tingkatKekhawatiran,
                        colorData: Colors.orange.shade300,
                        onTap: () => provider.setTingkatKekhawatiran("sedikit"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BuildKekhawatiranCard(
                        icon: Icons.sentiment_dissatisfied,
                        label: "KHAWATIR",
                        value: "khawatir",
                        selectedValue: provider.tingkatKekhawatiran,
                        colorData: Colors.deepOrange.shade400,
                        onTap: () =>
                            provider.setTingkatKekhawatiran("khawatir"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BuildKekhawatiranCard(
                        icon: Icons.sentiment_very_dissatisfied,
                        label: "SANGAT KHAWATIR",
                        value: "sangat",
                        selectedValue: provider.tingkatKekhawatiran,
                        colorData: Colors.red.shade600,
                        onTap: () => provider.setTingkatKekhawatiran("sangat"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: provider.tingkatKekhawatiran != null
                        ? () => provider.nextStep()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Lanjutkan",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ]));
  }
}

class _BuildKekhawatiranCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? selectedValue;
  final Color colorData;
  final VoidCallback onTap;

  const _BuildKekhawatiranCard({
    required this.icon,
    required this.label,
    required this.value,
    this.selectedValue,
    required this.colorData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: isSelected ? colorData.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? colorData : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 45,
              color: isSelected ? colorData : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? colorData : Colors.grey.shade600,
              ),
            )
          ],
        ),
      ),
    );
  }
}
