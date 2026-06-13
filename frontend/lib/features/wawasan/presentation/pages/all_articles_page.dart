/// LIHAT SEMUA PAGE
///
/// Halaman daftar lengkap untuk browsing konten tanpa batas.
/// Fokus pada Infinite Scroll experience (simulated).
library all_articles_page;

import 'package:flutter/material.dart';
import 'package:sigap_mobile/features/wawasan/data/repositories/wawasan_repository_impl.dart';
import 'package:sigap_mobile/features/wawasan/data/datasources/wawasan_local_datasource.dart';
import 'package:sigap_mobile/features/wawasan/domain/entities/article.dart';
import 'package:sigap_mobile/features/wawasan/presentation/widgets/article_card_widget.dart';

class AllArticlesPage extends StatefulWidget {
  const AllArticlesPage({super.key});

  @override
  State<AllArticlesPage> createState() => _AllArticlesPageState();
}

class _AllArticlesPageState extends State<AllArticlesPage> {
  final _repository =
      WawasanRepositoryImpl(localDataSource: WawasanLocalDataSource());
  List<Article> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Get more articles for "All" view
    final articles = await _repository.getArticles(limit: 10);
    if (mounted) {
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Semua Artikel",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _articles.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 48, color: Color(0xFFF5F5F5)),
              itemBuilder: (context, index) {
                return ArticleCardWidget(article: _articles[index]);
              },
            ),
    );
  }
}
