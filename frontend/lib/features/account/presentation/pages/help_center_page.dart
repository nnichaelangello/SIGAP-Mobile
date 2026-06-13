import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Data retrieved from WEBSITE/Landing Page/Landing_Page.html
  final List<Map<String, String>> _allFaqs = [
    {
      'question': 'Apa itu Satgas PPKPT?',
      'answer':
          'Satgas PPKPT (Pencegahan dan Penanganan Kekerasan Seksual) adalah unit di kampus yang bertugas mencegah, menangani, dan memulihkan penyintas kekerasan seksual.',
      'category': 'Umum',
    },
    {
      'question': 'Siapa yang bisa melapor?',
      'answer':
          'Semua anggota komunitas kampus (mahasiswa, dosen, tendik) yang menjadi penyintas, saksi, atau mengetahui adanya kasus.',
      'category': 'Pelaporan',
    },
    {
      'question': 'Apakah ada biaya untuk melapor?',
      'answer':
          'Tidak, seluruh layanan Satgas PPKPT gratis dan tidak dipungut biaya apapun.',
      'category': 'Umum',
    },
    {
      'question': 'Bagaimana jika saya trauma saat menceritakan kejadian?',
      'answer':
          'Tim kami terlatih menangani trauma. Anda bisa berhenti kapan saja dan kami menyediakan konseling psikologis untuk mendampingi masa pemulihan Anda.',
      'category': 'Pendampingan',
    },
    {
      'question': 'Apakah identitas saya akan dijaga kerahasiaannya?',
      'answer':
          'Ya, mutlak. Semua informasi pelapor dilindungi sesuai UU TPKS dan kebijakan kampus. Hanya tim Satgas yang berwenang mengakses data, dan identitas Anda tidak akan dibocorkan kepada siapapun tanpa persetujuan tertulis dari Anda.',
      'category': 'Privasi',
    },
    {
      'question': 'Apa yang langsung saya dapatkan setelah melapor?',
      'answer':
          'Dalam 24 jam pertama, tim akan menghubungi Anda untuk memastikan keselamatan, menawarkan pendampingan psikologis darurat, menjelaskan pilihan langkah hukum, dan memberikan kode monitoring untuk tracking real-time. Tindakan perlindungan akan segera diambil jika diperlukan.',
      'category': 'Proses',
    },
    {
      'question': 'Apakah bisa lapor anonim tanpa identitas?',
      'answer':
          'Bisa, namun laporan anonim memiliki keterbatasan dalam proses penanganan dan perlindungan hukum. Kami menyarankan minimal memberikan kontak yang bisa dihubungi untuk klarifikasi, sambil tetap menjaga privasi penuh identitas Anda.',
      'category': 'Privasi',
    },
    {
      'question': 'Bagaimana jika pelaku adalah dosen atau pejabat kampus?',
      'answer':
          'Satgas PPKPT independen dan tidak terpengaruh oleh jabatan atau posisi pelaku. Semua laporan ditangani dengan standar yang sama. Anda dilindungi dari tindakan retaliasi sesuai regulasi kampus dan UU TPKS.',
      'category': 'Keamanan',
    },
    {
      'question': 'Apakah teman atau keluarga bisa menemani saat melapor?',
      'answer':
          'Sangat bisa dan kami mendorong hal ini. Anda berhak didampingi oleh orang yang Anda percaya selama seluruh proses pelaporan dan investigasi untuk kenyamanan emosional Anda.',
      'category': 'Pendampingan',
    },
    {
      'question': 'Apa yang terjadi jika saya ingin menghentikan proses?',
      'answer':
          'Anda memiliki hak penuh untuk menghentikan atau menarik laporan kapan saja. Keputusan ada di tangan Anda sebagai penyintas. Tim kami akan menghormati pilihan Anda, dan pintu tetap terbuka jika suatu saat Anda ingin melanjutkan kembali.',
      'category': 'Hak',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _allFaqs.where((faq) {
      final query = _searchQuery.toLowerCase();
      return faq['question']!.toLowerCase().contains(query) ||
          faq['answer']!.toLowerCase().contains(query);
    }).toList();

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
                  const SizedBox(height: 24),
                  _buildQuickCategories(),
                  const SizedBox(height: 32),
                  const Text(
                    'Pertanyaan Umum',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredFaqs.isEmpty)
                    _buildEmptyState()
                  else
                    ...filteredFaqs.map((faq) => _buildFaqItem(faq)),
                  const SizedBox(height: 48),
                  _buildContactSupport(),
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
      expandedHeight: 220.0,
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
                    Color(0xFF4B86C6), // Slightly darker shade
                  ],
                ),
              ),
            ),
            // Decorative Patterns
            const Positioned(
              right: -50,
              top: -50,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 250,
                  color: Colors.white,
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    const Text(
                      'Pusat Bantuan',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Temukan jawaban dan panduan\nlengkap seputar layanan SIGAP.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Search Bar inside Header
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari topik bantuan...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppConstants.primaryColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
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

  Widget _buildQuickCategories() {
    final categories = [
      {'icon': Icons.shield_rounded, 'label': 'Keamanan'},
      {'icon': Icons.report_problem_rounded, 'label': 'Laporan'},
      {'icon': Icons.person_rounded, 'label': 'Akun'},
      {'icon': Icons.gavel_rounded, 'label': 'Hukum'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories
          .map((cat) => _buildCategoryItem(
                cat['icon'] as IconData,
                cat['label'] as String,
              ))
          .toList(),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // Future: Filter by category
              },
              child: Icon(icon, color: AppConstants.primaryColor, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFaqItem(Map<String, String> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding:
              const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          title: Text(
            faq['question']!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppConstants.textDark,
            ),
          ),
          iconColor: AppConstants.primaryColor,
          collapsedIconColor: Colors.grey.shade400,
          children: [
            Text(
              faq['answer']!,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Tidak ditemukan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci lain atau lihat kategori bantuan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSupport() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Masih butuh bantuan?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tim Satgas kami siap membantu Anda 24/7.',
            style: TextStyle(
              fontSize: 13,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Live Chat',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.email_outlined,
                  label: 'Email Kami',
                  onTap: () {},
                  isOutlined: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isOutlined ? Colors.white : AppConstants.primaryColor,
            borderRadius: BorderRadius.circular(12),
            border: isOutlined
                ? Border.all(color: AppConstants.primaryColor)
                : null,
            boxShadow: isOutlined
                ? null
                : [
                    BoxShadow(
                      color: AppConstants.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isOutlined ? AppConstants.primaryColor : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isOutlined ? AppConstants.primaryColor : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
