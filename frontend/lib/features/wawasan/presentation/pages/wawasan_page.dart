/// Wawasan Feature - Presentation Layer - Main Page (Redesigned)
///
/// Implementasi desain "News App" professional.
/// - Sticky Header & Category
/// - Carousel / Featured Section
/// - Clean List Layout
/// - Focus on Content & Discovery
library wawasan_page;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/wawasan/data/datasources/wawasan_local_datasource.dart';
import 'package:sigap_mobile/features/wawasan/data/repositories/wawasan_repository_impl.dart';
import 'package:sigap_mobile/features/wawasan/domain/entities/article.dart';
import 'package:sigap_mobile/features/wawasan/domain/repositories/wawasan_repository.dart';
import 'package:sigap_mobile/features/wawasan/presentation/widgets/wawasan_header.dart';
import 'package:sigap_mobile/features/wawasan/presentation/widgets/category_filter.dart';
import 'package:sigap_mobile/features/wawasan/presentation/widgets/article_card_widget.dart';
import 'package:sigap_mobile/features/wawasan/presentation/pages/all_articles_page.dart';

class WawasanPage extends StatefulWidget {
  const WawasanPage({super.key});

  @override
  State<WawasanPage> createState() => _WawasanPageState();
}

class _WawasanPageState extends State<WawasanPage> {
  late final WawasanRepository _repository;

  // Data State
  List<Article> _articles = [];
  bool _isLoading = true;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _repository = WawasanRepositoryImpl(
      localDataSource: WawasanLocalDataSource(),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 600));
    final articles = await _repository.getArticles(limit: 5);

    if (mounted) {
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgWhite = Colors.white;

    return Scaffold(
      backgroundColor: bgWhite,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Column(
          children: [
            // 1. Static Modern Header
            const WawasanHeader(),

            // 2. Category Filter
            CategoryFilter(
              selectedIndex: _selectedCategoryIndex,
              onSelect: (index) =>
                  setState(() => _selectedCategoryIndex = index),
            ),

            // 3. Scrollable Content with "Deep UX" Transition
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _isLoading
                    ? const Center(
                        key: ValueKey('loading'),
                        child: CircularProgressIndicator())
                    : NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          // Deep Technique: Hide keyboard on scroll
                          if (notification is ScrollUpdateNotification) {
                            if (notification.scrollDelta! > 10) {
                              FocusManager.instance.primaryFocus?.unfocus();
                            }
                          }
                          return false;
                        },
                        child: CustomScrollView(
                          key: ValueKey<int>(
                              _selectedCategoryIndex), // Important for animation
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 24)),

                            // Featured Article (Top 1) - Only show on "Semua" or specific category
                            if (_articles.isNotEmpty &&
                                _selectedCategoryIndex == 0) ...[
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Editorial Label
                                      Row(
                                        children: [
                                          Container(
                                              width: 20,
                                              height: 1,
                                              color: const Color(0xFF1A1A1A)),
                                          const SizedBox(width: 8),
                                          const Text(
                                            "FOKUS WAWASAN",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 2.0,
                                              color: Color(0xFF1A1A1A),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      ArticleCardWidget(
                                        article: _articles[0],
                                        isFeatured: true,
                                      ),
                                      const SizedBox(height: 32),
                                      const Divider(
                                          height: 1, color: Color(0xFFF9F9F9)),
                                      const SizedBox(height: 32),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Latest Articles List
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedCategoryIndex == 0
                                          ? "TERBARU"
                                          : "ARTIKEL",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        color: Colors.black,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, _, __) =>
                                                const AllArticlesPage(),
                                            transitionDuration: Duration.zero,
                                            reverseTransitionDuration:
                                                Duration.zero,
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Lihat Semua",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 20, 24, 40),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    // Adjust index based on featured
                                    final int actualIndex =
                                        _selectedCategoryIndex == 0
                                            ? index + 1
                                            : index;

                                    if (actualIndex >= _articles.length) {
                                      return null;
                                    }

                                    return Column(
                                      children: [
                                        ArticleCardWidget(
                                            article: _articles[actualIndex]),
                                        if (index < _articles.length - 2)
                                          const Divider(
                                              height: 32,
                                              color: Color(0xFFF5F5F5)),
                                      ],
                                    );
                                  },
                                  childCount: _selectedCategoryIndex == 0
                                      ? _articles.length - 1
                                      : _articles.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
