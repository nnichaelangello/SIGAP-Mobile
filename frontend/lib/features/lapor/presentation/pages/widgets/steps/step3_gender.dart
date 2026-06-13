import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/lapor/presentation/provider/lapor_isu_provider.dart';

class Step3Gender extends StatelessWidget {
  const Step3Gender({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            "Gender Penyintas",
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
                _BuildGenderRadio(
                  title: "Laki-laki",
                  value: "lakilaki",
                  groupValue: provider.genderPenyintas,
                  onChanged: (val) => provider.setGenderPenyintas(val!),
                ),
                const SizedBox(height: 16),
                _BuildGenderRadio(
                  title: "Perempuan",
                  value: "perempuan",
                  groupValue: provider.genderPenyintas,
                  onChanged: (val) => provider.setGenderPenyintas(val!),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: provider.genderPenyintas != null
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

class _BuildGenderRadio extends StatelessWidget {
  final String title;
  final String value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;

  const _BuildGenderRadio({
    required this.title,
    required this.value,
    this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? AppConstants.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: groupValue,
              // ignore: deprecated_member_use
              onChanged: onChanged,
              activeColor: AppConstants.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: AppConstants.textDark,
              ),
            )
          ],
        ),
      ),
    );
  }
}
