import 'dart:io';
import 'package:flutter/foundation.dart';

/// Flag file untuk sinkronisasi status AMAN antara overlay engine dan main engine.
///
/// KENAPA FILE, BUKAN IPC?
/// FlutterOverlayWindow.shareData menggunakan EventChannel (broadcast stream).
/// Broadcast stream TIDAK buffer events — jika receiver suspended, event hilang.
/// File system selalu tersedia dan shared antara kedua engine karena
/// keduanya berjalan di Android process yang sama (com.sigap.sigap_mobile).
///
/// ALUR:
///   1. User tekan AMAN di overlay → overlay tulis flag ke file
///   2. User buka app → main app baca flag dari file
///   3. Flag ada & valid → langsung _konfirmasiAman(), skip check-in view
///   4. Flag dihapus setelah diproses
class PantauAmanFlag {
  PantauAmanFlag._();

  // Path di temp directory — shared antara main engine dan overlay engine.
  // Dart's Directory.systemTemp pada Android mengembalikan cache dir app.
  static String get _path => '${Directory.systemTemp.path}/sigap_aman_flag';

  /// Tulis flag AMAN — dipanggil oleh overlay saat user tekan tombol AMAN.
  /// Isi file = epoch milliseconds saat AMAN ditekan, untuk validasi freshness.
  static Future<void> tulis() async {
    try {
      await File(_path).writeAsString(
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } catch (e) {
      debugPrint('[PantauAmanFlag] Gagal tulis flag: $e');
    }
  }

  /// Cek synchronous — untuk situasi yang butuh blocking check (lifecycle).
  /// Return true jika flag ada dan masih valid (kurang dari 2 menit).
  static bool adaSync() {
    try {
      final file = File(_path);
      if (!file.existsSync()) return false;
      final content = file.readAsStringSync().trim();
      final timestamp = int.tryParse(content);
      if (timestamp == null) return false;
      final umurMs = DateTime.now().millisecondsSinceEpoch - timestamp;
      return umurMs >= 0 && umurMs < 120000;
    } catch (e) {
      debugPrint('[PantauAmanFlag] Gagal baca flag: $e');
      return false;
    }
  }

  /// Hapus flag — dipanggil setelah AMAN berhasil diproses,
  /// atau saat check-in baru dimulai (supaya flag lama tidak bocor).
  static void hapus() {
    try {
      final file = File(_path);
      if (file.existsSync()) file.deleteSync();
    } catch (e) {
      debugPrint('[PantauAmanFlag] Gagal hapus flag: $e');
    }
  }
}
