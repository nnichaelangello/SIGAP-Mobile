/// Wawasan Feature - Domain Layer - Entities
///
/// Entity untuk konten Edukasi (Kapan Harus Lapor).
/// Ini adalah objek bisnis inti, bebas dari framework.
class EducationCard {
  final String id;
  final String title;
  final String imageAsset;
  final String contentTitle;
  final String description;
  final List<String> keyPoints;
  final List<String>? actionSteps;
  final bool isEmergency;

  const EducationCard({
    required this.id,
    required this.title,
    required this.imageAsset,
    required this.contentTitle,
    required this.description,
    required this.keyPoints,
    this.actionSteps,
    this.isEmergency = false,
  });
}
