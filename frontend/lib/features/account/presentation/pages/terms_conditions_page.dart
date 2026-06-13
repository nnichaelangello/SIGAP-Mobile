import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Halaman Syarat dan Ketentuan
/// Redesigned with DeepUI principles matching PrivacyPolicyPage.
class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  _buildHighlightCard(),
                  const SizedBox(height: 32),
                  _buildSection1(),
                  const SizedBox(height: 32),
                  _buildSection2(),
                  const SizedBox(height: 32),
                  _buildSection3(),
                  const SizedBox(height: 48),
                  _buildFooter(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: AppConstants.primaryColor,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.primaryColor,
                    Color(0xFF4B86C6), // Deep Blue equivalent
                  ],
                ),
              ),
            ),
            // Decorative Patterns
            const Positioned(
              right: -40,
              top: -40,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.assignment_turned_in_rounded,
                  size: 240,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: Opacity(
                opacity: 0.1,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                ),
              ),
            ),
            // Content
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Spacer(),
                    Text(
                      'Syarat & Ketentuan',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Kerangka hukum yang menjamin keadilan\ndan kepastian layanan.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.balance_rounded,
                    color: AppConstants.primaryColor),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Prinsip Keadilan & Transparansi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Setiap pasal dirancang untuk melindungi hak pengguna dan memastikan akuntabilitas institusional dalam setiap proses layanan. Kami berdiri di atas asas keadilan bagi seluruh civitas akademika.',
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 13,
              height: 1.8,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.gavel_rounded, 'KETENTUAN LAYANAN'),
        const SizedBox(height: 16),
        const Text(
          'Dengan mengakses dan menggunakan sistem SIGAP PPKPT, Anda menyetujui untuk terikat oleh syarat dan ketentuan ini. Layanan ini disediakan semata-mata untuk keperluan pelaporan dan tindak lanjut institusional yang sah.',
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 14,
            height: 1.8,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSection2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.assignment_ind_rounded, 'KEWAJIBAN PENGGUNA'),
        const SizedBox(height: 16),
        _buildNumberedItem(1,
            'Validitas: Pengguna wajib memberikan data yang akurat dan dapat dipertanggungjawabkan.'),
        _buildNumberedItem(2,
            'Keamanan Akun: Pengguna bertanggung jawab menjaga kerahasiaan kredensial akses.'),
        _buildNumberedItem(3,
            'Etika: Dilarang menyebarkan informasi palsu atau konten yang melanggar norma.'),
      ],
    );
  }

  Widget _buildSection3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            Icons.copyright_rounded, 'HAK KEKAYAAN INTELEKTUAL'),
        const SizedBox(height: 16),
        const Text(
          'Seluruh desain antarmuka, logo, dan konten dalam aplikasi ini dilindungi oleh hak cipta. Penggunaan tanpa izin tertulis dilarang keras dan dapat dikenakan sanksi.',
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 14,
            height: 1.8,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined,
              size: 32,
              color: AppConstants.primaryColor.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text(
            '© 2026 SIGAP SYSTEM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Integritas. Keamanan. Keadilan.',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppConstants.textDark,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberedItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppConstants.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
