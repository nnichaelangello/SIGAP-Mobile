/// Wawasan Feature - Domain Layer - Repositories (Abstract)
///
/// Interface untuk repository Wawasan.
/// Layer Presentation dan UseCase hanya bergantung pada interface ini,
/// bukan implementasi konkret. Ini memungkinkan dependency injection
/// dan testability yang lebih baik.
library wawasan_repository;

import 'package:sigap_mobile/features/wawasan/domain/entities/education_card.dart';
import 'package:sigap_mobile/features/wawasan/domain/entities/report_step.dart';
import 'package:sigap_mobile/features/wawasan/domain/entities/article.dart';

abstract class WawasanRepository {
  /// Mengambil semua konten Edukasi (Kapan Harus Lapor).
  Future<List<EducationCard>> getEducationCards();

  /// Mengambil langkah-langkah pelaporan berdasarkan kategori.
  Future<List<ReportStep>> getReportSteps(ReportStepCategory category);

  /// Mengambil daftar artikel terbaru.
  /// [limit] menentukan jumlah maksimal artikel yang diambil.
  Future<List<Article>> getArticles({int limit = 4});

  /// Mencari artikel berdasarkan query
  Future<List<Article>> searchArticles(String query);

  /// Mengambil detail artikel berdasarkan ID.
  Future<Article?> getArticleById(String id);
}
