import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/guest_profile_header.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/inactive_security_mode_card.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/menu_tile.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/section_header.dart';
import 'package:sigap_mobile/features/report_monitor/presentation/pages/report_monitor_page.dart';
import 'package:sigap_mobile/features/account/presentation/pages/about_page.dart';
import 'package:sigap_mobile/features/app_shell/presentation/pages/auth_check_screen.dart';
import 'package:sigap_mobile/features/account/presentation/pages/help_center_page.dart';
import 'package:sigap_mobile/features/account/presentation/pages/guest_protected_page.dart';
// IMPORT PENTING YANG HILANG KEMARIN:
import 'package:sigap_mobile/features/account/presentation/widgets/feature_cards.dart';

class GuestAccountPage extends StatelessWidget {
  const GuestAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Fungsi reusable untuk membuka Protected Page
    void openProtectedGate(String featureName) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              GuestProtectedPage(
            featureName: featureName,
            onLoginPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AuthCheckScreen()),
              );
            },
            onRegisterPressed: () {
              // Navigasi ke Register
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AuthCheckScreen()),
              );
            },
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Efek Slide Up yang Smooth (Deep UI)
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutQuart;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }

    return Container(
      color: AppConstants.backgroundColor,
      child: Column(
        children: [
          // Sticky Header
          GuestProfileHeader(
            onLoginPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AuthCheckScreen()),
              );
            },
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feature Section
                  const SectionHeader(title: 'Fitur Utama'),
                  const SizedBox(height: 12),
                  const InactiveSecurityModeCard(),
                  const SizedBox(height: 16),

                  // KEMBALIKAN WIDGET ASLI REPORT MONITOR
                  ReportMonitorButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportMonitorPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Settings Group (SEKARANG DIPROTEKSI)
                  MenuSection(
                    title: 'Pengaturan Akun',
                    tiles: [
                      MenuTile(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Detail Akun',
                        subtitle: 'Daftar untuk mengisi data diri',
                        onTap: () => openProtectedGate('Detail Akun'),
                      ),
                      MenuTile(
                        icon: Icons.vpn_key_outlined,
                        title: 'Key Management',
                        subtitle: 'Kelola kunci enkripsi laporan',
                        onTap: () => openProtectedGate('Manajemen Kunci'),
                      ),
                      MenuTile(
                        icon: Icons.shield_outlined,
                        title: 'Sandi & Keamanan',
                        subtitle: 'Kelola akses biometrik dan sandi',
                        onTap: () => openProtectedGate('Pengaturan Keamanan'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Info Group (Tetap Aksesibel)
                  MenuSection(
                    title: 'Info & Bantuan',
                    tiles: [
                      MenuTile(
                        icon: Icons.info_outline,
                        title: 'Tentang SIGAP',
                        subtitle:
                            'Versi ${AppConstants.appVersion}, lisensi & privasi',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutPage(),
                            ),
                          );
                        },
                      ),
                      MenuTile(
                        icon: Icons.help_outline,
                        title: 'Pusat Bantuan',
                        subtitle: 'FAQ, kontak darurat & panduan',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpCenterPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'SIGAP BUILD 1024 (GUEST)',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Colors.grey.shade400,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // Bottom spacer
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
