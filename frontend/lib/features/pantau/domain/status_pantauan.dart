/// Representasi eksplisit state machine fitur Pantau Aku.
///
/// Menggantikan `int _state` (0/1/2) + variabel lepas yang sebelumnya
/// tersebar di PantauPage. Sealed class menjamin:
///   - Setiap state punya data yang relevan dan HANYA data itu.
///   - Compiler memaksa exhaustive check di switch.
///   - Tidak mungkin masuk state ilegal (misal: aktif tapi kesempatan=3).
sealed class StatusPantauan {
  const StatusPantauan();
}

/// State awal — user memilih interval dan menyiapkan pemantauan.
class Persiapan extends StatusPantauan {
  const Persiapan();
}

/// Pantauan berjalan — countdown menuju check-in berikutnya.
class Aktif extends StatusPantauan {
  final int sisaDetik;
  final int intervalDetik;

  const Aktif({
    required this.sisaDetik,
    required this.intervalDetik,
  });
}

/// Check-in diminta — user harus konfirmasi AMAN.
class CheckInDiminta extends StatusPantauan {
  final int sisaDetik;
  final int kesempatan; // 1, 2, atau >=3 (final)
  final DateTime waktuMulai;

  const CheckInDiminta({
    required this.sisaDetik,
    required this.kesempatan,
    required this.waktuMulai,
  });
}

/// Sinyal darurat telah dikirim — pantauan berakhir.
class DaruratTerkirim extends StatusPantauan {
  const DaruratTerkirim();
}
