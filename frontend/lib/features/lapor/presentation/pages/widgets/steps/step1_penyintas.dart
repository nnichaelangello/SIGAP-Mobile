import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/lapor/presentation/provider/lapor_isu_provider.dart';

class Step1Penyintas extends StatelessWidget {
  const Step1Penyintas({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Siapa Penyintasnya?",
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
                _BuildChoiceCard(
                  icon: Icons.person,
                  title: "SAYA SENDIRI",
                  description: "Saya sendiri mengalami sebagai penyintas",
                  value: "saya",
                  selectedValue: provider.penyintas,
                  onTap: () => provider.setPenyintas("saya"),
                ),
                const SizedBox(height: 16),
                _BuildChoiceCard(
                  icon: Icons.people_alt,
                  title: "ORANG LAIN",
                  description:
                      "Saya melihat atau mendengar orang lain mendapat kekerasan",
                  value: "oranglain",
                  selectedValue: provider.penyintas,
                  onTap: () => provider.setPenyintas("oranglain"),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: provider.penyintas != null
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
        ],
      ),
    );
  }
}

class _BuildChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String value;
  final String? selectedValue;
  final VoidCallback onTap;

  const _BuildChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? AppConstants.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color:
                  isSelected ? AppConstants.primaryColor : Colors.grey.shade400,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppConstants.primaryColor
                          : AppConstants.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppConstants.primaryColor
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color:
                    isSelected ? AppConstants.primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            )
          ],
        ),
      ),
    );
  }
}
