import 'package:flutter/material.dart';
import 'package:sigap_mobile/features/wawasan/presentation/pages/article_search_page.dart';

class WawasanHeader extends StatelessWidget {
  const WawasanHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF9F9F9))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EDITORIAL FRAMING
          const Text(
            "Wawasan",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.0,
              color: Color(0xFF1A1A1A),
              fontFamily: 'Serif',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Ruang untuk membaca, memahami, dan belajar.",
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),

          // HUMANIST SEARCH
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const ArticleSearchPage(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
            child: SizedBox(
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey.shade400, size: 22),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Apa yang ingin Anda pahami hari ini?",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
