import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/account/presentation/pages/account_page.dart';
import 'package:sigap_mobile/features/account/presentation/pages/guest_account_page.dart';
import 'package:sigap_mobile/features/wawasan/presentation/pages/wawasan_page.dart';
import 'package:sigap_mobile/features/lapor/presentation/pages/lapor_page.dart';
import 'package:sigap_mobile/features/lapor/presentation/pages/lapor_guest_page.dart';
import 'package:sigap_mobile/features/chat/presentation/pages/chat_welcome_page.dart';
import 'package:sigap_mobile/features/home/presentation/pages/home_page.dart';

/// Screen utama dengan navigasi BottomNavigationBar (Beranda, Temanku, Lapor, Wawasan, Akun).
class MainScreen extends StatefulWidget {
  final bool isGuest;

  const MainScreen({super.key, this.isGuest = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Daftar halaman navigasi
    final List<Widget> pages = [
      HomePage(isGuest: widget.isGuest),
      const ChatWelcomePage(),
      const SizedBox(), // Placeholder Lapor (dihandle FAB)
      const WawasanPage(),
      widget.isGuest ? const GuestAccountPage() : const AccountPage(),
    ];

    return Scaffold(
      // Menggunakan SafeArea agar konten tidak tertutup status bar atau notch
      body: SafeArea(
        child: pages[_selectedIndex],
      ),

      // Tombol Lapor (Tengah) - Mengarah ke STEALTH EMERGENCY PAGE
      floatingActionButton: SizedBox(
        width: 66,
        height: 66,
        child: FloatingActionButton(
          onPressed: () => _onItemTapped(2),
          elevation: 4,
          backgroundColor: AppConstants.primaryAlphaColor,
          shape: const CircleBorder(),
          child: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppConstants.urgentColor,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.shield_rounded, color: Colors.white, size: 30),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: Colors.white,
        elevation: 10,
        padding: EdgeInsets.zero,
        // Wrap Row dengan SafeArea agar tidak tertutup Home Indicator (garis bawah) di iOS
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Beranda'),
                _buildNavItem(1, Icons.group_rounded, 'Temanku'),
                const SizedBox(width: 48), // Spacer FAB
                _buildNavItem(3, Icons.article_rounded, 'Wawasan'),
                _buildNavItem(4, Icons.person_rounded, 'Akun'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      if (widget.isGuest) {
        // Tamu mencoba akses Lapor -> Arahkan ke Halaman Edukasi Login
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LaporGuestPage()),
        );
      } else {
        // User Login -> Masuk Mode Darurat
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LaporPage()),
        );
      }
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  // Builder untuk item navigasi
  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;
    final Color currentColor =
        isSelected ? AppConstants.primaryColor : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? const Border(
                    top: BorderSide(
                        color: AppConstants.primaryColor, width: 3.0))
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: currentColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: currentColor,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
