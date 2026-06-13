class ReportEntity {
  final String id;
  // Step 2 & 3
  final String penyintas; // "saya" atau "oranglain"
  final String tingkatKekhawatiran; // "sedikit", "khawatir", "sangat"
  // Step 4
  final String genderPenyintas; // "lakilaki", "perempuan"
  // Step 5
  final String pelakuKekerasan; // "dosen", "satpam", dll
  // Step 6
  final DateTime waktuKejadian;
  final String lokasiKategori; // "Gedung Utama", "Masjid", dll
  final String? lokasiDetail; // Opsional
  final String detailKejadian; // Minimum 10 max 200 karakter
  // Step 7
  final String? emailPenyintas;
  final String usiaPenyintas; // "12-17", dsb.
  final bool isDisabilitas;
  final String? jenisDisabilitas;
  final String? whatsappPenyintas;

  // System Fields
  final DateTime createdAt;
  final String status;
  final String reporterId;
  final bool isAnonymous;
  final String trackingCode;

  const ReportEntity({
    required this.id,
    required this.trackingCode,
    required this.penyintas,
    required this.tingkatKekhawatiran,
    required this.genderPenyintas,
    required this.pelakuKekerasan,
    required this.waktuKejadian,
    required this.lokasiKategori,
    this.lokasiDetail,
    required this.detailKejadian,
    this.emailPenyintas,
    required this.usiaPenyintas,
    required this.isDisabilitas,
    this.jenisDisabilitas,
    this.whatsappPenyintas,
    required this.createdAt,
    required this.status,
    required this.reporterId,
    this.isAnonymous = false,
  });
}
