import '../entities/kasus_item.dart';

/// Kontrak abstrak untuk akses data kasus.
///
/// UI Layer tidak boleh tahu apakah data berasal dari Mock, REST API,
/// WebSocket, atau database lokal. Pattern ini memungkinkan penggantian
/// data source tanpa merombak presentation layer.
///
/// Prinsip:
/// - Inward Dependency Rule: Presentation → Domain (bukan sebaliknya)
/// - Testability: Mudah di-mock untuk unit testing
/// - Scalability: Ganti implementasinya kapan saja tanpa merombak UI
abstract class KasusRepository {
  /// Mengambil daftar kasus berdasarkan role (admin / psikolog).
  Future<List<KasusItem>> getKasusList();

  /// Menerima dan memproses kasus pada [kasusId].
  /// Return `true` jika berhasil.
  Future<bool> terimaKasus(int kasusId);

  /// Menolak kasus pada [kasusId] dengan [alasan] tertentu.
  /// Return `true` jika berhasil.
  Future<bool> tolakKasus(int kasusId, String alasan);

  /// Memulai sesi konsultasi untuk kasus pada [kasusId].
  /// Return `true` jika berhasil.
  Future<bool> mulaiSesi(int kasusId);

  /// Menyelesaikan dan mencatat sesi untuk kasus pada [kasusId].
  /// Return `true` jika berhasil.
  Future<bool> selesaikanSesi(int kasusId, String catatan);
}
