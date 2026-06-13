import 'package:sigap_mobile/features/lapor/domain/entities/report_entity.dart';

class ReportModel extends ReportEntity {
  const ReportModel({
    required super.id,
    required super.trackingCode,
    required super.penyintas,
    required super.tingkatKekhawatiran,
    required super.genderPenyintas,
    required super.pelakuKekerasan,
    required super.waktuKejadian,
    required super.lokasiKategori,
    super.lokasiDetail,
    required super.detailKejadian,
    super.emailPenyintas,
    required super.usiaPenyintas,
    required super.isDisabilitas,
    super.jenisDisabilitas,
    super.whatsappPenyintas,
    required super.createdAt,
    required super.status,
    required super.reporterId,
    super.isAnonymous = false,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id']?.toString() ?? '',
      trackingCode: json['tracking_code'] ?? '',
      penyintas: json['penyintas'] ?? '',
      tingkatKekhawatiran: json['tingkat_kekhawatiran'] ?? '',
      genderPenyintas: json['gender_penyintas'] ?? '',
      pelakuKekerasan: json['pelaku_kekerasan'] ?? '',
      waktuKejadian: json['waktu_kejadian'] != null
          ? DateTime.parse(json['waktu_kejadian'])
          : DateTime.now(),
      lokasiKategori: json['lokasi_kategori'] ?? '',
      lokasiDetail: json['lokasi_detail'],
      detailKejadian: json['detail_kejadian'] ?? '',
      emailPenyintas: json['email_penyintas'],
      usiaPenyintas: json['usia_penyintas'] ?? '',
      isDisabilitas: json['is_disabilitas'] ?? false,
      jenisDisabilitas: json['jenis_disabilitas'],
      whatsappPenyintas: json['whatsapp_penyintas'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      status: json['status'] ?? 'pending',
      reporterId: json['reporter_id'] ?? '',
      isAnonymous: json['is_anonymous'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tracking_code': trackingCode,
      'penyintas': penyintas,
      'tingkat_kekhawatiran': tingkatKekhawatiran,
      'gender_penyintas': genderPenyintas,
      'pelaku_kekerasan': pelakuKekerasan,
      'waktu_kejadian': waktuKejadian.toIso8601String(),
      'lokasi_kategori': lokasiKategori,
      'lokasi_detail': lokasiDetail,
      'detail_kejadian': detailKejadian,
      'email_penyintas': emailPenyintas,
      'usia_penyintas': usiaPenyintas,
      'is_disabilitas': isDisabilitas,
      'jenis_disabilitas': jenisDisabilitas,
      'whatsapp_penyintas': whatsappPenyintas,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'reporter_id': reporterId,
      'is_anonymous': isAnonymous,
    };
  }
}
