import '../../domain/entities/kasus_item.dart';
import '../../domain/repositories/kasus_repository.dart';
import 'package:sigap_mobile/core/services/api_service.dart';

/// Tipe role satgas yang menentukan sumber data.
enum SatgasRole { admin, psikolog }

/// Implementasi API dari [KasusRepository].
///
/// Menghubungkan presentation layer ke Go backend secara langsung
/// melalui [ApiService] singleton.
class ApiKasusRepository implements KasusRepository {
  final SatgasRole role;

  ApiKasusRepository({required this.role});

  @override
  Future<List<KasusItem>> getKasusList() async {
    final resp = await ApiService.instance.get('/api/reports');

    if (!resp.success || resp.data == null) {
      throw Exception(resp.error ?? 'Gagal mengambil data laporan');
    }

    final itemsList = resp.data!['data'] as List? ?? [];
    return itemsList.map((item) {
      final status = item['status']?.toString() ?? 'pending';
      final kategori = item['kategori_kekhawatiran'] ?? '';
      
      return KasusItem(
        id: item['id'] ?? 0,
        kode: item['tracking_code'] ?? 'SIGAP-???',
        status: _mapStatus(status),
        rawStatus: status,
        info: item['detail_kejadian'] ?? '',
        waktu: _formatWaktu(item['created_at'] ?? ''),
        urgency: kategori.toString().toLowerCase().contains('darurat')
            ? KasusUrgency.darurat
            : KasusUrgency.normal,
      );
    }).toList();
  }

  @override
  Future<bool> terimaKasus(int kasusId) async {
    final resp = await ApiService.instance.put('/api/reports/status', {
      'report_id': kasusId,
      'status': 'diterima',
    });
    return resp.success;
  }

  @override
  Future<bool> tolakKasus(int kasusId, String alasan) async {
    final resp = await ApiService.instance.put('/api/reports/status', {
      'report_id': kasusId,
      'status': 'ditolak',
      'alasan_tolak': alasan,
    });
    return resp.success;
  }

  @override
  Future<bool> mulaiSesi(int kasusId) async {
    // Untuk psikolog: mengubah status menjadi 'diproses'
    final resp = await ApiService.instance.put('/api/reports/status', {
      'report_id': kasusId,
      'status': 'diproses',
    });
    return resp.success;
  }

  @override
  Future<bool> selesaikanSesi(int kasusId, String catatan) async {
    final resp = await ApiService.instance.put('/api/reports/status', {
      'report_id': kasusId,
      'status': 'selesai',
      'catatan_psikolog': catatan,
    });
    return resp.success;
  }

  // ─────────────────────────────────────────────────────
  //  PRIVATE HELPERS
  // ─────────────────────────────────────────────────────

  KasusStatus _mapStatus(String status) {
    switch (status) {
      case 'pending':
        return KasusStatus.pending;
      case 'diterima':
        return KasusStatus.terjadwal;
      case 'dijadwalkan':
        return KasusStatus.terjadwal;
      case 'diproses':
        return KasusStatus.terjadwal;
      case 'selesai':
        return KasusStatus.terjadwal; // tampilkan sebagai selesai via label
      case 'ditolak':
        return KasusStatus.dispute;
      default:
        return KasusStatus.pending;
    }
  }

  String _formatWaktu(String isoDateTime) {
    if (isoDateTime.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoDateTime);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDateTime;
    }
  }
}
