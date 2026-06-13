import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../presentation/pages/emergency_live_tracking_page.dart';

/// Handler yang bertugas menerima payload notifikasi darurat
/// dan menavigasi user ke halaman Live Tracking.
///
/// Didesain agar bisa dipanggil dari mana saja:
/// - Dari tap notifikasi lokal (flutter_local_notifications onTap)
/// - Dari tap notifikasi FCM (jika nanti ditambahkan)
/// - Dari event internal (misal PantauService trigger darurat)
///
/// Menggunakan GlobalKey<NavigatorState> agar tidak butuh BuildContext.
class EmergencyNotificationHandler {
  /// NavigatorKey yang sama dengan yang disuntikkan ke MaterialApp
  final GlobalKey<NavigatorState> navigatorKey;

  static const String responderChannelId = 'responder_siren_channel';
  static const int responderNotificationId = 911;

  EmergencyNotificationHandler({required this.navigatorKey});

  /// 1. Mendaftarkan Speaker Sirine Khusus di HP Penolong
  /// (Dipanggil sekali di main.dart saat aplikasi penolong dibuka)
  static Future<void> initializeResponderChannel() async {
    // Pola getaran sirine berat: Getar 2 detik, Jeda 0.5 detik (Berulang gaya Ambulans/Siren)
    final Int64List sirenVibration =
        Int64List.fromList([0, 2000, 500, 2000, 500, 2000]);

    final AndroidNotificationChannel responderChannel =
        AndroidNotificationChannel(
      responderChannelId,
      'Panggilan Darurat Masuk',
      description: 'Sirine kencang berlapis ketika ada teman minta tolong',
      importance: Importance.max, // TEMBUS DND (DO NOT DISTURB)
      enableVibration: true,
      vibrationPattern: sirenVibration,
      playSound: true,
    );

    await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(responderChannel);
  }

  /// 2. Fungsi untuk Menembakkan Sirine di layar Kunci Penolong
  /// (Dipanggil saat notifikasi FCM latar belakang masuk)
  static Future<void> showResponderSiren(String incidentId) async {
    const title = "🆘 TEMAN ANDA BUTUH BANTUAN!";
    const content = "Darurat! Ketuk untuk melacak lokasi secara LIVE.";

    await FlutterLocalNotificationsPlugin().show(
      responderNotificationId,
      title,
      content,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          responderChannelId,
          'Panggilan Darurat Masuk',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          playSound: true,
          fullScreenIntent: true, // Memaksa Layar HP Penolong Menyala
          color: Color(0xFFFF0000),
        ),
      ),
    );
  }

  /// Mem-parsing payload mentah dari notifikasi, lalu navigasi ke peta.
  ///
  /// Format payload yang diharapkan (Map<String, dynamic>):
  /// {
  ///   "type": "EMERGENCY_DISPATCH",
  ///   "incident_id": "REQ-00234X",
  ///   "lat": "-7.275000",
  ///   "lng": "112.792000"
  /// }
  ///
  /// Mengembalikan true jika berhasil navigasi, false jika payload tidak valid.
  bool handlePayload(Map<String, dynamic>? payload) {
    if (payload == null) return false;

    final String? type = payload['type'] as String?;
    if (type != 'EMERGENCY_DISPATCH') return false;

    final String? incidentId = payload['incident_id'] as String?;
    final String? latStr = payload['lat'] as String?;
    final String? lngStr = payload['lng'] as String?;

    // Validasi ketat — tidak boleh ada data yang kosong
    if (incidentId == null || latStr == null || lngStr == null) {
      debugPrint('[EmergencyHandler] Payload tidak lengkap: $payload');
      return false;
    }

    final double? lat = double.tryParse(latStr);
    final double? lng = double.tryParse(lngStr);

    if (lat == null || lng == null) {
      debugPrint(
          '[EmergencyHandler] Koordinat tidak valid: lat=$latStr, lng=$lngStr');
      return false;
    }

    // Navigasi ke halaman darurat menggunakan navigatorKey (tanpa context)
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint(
          '[EmergencyHandler] NavigatorState belum siap (app belum mounted?)');
      return false;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => EmergencyLiveTrackingWrapper(
          incidentId: incidentId,
          initialKorbanLocation: LatLng(lat, lng),
        ),
      ),
    );

    return true;
  }

  /// Shortcut untuk navigasi langsung jika data sudah terstruktur.
  /// Digunakan oleh komponen internal (misal: tombol di service_grid).
  void navigateToTracking({
    required String incidentId,
    required double lat,
    required double lng,
  }) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => EmergencyLiveTrackingWrapper(
          incidentId: incidentId,
          initialKorbanLocation: LatLng(lat, lng),
        ),
      ),
    );
  }
}
