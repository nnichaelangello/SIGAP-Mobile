// Wawasan Feature - Presentation Layer - Widgets
//
// Widget kartu artikel dengan desain "Zero-Thinking".
// Bersih, minim distraksi, fokus pada konten visual dan judul.
library article_card_widget;

import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/wawasan/domain/entities/article.dart';
import 'package:sigap_mobile/features/wawasan/presentation/pages/article_detail_page.dart';

class ArticleCardWidget extends StatelessWidget {
  final Article article;
  final bool isFeatured; // Layout opsi besar untuk headline

  const ArticleCardWidget({
    super.key,
    required this.article,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isFeatured) {
      return _buildFeaturedLayout(context);
    }
    return _buildStandardLayout(context);
  }

  // Layout untuk Headline (Besar, Image di atas)
  Widget _buildFeaturedLayout(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Hero(
              tag: 'image_${article.id}',
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: AssetImage(article.imageUrl),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.08),
                        blurRadius: 16,
                        offset: Offset(0, 8)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Meta
            _buildMetaRow(),

            const SizedBox(height: 8),
            // Title
            Hero(
              tag: 'title_${article.id}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                    height: 1.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Excerpt
            Text(
              article.excerpt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Layout Standard (List, Image di samping)
  Widget _buildStandardLayout(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        color: Colors.transparent, // Ensure hit test works on padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Thumbnail
            Hero(
              tag: 'image_${article.id}',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: AssetImage(article.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMetaRow(isSmall: true),
                  const SizedBox(height: 6),
                  Hero(
                    tag: 'title_${article.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2C2C), // Ink Black
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow({bool isSmall = false}) {
    return Row(
      children: [
        Text(
          article.category.toUpperCase(),
          style: TextStyle(
            fontSize: isSmall ? 10 : 11,
            fontWeight: FontWeight.w700,
            color: AppConstants.primaryColor,
            letterSpacing: 0.5,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade400,
          ),
        ),
        Text(
          article.formattedDate,
          style: TextStyle(
            fontSize: isSmall ? 10 : 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ArticleDetailPage(article: article),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Deep UX: Fade ends slightly before Hero arrives to prevent overlap
          // Also, adding a tiny scale effect to the background can help
          return FadeTransition(
            opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.8, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );
  }
}
