/// Wawasan Feature - Domain Layer - Entities
///
/// Entity untuk langkah-langkah pelaporan (Cara Lapor).
class ReportStep {
  final int stepNumber;
  final String iconName; // Using string for flexibility (FontAwesome/Material)
  final String title;
  final String description;
  final bool isImportant; // For "Langkah Penting" tab

  const ReportStep({
    required this.stepNumber,
    required this.iconName,
    required this.title,
    required this.description,
    this.isImportant = false,
  });
}

/// Enum untuk kategori tab Cara Lapor.
enum ReportStepCategory {
  online, // Lapor Daring
  important, // Langkah Penting
}
