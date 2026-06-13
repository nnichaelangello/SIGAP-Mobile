import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Halaman Kebijakan Privasi
/// Redesigned with DeepUI principles: SliverAppBar, Premium Typography, and Clear Hierarchy.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
                  const SizedBox(height: 32),
                  _buildSection4(),
                  const SizedBox(height: 32),
                  _buildConsent(),
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
                  Icons.security_rounded,
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
                      'Kebijakan Privasi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Komitmen kami dalam menjaga integritas\ndan kerahasiaan data Anda.',
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
                child: const Icon(Icons.verified_user_rounded,
                    color: AppConstants.primaryColor),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Enkripsi Standar Militer',
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
            'Seluruh data dilindungi protokol AES-256 yang memenuhi standar kepatuhan internasional. Privasi Anda adalah prioritas absolut kami.',
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
        _buildSectionHeader(Icons.gavel_rounded, 'LANDASAN HUKUM'),
        const SizedBox(height: 16),
        const Text(
          'Kami beroperasi sepenuhnya di bawah payung hukum Undang-Undang Perlindungan Data Pribadi (UU PDP). Setiap pemrosesan data dilakukan dengan basis hukum yang sah.',
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 14,
            height: 1.8,
            color: AppConstants.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _buildBulletPoint(
            'Enkripsi Berlapis: Data dikunci menggunakan standar AES-256-GCM.'),
        _buildBulletPoint(
            'Anonimitas Terjamin: Identitas pelapor dilindungi hak kerahasiaan penuh.'),
      ],
    );
  }

  Widget _buildSection2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            Icons.data_usage_rounded, 'LINGKUP PENGUMPULAN DATA'),
        const SizedBox(height: 16),
        const Text(
          'Kami menerapkan prinsip "Data Minimization". Kami tidak mengumpulkan data yang tidak relevan dengan esensi pelaporan.',
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 14,
            height: 1.8,
            color: AppConstants.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _buildBulletPoint(
            'Data Laporan: Kronologi kejadian dan bukti materiil.'),
        _buildBulletPoint(
            'Metadata Keamanan: Jejak audit digital untuk validasi forensik.'),
        _buildBulletPoint('Token Enkripsi: Kunci unik yang hanya Anda miliki.'),
      ],
    );
  }

  Widget _buildSection3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.security_rounded, 'INFRASTRUKTUR KEAMANAN'),
        const SizedBox(height: 16),
        _buildNumberedItem(
            1, 'Penerapan arsitektur Zero-Trust Network Access (ZTNA).'),
        _buildNumberedItem(2,
            'Data Siloing: Pemisahan fisik server data identitas dan data laporan.'),
        _buildNumberedItem(
            3, 'Monitoring anomali keamanan siber 24/7 oleh tim SecOps.'),
        _buildNumberedItem(
            4, 'Pemusnahan data aman (Secure Deletion) sesuai retensi hukum.'),
      ],
    );
  }

  Widget _buildSection4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.pan_tool_rounded, 'HAK SUBJEK DATA'),
        const SizedBox(height: 16),
        const Text(
          'Sebagai pemilik data, Anda memiliki hak penuh yang dijamin undang-undang:',
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 14,
            height: 1.8,
            color: AppConstants.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _buildBulletPoint('Hak Akses: Meminta salinan data yang tersimpan.'),
        _buildBulletPoint('Hak Koreksi: Memperbaiki akurasi data lapor.'),
        _buildBulletPoint(
            'Hak Penghapusan (Right to be Forgotten): Menghapus permanen jejak digital Anda.'),
      ],
    );
  }

  Widget _buildConsent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 20, color: AppConstants.primaryColor),
              SizedBox(width: 8),
              Text(
                'Pernyataan Persetujuan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Dengan melanjutkan penggunaan layanan ini, Anda secara sadar memberikan izin pemrosesan data sesuai standar pelindungan data yang berlaku.',
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
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
          const Text(
            'Integritas. Keamanan. Keadilan.',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              color: Colors
                  .grey, // Assuming shade400 is not const, but actually shade400 is const.
            ), // Wait, Colors.grey.shade400 IS const.
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

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppConstants.primaryColor,
              shape: BoxShape.circle,
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
