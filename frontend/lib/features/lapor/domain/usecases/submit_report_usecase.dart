import 'package:sigap_mobile/core/result/data_result.dart';
import 'package:sigap_mobile/features/lapor/domain/entities/report_entity.dart';
import 'package:sigap_mobile/features/lapor/domain/repositories/report_repository.dart';

class SubmitReportUseCase {
  final ReportRepository repository;

  SubmitReportUseCase(this.repository);

  Future<DataResult<ReportEntity>> execute({
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
    // Domain Business Validation
    if (detailKejadian.trim().length < 10) {
      return const Error("Detail kejadian minimal 10 karakter");
    }

    if (isDisabilitas &&
        (jenisDisabilitas == null || jenisDisabilitas.isEmpty)) {
      return const Error(
          "Jenis disabilitas wajib dipilih jika penyintas memiliki disabilitas");
    }

    return await repository.submitReport(
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
  }
}
