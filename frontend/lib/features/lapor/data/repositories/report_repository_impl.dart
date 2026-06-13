import 'package:sigap_mobile/core/result/data_result.dart';
import 'package:sigap_mobile/features/lapor/data/datasources/report_remote_data_source.dart';
import 'package:sigap_mobile/features/lapor/domain/entities/report_entity.dart';
import 'package:sigap_mobile/features/lapor/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource remoteDataSource;

  ReportRepositoryImpl({required this.remoteDataSource});

  @override
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
  }) async {
    try {
      final remoteReport = await remoteDataSource.submitReport(
        penyintas: penyintas,
        tingkatKekhawatiran: tingkatKekhawatiran,
        genderPenyintas: genderPenyintas,
        pelakuKekerasan: pelakuKekerasan,
        waktuKejadian: waktuKejadian,
        lokasiKategori: lokasiKategori,
        lokasiDetail: lokasiDetail,
        detailKejadian: detailKejadian,
        emailPenyintas: emailPenyintas,
        usiaPenyintas: usiaPenyintas,
        isDisabilitas: isDisabilitas,
        jenisDisabilitas: jenisDisabilitas,
        whatsappPenyintas: whatsappPenyintas,
        isAnonymous: isAnonymous,
        reporterId: reporterId,
      );
      return Success(remoteReport);
    } catch (e) {
      return Error("Terjadi kesalahan jaringan: ${e.toString()}");
    }
  }

  @override
  Future<DataResult<List<ReportEntity>>> getReportsByUser(String userId) async {
    try {
      final remoteReports = await remoteDataSource.getReportsByUser(userId);
      return Success(remoteReports);
    } catch (e) {
      return const Error("Gagal mengambil riwayat laporan");
    }
  }
}
