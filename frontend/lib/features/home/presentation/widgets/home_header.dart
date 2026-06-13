import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/core/widgets/blur_extension.dart';
import 'package:sigap_mobile/features/notification/presentation/pages/notification_page.dart';
import 'package:sigap_mobile/core/services/api_service.dart';

/// Widget Header Beranda.
/// Mode Guest: Sapaan umum + Welcome Card.
/// Mode Logged In: Sapaan personal + Identity Card mahasiswa.
class HomeHeader extends StatelessWidget {
  final bool isGuest;

  const HomeHeader({super.key, this.isGuest = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreetingRow(context),
          const SizedBox(height: 32),
          isGuest ? _buildWelcomeCard() : _buildIdentityCard(),
        ],
      ),
    );
  }

  Widget _buildGreetingRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge SIGAP
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppConstants.primaryColor.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_rounded,
                      size: 12, color: AppConstants.primaryColor),
                  SizedBox(width: 4),
                  Text(
                    "SIGAP",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.primaryColor,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isGuest ? "Hai, Pengunjung" : "Hai, ${ApiService.instance.userName.split(' ').first}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.textDark,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        // Glass Notification Button
        _buildNotificationButton(context),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_rounded,
                color: AppConstants.textSecondary, size: 22),
            if (!isGuest)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppConstants.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── GUEST: Welcome Card ─────────────────────
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor.withValues(alpha: 0.85),
            const Color(0xFF5A8BBD).withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Light flare
            Positioned(
              bottom: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ).blurred(blur: 40),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.waving_hand_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(height: 16),
                const Text(
                  "Selamat Datang\ndi SIGAP PPKS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Masuk untuk mengakses semua fitur dan layanan kampus.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.login_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        "Login Sekarang",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── LOGGED IN: Identity Card ─────────────────
  Widget _buildIdentityCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor.withValues(alpha: 0.9),
            const Color(0xFF5A8BBD).withValues(alpha: 0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              bottom: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ).blurred(blur: 40),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatarContainer(),
                  const SizedBox(width: 20),
                  Expanded(child: _buildIdentityInfo()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContainer() {
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(ApiService.instance.userName)}&size=128&background=F4F6F9&color=7BA8DC&bold=true',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildIdentityInfo() {
    final user = ApiService.instance.currentUser;
    final nim = user?['nim_nidn_nik']?.toString() ?? '-';
    final prodi = user?['prodi_unit']?.toString() ?? '-';
    final role = user?['role']?.toString() ?? 'user';
    final subRole = user?['sub_role']?.toString() ?? '';
    
    // Determine the text to show on the badge
    String badgeText = subRole.isNotEmpty ? subRole.toUpperCase() : 'MAHASISWA';
    if (role == 'admin') {
      badgeText = 'ADMIN';
    }
    if (role == 'psikolog') {
      badgeText = 'PSIKOLOG';
    }

    // Determine the color of the badge based on role
    Color badgeColor = Colors.white.withValues(alpha: 0.2);
    if (role == 'admin') {
      badgeColor = AppConstants.urgentColor.withValues(alpha: 0.8);
    } else if (role == 'psikolog') {
      badgeColor = AppConstants.successColor.withValues(alpha: 0.8);
    } else if (subRole.toLowerCase() == 'dosen') {
      badgeColor = Colors.orange.withValues(alpha: 0.8);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ApiService.instance.userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          nim.isNotEmpty ? nim : "-",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontFamily: 'monospace',
            fontSize: 14,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (prodi.isNotEmpty && role == 'user')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(
                  prodi,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
