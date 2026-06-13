import 'package:http/http.dart' as http;
import 'package:sigap_mobile/core/services/api_service.dart';
import 'package:sigap_mobile/features/lapor/data/models/report_model.dart';

abstract class ReportRemoteDataSource {
  Future<ReportModel> submitReport({
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

  Future<List<ReportModel>> getReportsByUser(String userId);
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  ReportRemoteDataSourceImpl(
      {required this.client, this.baseUrl = 'http://localhost:8080/api'});

  @override
  Future<ReportModel> submitReport({
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
    // Kirim laporan ke Go backend
    final resp = await ApiService.instance.post('/api/reports', {
      'jenis_penyintas': penyintas,
      'kategori_kekhawatiran': tingkatKekhawatiran,
      'gender_pelaku': genderPenyintas,
      'hubungan_pelaku': pelakuKekerasan,
      'detail_kejadian': detailKejadian,
      'email_penyintas': emailPenyintas ?? '',
    });

    if (resp.success && resp.data != null) {
      final d = resp.data!;
      return ReportModel(
        id: d['report_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        trackingCode: d['tracking_code'] ?? 'SIGAP-ERROR',
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
        createdAt: DateTime.now(),
        status: 'pending',
        reporterId: reporterId,
        isAnonymous: isAnonymous,
      );
    } else {
      throw Exception(resp.error ?? 'Gagal mengirim laporan ke server');
    }
  }

  @override
  Future<List<ReportModel>> getReportsByUser(String userId) async {
    final resp = await ApiService.instance.get('/api/reports');

    if (resp.success && resp.data != null) {
      final items = resp.data!['data'] as List? ?? [];
      return items.map((item) {
        return ReportModel(
          id: item['id']?.toString() ?? '',
          trackingCode: item['tracking_code'] ?? 'SIGAP-UNKNOWN',
          penyintas: item['jenis_penyintas'] ?? '',
          tingkatKekhawatiran: item['kategori_kekhawatiran'] ?? '',
          genderPenyintas: item['gender_pelaku'] ?? '',
          pelakuKekerasan: item['hubungan_pelaku'] ?? '',
          waktuKejadian: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
          lokasiKategori: '',
          detailKejadian: item['detail_kejadian'] ?? '',
          usiaPenyintas: '',
          isDisabilitas: false,
          createdAt: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
          status: item['status'] ?? 'pending',
          reporterId: item['user_id']?.toString() ?? '',
          isAnonymous: false,
        );
      }).toList();
    }

    return [];
  }
}
