import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/wawasan/domain/entities/article.dart';

/// Halaman Baca Artikel (The Reader)
/// Desain fokus pada kenyamanan membaca (Zero-Distraction).
/// - Typography-centric
/// - Warm background (Paper-like)
/// - Immersive reading experience
class ArticleDetailPage extends StatefulWidget {
  final Article article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  // Reading preferences state
  final double _fontSize = 16.0;
  final ScrollController _scrollController = ScrollController();
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateProgress);
  }

  void _updateProgress() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0) {
      final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      setState(() {
        _progress = progress;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // "Warm Paper" Theme colors
    const Color bgPaper = Color(0xFFF9F9F9);
    const Color textInk = Color(0xFF2C2C2C);
    const Color textSecondary = Color(0xFF666666);

    return Scaffold(
      backgroundColor: bgPaper,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Minimized AppBar with Progress Indicator
                SliverAppBar(
                  backgroundColor: bgPaper,
                  elevation: 0,
                  pinned: true,
                  floating: false,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: textInk, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.bookmark_border_rounded,
                          color: textInk),
                      onPressed: () {}, // Save functionality
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: textInk),
                      onPressed: () {}, // Share functionality
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Progress bar at the bottom of AppBar
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(2),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppConstants.primaryColor.withValues(alpha: 0.5)),
                      minHeight: 2,
                    ),
                  ),
                ),

                // 2. Content Body
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Image (Hero) matched with Card layout
                        Hero(
                          tag: 'image_${widget.article.id}',
                          child: Container(
                            height: 240,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: AssetImage(widget.article.imageUrl),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.08),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Image Caption
                        Center(
                          child: Text(
                            "Ilustrasi oleh Tim Kreatif SIGAP",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Category & Date
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.article.category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppConstants.primaryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.article.formattedDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.access_time_rounded,
                                size: 14, color: textSecondary),
                            const SizedBox(width: 4),
                            const Text(
                              "4 min baca", // Estimasi waktu baca
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title (Hero)
                        Hero(
                          tag: 'title_${widget.article.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              widget.article.title,
                              style: const TextStyle(
                                fontSize: 24, // Slightly adjusted for balance
                                fontWeight: FontWeight.w800,
                                color: textInk,
                                height: 1.3,
                                letterSpacing: -0.5,
                                fontFamily: 'Serif',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Article Content
                        _buildArticleContent(textInk),

                        const SizedBox(height: 56),

                        // "Read Next" / Related (Seamless transition)
                        const Divider(color: Colors.black12),
                        const SizedBox(height: 24),
                        const Text(
                          "Lanjutkan Membaca",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textInk,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRelatedCard(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleContent(Color color) {
    if (widget.article.content == null) {
      return Text(
        "Konten artikel tidak tersedia.",
        style: TextStyle(fontSize: 14, color: color.withValues(alpha: 0.5)),
      );
    }

    final paragraphs = widget.article.content!.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lead excerpt
        Text(
          widget.article.excerpt,
          style: TextStyle(
            fontSize: _fontSize + 2, // Lead paragraph slightly larger
            fontWeight: FontWeight.w500,
            color: color.withValues(alpha: 0.95),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),

        // Dynamic content
        ...paragraphs.map((p) {
          if (p.trim().isEmpty) return const SizedBox.shrink();

          if (p.trim().length < 80 && !p.contains('.') && p.contains(':')) {
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12),
              child: Text(
                p.trim(),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                    color: Color(0xFF2C2C2C)),
              ),
            );
          }

          if (p.trim().startsWith('1.') || p.trim().startsWith('*')) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• ",
                      style: TextStyle(
                          fontSize: _fontSize,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Expanded(
                    child: Text(
                      p.trim().replaceAll(RegExp(r'^[0-9*.]+\s*'), ''),
                      style: TextStyle(
                        fontSize: _fontSize,
                        color: color.withValues(alpha: 0.85),
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              p.trim(),
              style: TextStyle(
                fontSize: _fontSize,
                color: color.withValues(alpha: 0.85),
                height: 1.8,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRelatedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.article_rounded, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Panduan Pelaporan Aman",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Langkah demi langkah melapor tanpa rasa takut.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.grey.shade400,
          )
        ],
      ),
    );
  }
}
