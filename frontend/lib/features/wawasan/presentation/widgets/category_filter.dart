import 'package:flutter/material.dart';

class CategoryFilter extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;

  const CategoryFilter({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> categories = const [
    'Semua',
    'Edukasi',
    'Hukum',
    'Pemulihan',
    'Digital',
    'Berita'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF9F9F9))),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFF0F0F0)
                    : Colors.transparent, // Soft grey instead of black
                borderRadius: BorderRadius.circular(24), // Rounder
                border: Border.all(
                  color:
                      isSelected ? Colors.transparent : const Color(0xFFEBEBEB),
                ),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF1A1A1A)
                      : Colors.grey.shade600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
