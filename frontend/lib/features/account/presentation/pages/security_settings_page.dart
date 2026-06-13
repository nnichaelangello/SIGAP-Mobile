import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/features/account/presentation/pages/fingerprint_setup_page.dart';
import 'package:sigap_mobile/features/account/presentation/pages/pin_management_page.dart';
import 'package:sigap_mobile/features/account/presentation/pages/change_password_page.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/section_header.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/security/expandable_security_section.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/security/security_menu_tile.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/security/login_prompt_view.dart';

/// Halaman Sandi & Keamanan
/// Untuk mengatur kunci aplikasi, biometrik, dan password (hanya untuk user login)
class SecuritySettingsPage extends StatefulWidget {
  final bool isLoggedIn;

  const SecuritySettingsPage({super.key, this.isLoggedIn = false});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage>
    with SingleTickerProviderStateMixin {
  // State untuk expandable sections
  bool _isAppLockExpanded = false;
  bool _isKeyAccessExpanded = false;

  // State untuk toggles dan checkboxes (default: OFF)
  bool _isAppLockEnabled = false;
  bool _isBiometricEnabled = false;
  bool _isPinEnabled = false;

  // State untuk Key Access
  bool _isKeyAccessLockEnabled = false;
  bool _isKeyBiometricEnabled = false;
  bool _isKeyPinEnabled = false;

  // Animation controller untuk shake (jika belum login)
  late final AnimationController _shakeController;
  bool _showLoginPrompt = false;

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
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showLoginPrompt = true);
    _shakeController.forward().then((_) => _shakeController.reverse());
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
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: widget.isLoggedIn
          ? _buildSecurityView()
          : LoginPromptView(
              shakeController: _shakeController,
              showLoginPrompt: _showLoginPrompt,
              onLoginPressed: () => Navigator.pop(context),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: Colors.grey.shade800,
      ),
      title: Text(
        'SANDI & KEAMANAN',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade900,
          letterSpacing: 1,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: Colors.grey.shade100,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildSecurityView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Section: Keamanan Aplikasi
          const SectionHeader(title: 'Keamanan Aplikasi'),
          const SizedBox(height: 12),
          ExpandableSecuritySection(
            icon: Icons.lock_rounded,
            title: 'Kunci Aplikasi',
            subtitle: 'Opsi keamanan saat membuka aplikasi',
            isExpanded: _isAppLockExpanded,
            onToggleExpand: () =>
                setState(() => _isAppLockExpanded = !_isAppLockExpanded),
            isLockEnabled: _isAppLockEnabled,
            onLockToggle: (val) => setState(() => _isAppLockEnabled = val),
            isBiometricEnabled: _isBiometricEnabled,
            onBiometricToggle: (val) =>
                setState(() => _isBiometricEnabled = val),
            isPinEnabled: _isPinEnabled,
            onPinToggle: (val) => setState(() => _isPinEnabled = val),
            lockLabel: 'Aktifkan Kunci Aplikasi',
          ),
          const SizedBox(height: 24),

          // Section: Keamanan Key Management
          const SectionHeader(title: 'Keamanan Key Management'),
          const SizedBox(height: 12),
          ExpandableSecuritySection(
            icon: Icons.vpn_key_rounded,
            title: 'Kunci Akses Key',
            subtitle: 'Proteksi tambahan manajemen kunci',
            isExpanded: _isKeyAccessExpanded,
            onToggleExpand: () =>
                setState(() => _isKeyAccessExpanded = !_isKeyAccessExpanded),
            isLockEnabled: _isKeyAccessLockEnabled,
            onLockToggle: (val) =>
                setState(() => _isKeyAccessLockEnabled = val),
            isBiometricEnabled: _isKeyBiometricEnabled,
            onBiometricToggle: (val) =>
                setState(() => _isKeyBiometricEnabled = val),
            isPinEnabled: _isKeyPinEnabled,
            onPinToggle: (val) => setState(() => _isKeyPinEnabled = val),
            lockLabel: 'Aktifkan Kunci Akses Key',
          ),
          const SizedBox(height: 24),

          // Section: Pengaturan Sandi
          const SectionHeader(title: 'Pengaturan Sandi'),
          const SizedBox(height: 12),
          _buildPasswordSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SecurityMenuTile(
            icon: Icons.password_rounded,
            title: 'Ubah Password',
            subtitle: 'Ganti kata sandi akun Anda',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ChangePasswordPage()),
              );
            },
          ),
          Divider(height: 1, color: Colors.grey.shade100, indent: 68),
          SecurityMenuTile(
            icon: Icons.dialpad_rounded,
            title: 'Atur PIN',
            subtitle: 'Kelola PIN akses aplikasi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PinManagementPage()),
              );
            },
          ),
          Divider(height: 1, color: Colors.grey.shade100, indent: 68),
          SecurityMenuTile(
            icon: Icons.fingerprint_rounded,
            title: 'Atur Sidik Jari',
            subtitle: 'Verifikasi identitas dengan sidik jari',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FingerprintSetupPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
