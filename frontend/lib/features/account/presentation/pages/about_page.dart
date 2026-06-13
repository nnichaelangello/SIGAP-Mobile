import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/account/presentation/pages/privacy_policy_page.dart';
import 'package:sigap_mobile/features/account/presentation/pages/terms_conditions_page.dart';

/// Halaman Tentang SIGAP
/// Redesigned to match HelpCenterPage style (DeepUI)
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
                  _buildIntroCard(),
                  const SizedBox(height: 32),
                  _buildVisionMission(),
                  const SizedBox(height: 32),
                  _buildPillars(),
                  const SizedBox(height: 32),
                  _buildLegalSection(context),
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
                  Icons.info_outline_rounded,
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
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(50)),
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
                      'Tentang SIGAP',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Satuan Tugas Pencegahan & \nPenanganan Kekerasan Seksual',
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

  Widget _buildIntroCard() {
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
                child: const Icon(Icons.shield_rounded,
                    color: AppConstants.primaryColor),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'SIGAP PPKPT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Satuan Tugas Pencegahan dan Penanganan Kekerasan Seksual Telkom University berkomitmen untuk menciptakan lingkungan kampus yang aman, nyaman, dan bebas dari segala bentuk kekerasan seksual. Kami hadir sebagai wadah perlindungan dan pendampingan bagi seluruh civitas akademika.',
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

  Widget _buildVisionMission() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visi & Misi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.textDark,
          ),
        ),
        const SizedBox(height: 16),
        // Vision
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppConstants.primaryColor.withValues(alpha: 0.9),
                const Color(0xFF4B86C6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'VISI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Terwujudnya lingkungan Telkom University yang aman, nyaman, dan bebas dari segala bentuk kekerasan seksual.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Mission Grid
        _buildMissionItem('1',
            'Berpihak pada korban dengan menjamin keamanan dan kenyamanan.'),
        _buildMissionItem('2', 'Melindungi identitas dan informasi sensitif.'),
        _buildMissionItem(
            '3', 'Prosedur pelaporan & pendampingan profesional.'),
        _buildMissionItem('4', 'Memberikan rekomendasi sanksi yang adil.'),
      ],
    );
  }

  Widget _buildMissionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppConstants.primaryColor),
            ),
            child: Center(
              child: Text(
                number,
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

  Widget _buildPillars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Empat Pilar Utama',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.textDark,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          // Adjusted ratio for better proportions (wider/shorter cards)
          childAspectRatio: 1.1,
          children: [
            _buildPillarCard(Icons.shield_outlined, 'Pencegahan',
                'Edukasi & sosialisasi pencegahan.'),
            _buildPillarCard(Icons.gavel_outlined, 'Penanganan',
                'Menangani laporan secara profesional.'),
            _buildPillarCard(Icons.support_agent_outlined, 'Pendampingan',
                'Pendampingan penuh kepada penyintas.'),
            _buildPillarCard(Icons.favorite_outline_rounded, 'Pemulihan',
                'Konseling dan dukungan pemulihan.'),
          ],
        ),
      ],
    );
  }

  Widget _buildPillarCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.center, // Center content vertically
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppConstants.primaryColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            // Removed Expanded to prevent layout issues in varied screen sizes
            desc,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Legal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildLegalTile(
                context,
                icon: Icons.lock_outline_rounded,
                title: 'Kebijakan Privasi',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyPage()),
                  );
                },
              ),
              Divider(height: 1, color: Colors.grey.shade100),
              _buildLegalTile(
                context,
                icon: Icons.description_outlined,
                title: 'Syarat & Ketentuan',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TermsConditionsPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalTile(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: AppConstants.textSecondary, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.textDark,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return SizedBox(
      width: double.infinity, // Ensures centering in parent Column
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
            'Versi ${AppConstants.appVersion}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
