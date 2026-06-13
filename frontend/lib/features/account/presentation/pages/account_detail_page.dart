import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/account/presentation/pages/edit_profile_page.dart';
import 'package:sigap_mobile/features/account/presentation/pages/key_management_page.dart';
import 'package:sigap_mobile/features/account/presentation/pages/security_settings_page.dart';
import 'package:sigap_mobile/core/services/api_service.dart';

/// Halaman Detail Akun
/// Menampilkan profil lengkap jika sudah login, atau prompt login dengan efek getar jika belum
class AccountDetailPage extends StatefulWidget {
  final bool isLoggedIn;

  const AccountDetailPage({super.key, this.isLoggedIn = false});

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  bool _showLoginPrompt = false;

  // Warna iOS Style
  static const _iosCard = Colors.white;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    if (!widget.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerShake());
    }
  }

  void _triggerShake() async {
    // Delay sebentar agar halaman sempat render dulu
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() => _showLoginPrompt = true);

    // Jalankan animasi shake
    _shakeController.forward().then((_) => _shakeController.reverse());

    // Getaran bersamaan dengan shake (3x pulse)
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: _buildAppBar(),
      body: widget.isLoggedIn ? _buildProfileView() : _buildLoginPromptView(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstants.backgroundColor.withValues(alpha: 0.9),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: AppConstants.primaryColor,
      ),
      title: const Text(
        'Profil Saya',
        style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }

  // =========================================================================
  // VIEW: LOGIN PROMPT (Belum Login)
  // =========================================================================
  Widget _buildLoginPromptView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon Kunci
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _iosCard,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ],
              ),
              child: Icon(Icons.lock_outline_rounded,
                  size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),

            Text('Akses Terbatas',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800)),
            const SizedBox(height: 8),
            Text(
              'Anda harus login terlebih dahulu\nuntuk melihat detail akun',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade500, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Tombol Login dengan Efek Getar
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final shake = Tween(begin: 0.0, end: 1.0)
                    .chain(CurveTween(curve: Curves.elasticIn))
                    .evaluate(_shakeController);
                return Transform.translate(
                  offset: Offset(10 * shake * (shake > 0.5 ? -1 : 1), 0),
                  child: child,
                );
              },
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: const Text('Masuk atau Daftar',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),

            // Notifikasi Merah
            if (_showLoginPrompt) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Text('Silakan login terlebih dahulu',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.red.shade700)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // VIEW: PROFIL LENGKAP (Sudah Login)
  // =========================================================================
  Widget _buildProfileView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileCard(),
          const SizedBox(height: 32),
          _InfoSection(),
          const SizedBox(height: 24),
          _EditButton(onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfilePage()),
            );
          }),
          const SizedBox(height: 40),
          _SecuritySection(),
        ],
      ),
    );
  }
}

// =============================================================================
// WIDGETS TERPISAH (Reusable & Clean)
// =============================================================================

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 30,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade50,
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: Colors.grey.shade200,
              child: Icon(Icons.person_rounded,
                  size: 56, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 20),
          Text(ApiService.instance.userName,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(ApiService.instance.userRole == 'user' ? 'Mahasiswa Teknologi Informasi' : ApiService.instance.userRole.toUpperCase(),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          _InfoTile(
              icon: Icons.person_outline, label: 'Nama Lengkap', value: ApiService.instance.userName),
          _divider(),
          _InfoTile(
              icon: Icons.badge_outlined, label: 'Role', value: ApiService.instance.userRole),
          _divider(),
          _InfoTile(
              icon: Icons.mail_outline,
              label: 'Email / Info Kontak',
              value: ApiService.instance.currentUser?['email'] ?? 'Tidak tersedia'),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: Colors.grey.shade100, indent: 72);
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.grey.shade50, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade400,
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _EditButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.1),
            ),
            child: const Text('Edit Informasi Pribadi',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Terakhir diubah: 12 Okt 2023',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500)),
      ],
    );
  }
}

class _SecuritySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text('KEAMANAN',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 1)),
        ),
        _SecurityTile(
            icon: Icons.vpn_key_rounded,
            title: 'Key Management',
            subtitle: 'Otorisasi kunci digital untuk akses laporan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const KeyManagementPage(isLoggedIn: true)),
              );
            }),
        const SizedBox(height: 16),
        _SecurityTile(
            icon: Icons.shield_rounded,
            title: 'Sandi & Keamanan',
            subtitle: 'Kelola akses biometrik dan kata sandi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const SecuritySettingsPage(isLoggedIn: true)),
              );
            }),
      ],
    );
  }
}

class _SecurityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SecurityTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(icon, size: 22, color: AppConstants.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            height: 1.3)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}
