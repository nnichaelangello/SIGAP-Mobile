import 'package:sigap_mobile/core/result/data_result.dart';
import 'package:sigap_mobile/features/lapor/domain/entities/report_entity.dart';

abstract class ReportRepository {
  /// Mengirim laporan baru ke server dari Form 6-Langkah
  Future<DataResult<ReportEntity>> submitReport({
    required String penyintas,
    required String tingkatKekhawatiran,
    required String genderPenyintas,
    required String pelakuKekerasan,
    required DateTime waktuKejadian,
    required String lokasiKategori,
    String? lokasiDetail,
    required String detailKejadian,
    String? emailPenyintas,
    required String usiaPenyintas,
    required bool isDisabilitas,
    String? jenisDisabilitas,
    String? whatsappPenyintas,
    bool isAnonymous = false,
    required String reporterId,
  });

  /// Mengambil daftar laporan berdasarkan user ID
  Future<DataResult<List<ReportEntity>>> getReportsByUser(String userId);
}
