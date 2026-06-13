import 'package:flutter/foundation.dart';
import '../../domain/entities/kasus_item.dart';
import '../../domain/repositories/kasus_repository.dart';

/// State kasus yang di-expose ke presentation layer.
///
/// Menggunakan sealed class agar exhaustive switch di UI terjamin oleh compiler.
sealed class KasusState {
  const KasusState();
}

class KasusInitial extends KasusState {
  const KasusInitial();
}

class KasusLoading extends KasusState {
  const KasusLoading();
}

class KasusLoaded extends KasusState {
  final List<KasusItem> items;
  final KasusFilter activeFilter;

  const KasusLoaded({
    required this.items,
    this.activeFilter = KasusFilter.terbaru,
  });
}

class KasusError extends KasusState {
  final String message;
  const KasusError(this.message);
}

/// Result kecil untuk memberi sinyal UI tentang operasi per-item.
class OperationResult {
  final bool success;
  final String message;
  const OperationResult({required this.success, required this.message});
}

/// Single Source of Truth untuk seluruh business logic kasus satgas.
///
/// ChangeNotifier dipilih karena sudah built-in dan `provider` sudah di-declare
/// pada `pubspec.yaml`. Tidak perlu tambah dependency baru.
///
/// Prinsip arsitektural:
/// - UI hanya memanggil **method** di notifier ini — tidak pernah memodifikasi
///   state secara langsung.
/// - State hanya bisa berubah melalui notifier ini (unidirectional data flow).
/// - Business logic sepenuhnya terpisah dari widget tree = bisa di-unit-test.
/// - Repository di-inject via constructor = bisa di-mock untuk testing.
class SatgasNotifier extends ChangeNotifier {
  final KasusRepository _repository;

  KasusState _state = const KasusInitial();
  KasusState get state => _state;

  /// Lock untuk mencegah double-submit (race condition protection).
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  SatgasNotifier({required KasusRepository repository})
      : _repository = repository;

  // ─────────────────────────────────────────────────────
  //  PUBLIC METHODS (dipanggil oleh UI)
  // ─────────────────────────────────────────────────────

  /// Memuat daftar kasus dari repository.
  Future<void> loadKasus() async {
    _state = const KasusLoading();
    notifyListeners();

    try {
      final items = await _repository.getKasusList();
      _state = KasusLoaded(items: items);
    } catch (e) {
      _state = KasusError('Gagal memuat data: ${e.toString()}');
    }

    notifyListeners();
  }

  /// Mengubah filter aktif (hanya jika state = loaded).
  void changeFilter(KasusFilter filter) {
    final current = _state;
    if (current is KasusLoaded) {
      _state = KasusLoaded(items: current.items, activeFilter: filter);
      notifyListeners();
    }
  }

  /// Menerima kasus. Mengembalikan [OperationResult] untuk feedback UI.
  Future<OperationResult> terimaKasus(int kasusId) async {
    if (_isProcessing) {
      return const OperationResult(
        success: false,
        message: 'Sedang memproses aksi lain.',
      );
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _repository.terimaKasus(kasusId);
      if (success) {
        _removeItemFromState(kasusId);
        return const OperationResult(
          success: true,
          message: 'Status kasus diperbarui: Diterima',
        );
      } else {
        return const OperationResult(
          success: false,
          message: 'Server menolak operasi. Coba lagi.',
        );
      }
    } catch (e) {
      return OperationResult(
        success: false,
        message: 'Gagal menghubungi server: ${e.toString()}',
      );
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Menolak kasus dengan alasan.
  Future<OperationResult> tolakKasus(int kasusId, String alasan) async {
    if (_isProcessing) {
      return const OperationResult(
        success: false,
        message: 'Sedang memproses aksi lain.',
      );
    }

    if (alasan.trim().isEmpty) {
      return const OperationResult(
        success: false,
        message: 'Alasan penolakan wajib diisi.',
      );
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _repository.tolakKasus(kasusId, alasan);
      if (success) {
        _removeItemFromState(kasusId);
        return const OperationResult(
          success: true,
          message: 'Kasus ditolak dan diarsipkan',
        );
      } else {
        return const OperationResult(
          success: false,
          message: 'Server menolak operasi. Coba lagi.',
        );
      }
    } catch (e) {
      return OperationResult(
        success: false,
        message: 'Gagal menghubungi server: ${e.toString()}',
      );
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Memulai sesi konsultasi (untuk Psikolog).
  Future<OperationResult> mulaiSesi(int kasusId) async {
    if (_isProcessing) {
      return const OperationResult(
        success: false,
        message: 'Sedang memproses aksi lain.',
      );
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _repository.mulaiSesi(kasusId);
      if (success) {
        return const OperationResult(
          success: true,
          message: 'Link meeting dikirim ke mahasiswa',
        );
      } else {
        return const OperationResult(
          success: false,
          message: 'Gagal memulai sesi.',
        );
      }
    } catch (e) {
      return OperationResult(
        success: false,
        message: 'Gagal menghubungi server: ${e.toString()}',
      );
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Menyelesaikan sesi dan menyimpan catatan (untuk Psikolog).
  Future<OperationResult> selesaikanSesi(int kasusId, String catatan) async {
    if (_isProcessing) {
      return const OperationResult(
        success: false,
        message: 'Sedang memproses aksi lain.',
      );
    }

    if (catatan.trim().isEmpty) {
      return const OperationResult(
        success: false,
        message: 'Catatan sesi wajib diisi.',
      );
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _repository.selesaikanSesi(kasusId, catatan);
      if (success) {
        _removeItemFromState(kasusId);
        return const OperationResult(
          success: true,
          message: 'Sesi ditutup & catatan tersimpan',
        );
      } else {
        return const OperationResult(
          success: false,
          message: 'Gagal menyimpan catatan.',
        );
      }
    } catch (e) {
      return OperationResult(
        success: false,
        message: 'Gagal menghubungi server: ${e.toString()}',
      );
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────
  //  PRIVATE HELPERS
  // ─────────────────────────────────────────────────────

  /// Menghapus item dari daftar state secara immutable.
  void _removeItemFromState(int kasusId) {
    final current = _state;
    if (current is KasusLoaded) {
      final updated = current.items.where((k) => k.id != kasusId).toList();
      _state = KasusLoaded(items: updated, activeFilter: current.activeFilter);
    }
  }

  /// Helper: Jumlah kasus darurat (untuk summary card).
  int get jumlahDarurat {
    final current = _state;
    if (current is KasusLoaded) {
      return current.items.where((k) => k.isDarurat).length;
    }
    return 0;
  }

  /// Helper: Total item di antrean.
  int get totalAntrean {
    final current = _state;
    if (current is KasusLoaded) {
      return current.items.length;
    }
    return 0;
  }
}
