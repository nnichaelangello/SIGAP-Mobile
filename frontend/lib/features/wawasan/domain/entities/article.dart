/// Wawasan Feature - Domain Layer - Entities
///
/// Entity untuk artikel/berita (Kabar Sigap).
class Article {
  final String id;
  final String title;
  final String excerpt;
  final String imageUrl;
  final String category;
  final DateTime publishedAt;
  final String? author;
  final String? contentUrl; // Link to full article
  final String? content; // Article body content

  const Article({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.imageUrl,
    required this.category,
    required this.publishedAt,
    this.author,
    this.contentUrl,
    this.content,
  });

  /// Format tanggal untuk ditampilkan di UI.
  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${publishedAt.day} ${months[publishedAt.month - 1]} ${publishedAt.year}';
  }
}
