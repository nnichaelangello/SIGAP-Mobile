// Domain Entity — representasi data kasus yang bersih dan type-safe.
//
// Entity ini tidak bergantung pada framework apapun (tidak import Flutter).
// Digunakan di seluruh layer: domain, data, dan presentation.

/// Tingkat urgensi kasus.
enum KasusUrgency {
  darurat('darurat'),
  normal('normal');

  final String value;
  const KasusUrgency(this.value);

  bool get isDarurat => this == KasusUrgency.darurat;
}

/// Status proses kasus.
enum KasusStatus {
  darurat('Darurat'),
  dispute('Dispute'),
  pending('Pending'),
  terjadwal('Terjadwal');

  final String label;
  const KasusStatus(this.label);
}

/// Filter yang tersedia untuk daftar kasus.
enum KasusFilter {
  terbaru('Terbaru'),
  mendesak('Mendesak'),
  hariIni('Hari Ini'),
  mingguIni('Minggu Ini'),
  dispute('Status Dispute');

  final String label;
  const KasusFilter(this.label);
}

/// Immutable model yang merepresentasikan satu item kasus laporan.
class KasusItem {
  final int id;
  final String kode;
  final KasusStatus status;
  final String rawStatus;
  final String info;
  final String waktu;
  final KasusUrgency urgency;

  const KasusItem({
    required this.id,
    required this.kode,
    required this.status,
    required this.rawStatus,
    required this.info,
    required this.waktu,
    required this.urgency,
  });

  bool get isDarurat => urgency.isDarurat;

  /// Mengkonversi ke Map (untuk kompatibilitas dengan UI lama sementara waktu)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode': kode,
      'darurat': isDarurat ? 'darurat' : 'normal',
      'info': info,
      'waktu': waktu,
      'status': status.label,
      'rawStatus': rawStatus,
    };
  }

  KasusItem copyWith({
    int? id,
    String? kode,
    KasusStatus? status,
    String? rawStatus,
    String? info,
    String? waktu,
    KasusUrgency? urgency,
  }) {
    return KasusItem(
      id: id ?? this.id,
      kode: kode ?? this.kode,
      status: status ?? this.status,
      rawStatus: rawStatus ?? this.rawStatus,
      info: info ?? this.info,
      waktu: waktu ?? this.waktu,
      urgency: urgency ?? this.urgency,
    );
  }
}
