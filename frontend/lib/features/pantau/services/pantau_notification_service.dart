import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:geolocator/geolocator.dart'; // Import GPS Heartbeat
import 'package:sigap_mobile/features/pantau/services/pantau_aman_flag.dart';

@pragma('vm:entry-point')
void onNotificationActionTriggered(NotificationResponse response) {
  if (response.actionId == 'btn_aman') {
    debugPrint(
        '[PantauNotificationService] SAYA AMAN ditekan dari luar aplikasi!');
    // Tulis flag. Karena timer berjalan terus, di detik berikutnya ia akan membaca flag ini.
    PantauAmanFlag.tulis();
    // Tutup langsung notif berisik ini
    FlutterLocalNotificationsPlugin()
        .cancel(PantauNotificationService.stealthNotificationId);
  }
}

class PantauNotificationService {
  static const String notificationChannelId = 'pantau_aman_channel';
  static const String stealthChannelId =
      'pantau_aman_stealth_channel'; // Channel SILUMAN untuk Korban
  static const int notificationId = 888;
  static const int stealthNotificationId =
      889; // ID notif khusus yang bergetar sangat halus

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // 1. Channel Biasa (Background Service standar)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Status Pantauan',
      description: 'Menampilkan sisa waktu pantauan yang sedang berjalan',
      importance: Importance
          .low, // Dibuat low agar tidak bergetar setiap detik (saat countdown berjalan)
    );

    // 2. Channel STEALTH (Pengingat Check-In Korban yang Sunyi)
    // Getar 2 kali dengan sangat cepat dan halus agar tidak mencolok
    final Int64List stealthVibration = Int64List.fromList([0, 200, 100, 200]);

    final AndroidNotificationChannel stealthChannel =
        AndroidNotificationChannel(
      stealthChannelId,
      'Pengingat Halus Pantauan',
      description: 'Pengingat getar halus saat waktu check-in tiba',
      importance:
          Importance.high, // Cukup High untuk muncul di layar, tidak MAX
      enableVibration: true,
      vibrationPattern: stealthVibration,
      playSound: false, // MATIKAN SUARA DEMI KESELAMATAN KORBAN
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // =========================================================
    // INISIALISASI PLUGIN AGAR TOMBOL NOTIFIKASI BISA DITEKAN
    // =========================================================
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse: onNotificationActionTriggered,
    );

    // Daftarkan kedua channel tersebut ke sistem Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(stealthChannel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart, // Fungsi utama background
        autoStart: false, // Jangan auto start, biar dikontrol UI
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Pantau Aman Aktif',
        initialNotificationContent: 'Pantauan sedang dimulai...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    Timer? timer;
    Timer?
        heartbeatTimer; // Timer Khusus untuk menyuplai Denyut Nadi GPS ke Backend
    int sisaWaktu = 0;
    int durasiAsli = 0;
    int stateInfo = 1; // 1: Pantauan Aktif, 2: Check-in, 3: Darurat
    int kesempatan = 0;

    void updateNotification() {
      if (service is AndroidServiceInstance) {
        String title = "Sigap Pantau Aku";
        String content = "";

        // --- STATUS 1: AMAN / COUNTDOWN BIASA ---
        if (stateInfo == 1) {
          int menit = sisaWaktu ~/ 60;
          int detik = sisaWaktu % 60;
          String waktuFormat =
              '${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}';

          title = "🛡️ Sigap: Pantauan Aktif";
          content =
              "Anda masih aman. Penelusuran diam-diam berjalan. Sisa: $waktuFormat";
          service.setForegroundNotificationInfo(title: title, content: content);

          // Hapus notif STEALTH jika sebelumnya ada (misal: user udah klik AMAN)
          FlutterLocalNotificationsPlugin().cancel(stealthNotificationId);
        }
        // --- STATUS 2: MINTA CHECK-IN (ALERT!) ---
        else if (stateInfo == 2) {
          title = "🚨 WAKTUNYA LAPOR!";
          content =
              "Ketuk [SAYA AMAN] sekarang atau sinyal darurat dikirim dalam $sisaWaktu detik!";

          // Foreground notif bawaan diperbarui secara diam-diam
          service.setForegroundNotificationInfo(title: title, content: content);

          // TEMBAKKAN GETARAN STEALTH HALUS (Hanya saat 30 detik & 15 detik terakhir)
          // Tidak ditembakkan tiap detik agar tidak membuat panik.
          if (sisaWaktu == 30 || sisaWaktu == 15) {
            FlutterLocalNotificationsPlugin().show(
              stealthNotificationId,
              title,
              content,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  stealthChannelId,
                  'Pengingat Halus Pantauan',
                  importance: Importance.high,
                  priority: Priority.high,
                  enableVibration: true,
                  playSound: false, // SUNyi
                  fullScreenIntent:
                      false, // JANGAN paksakan bangun layar secara norak
                  actions: <AndroidNotificationAction>[
                    AndroidNotificationAction(
                      'btn_aman',
                      '✅ SAYA AMAN',
                      showsUserInterface:
                          false, // Memungkinkan tombol bekerja tanpa harus membuka/unlock aplikasi
                      cancelNotification:
                          true, // Langsung buang notif setelah ditekan
                    ),
                  ],
                ),
              ),
            );
          }
        }
        // --- STATUS 3: DARURAT DIKIRIM (STEALTH MODE / MUTE) ---
        // KORBAN DIASUMSIKAN SEDANG DALAM BAHAYA, JANGAN BUNYIKAN APAPUN!
        else if (stateInfo == 3) {
          title = "🔴 DARURAT TERKIRIM!";
          content =
              "Gagal Check-in. Lokasi Anda telah dibagikan ke pusat & responder terdekat.";

          // HANYA perbarui tulisan notifikasi yang diam di background.
          service.setForegroundNotificationInfo(title: title, content: content);

          // HAPUS SEMUA pop-up / alarm peringatan jika masih menempel!
          FlutterLocalNotificationsPlugin().cancel(stealthNotificationId);
        }
      }
    }

    void mintaCheckIn() async {
      PantauAmanFlag.hapus();

      service.invoke(
          'tick', {'seconds': sisaWaktu, 'state': 2, 'kesempatan': kesempatan});
      updateNotification();

      if (kesempatan <= 2) {
        try {
          final active = await FlutterOverlayWindow.isActive();
          if (active) {
            await FlutterOverlayWindow.closeOverlay();
            await Future.delayed(const Duration(milliseconds: 500));
          }

          await FlutterOverlayWindow.showOverlay(
            height: 800, // Safe physical height
            width: WindowSize.matchParent,
            alignment: OverlayAlignment.bottomCenter,
            flag: OverlayFlag.defaultFlag,
            overlayTitle: 'Konfirmasi Keamanan Aktif',
            overlayContent: 'Sigap memantau keamanan Anda.',
          );

          await Future.delayed(const Duration(milliseconds: 500));
          FlutterOverlayWindow.shareData(
              'START_OVERLAY_CHECKIN:${DateTime.now().millisecondsSinceEpoch}:$sisaWaktu');
        } catch (e) {
          debugPrint('[PantauService] Gagal tampilkan overlay check-in: $e');
        }
      }
    }

    service.on('start_timer').listen((event) {
      if (event == null) return;
      durasiAsli = event['duration'] as int;
      sisaWaktu = durasiAsli;
      kesempatan = 0;
      stateInfo = 1;

      timer?.cancel();
      heartbeatTimer?.cancel();
      updateNotification();

      // --- [FITUR KEAMANAN: DEAD MAN'S SWITCH PING] ---
      // Timer berdetak setiap 60 detik secara rahasia di background.
      // Sinyal ini memastikan Server Go-Lang tahu bahwa korban masih online & tidak di blank spot.
      heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (t) async {
        try {
          final Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 15),
            ),
          );

          debugPrint('=========================================');
          debugPrint('❤️ [HEARTBEAT] Mengirim Denyut Nadi Korban ke Server...');
          debugPrint(
              '   Lat: ${position.latitude}, Lng: ${position.longitude}');
          debugPrint('   Status: $stateInfo');
          debugPrint('   [API Backend Go-Lang menanti di sini]');
          debugPrint('=========================================');
        } catch (e) {
          debugPrint('💔 [HEARTBEAT] Gagal mendapatkan GPS: $e');
        }
      });

      timer = Timer.periodic(const Duration(seconds: 1), (t) async {
        if (PantauAmanFlag.adaSync()) {
          PantauAmanFlag.hapus();
          sisaWaktu = durasiAsli;
          stateInfo = 1;
          kesempatan = 0;

          try {
            await FlutterOverlayWindow.closeOverlay();
          } catch (e) {
            debugPrint('[PantauService] Gagal tutup overlay setelah aman: $e');
          }

          updateNotification();
          service.invoke('status_aman_dikonfirmasi');
        }

        if (stateInfo == 1) {
          if (sisaWaktu > 0) {
            sisaWaktu--;
            updateNotification();
            service.invoke('tick',
                {'seconds': sisaWaktu, 'state': 1, 'kesempatan': kesempatan});
          } else {
            stateInfo = 2;
            kesempatan = 1;
            sisaWaktu = 30;
            mintaCheckIn();
          }
        } else if (stateInfo == 2) {
          if (sisaWaktu > 0) {
            sisaWaktu--;
            if (sisaWaktu % 5 == 0) updateNotification();
            service.invoke('tick',
                {'seconds': sisaWaktu, 'state': 2, 'kesempatan': kesempatan});
          } else {
            if (kesempatan < 3) {
              kesempatan++;
              sisaWaktu = (kesempatan >= 3) ? 90 : 30;
              mintaCheckIn();
            } else {
              stateInfo = 3;
              updateNotification();
              t.cancel();
              service.invoke('darurat_triggered');
              try {
                await FlutterOverlayWindow.closeOverlay();
              } catch (e) {
                debugPrint('[PantauService] Gagal tutup overlay darurat: $e');
              }
            }
          }
        }
      });
    });

    service.on('stop_service').listen((event) {
      timer?.cancel();
      heartbeatTimer?.cancel();
      try {
        FlutterOverlayWindow.closeOverlay();
      } catch (e) {
        debugPrint('[PantauService] Gagal tutup overlay saat stop: $e');
      }
      service.stopSelf();
    });

    service.on('reset_timer').listen((event) {
      sisaWaktu = durasiAsli;
      kesempatan = 0;
      stateInfo = 1;
      updateNotification();
    });
  }
}
