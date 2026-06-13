import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/core/services/api_service.dart';
import 'package:sigap_mobile/features/app_shell/presentation/pages/main_screen.dart';
import 'package:sigap_mobile/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:sigap_mobile/features/pantau/overlay/overlay_entry_point.dart';
import 'package:sigap_mobile/features/pantau/services/pantau_notification_service.dart';
import 'package:sigap_mobile/features/pantau/services/pantau_service.dart';
import 'package:sigap_mobile/features/pantau/presentation/pages/trigger_sent_page.dart';
import 'package:sigap_mobile/features/lapor/services/emergency_notification_handler.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/pages/admin_lite_page.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/pages/psikolog_lite_page.dart';

/// Instance global handler darurat — bisa diakses dari mana saja
/// (notification callback, background service, dsb).
late final EmergencyNotificationHandler emergencyHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  // WAJIB di-await SEBELUM runApp — background service harus terkonfigurasi
  // agar channel invoke/on antara UI dan service isolate bisa berfungsi.
  await PantauNotificationService.initializeService();

  // Daftarkan juga channel Sirine untuk HP Penolong
  await EmergencyNotificationHandler.initializeResponderChannel();

  // Singleton instance untuk State Management isolasi UI dari Timer
  PantauService.instance.initialize();

  // Inisialisasi handler darurat — pakai navigatorKey yang sama
  // agar bisa navigasi tanpa context dari mana saja
  emergencyHandler = EmergencyNotificationHandler(
    navigatorKey: PantauService.instance.navigatorKey,
  );

  // Inisialisasi API Service — load token tersimpan & base URL
  ApiService.instance.navigatorKey = PantauService.instance.navigatorKey;
  await ApiService.autoConfigureBaseUrl();
  // KRUSIAL: loadToken() harus selesai SEBELUM build() dipanggil
  // agar ApiService.instance.isLoggedIn sudah bernilai benar saat routing.
  await ApiService.instance.loadToken();

  runApp(const SigapApp());
}

// Global scope registration for Android Service (flutter_overlay_window)
@pragma("vm:entry-point")
void overlayMain() {
  runOverlayMain();
}

class SigapApp extends StatelessWidget {
  const SigapApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Tentukan halaman awal berdasarkan status login yang sudah dimuat
    // di main() sebelum runApp dipanggil.
    final Widget homePage = _resolveHomePage();

    return MaterialApp(
      title: 'Sigap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          primary: AppConstants.primaryColor,
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      navigatorKey: PantauService
          .instance.navigatorKey, // Injeksi key untuk navigasi context-less
      home: homePage,
      routes: {
        '/trigger_sent': (context) => const TriggerSentPage(),
      },
    );
  }

  /// Menentukan halaman awal berdasarkan:
  /// 1. Apakah token tersimpan di SharedPreferences (isLoggedIn)?
  /// 2. Jika ya, apa role user? (user, admin, psikolog)
  Widget _resolveHomePage() {
    if (!ApiService.instance.isLoggedIn) {
      // Token tidak ada → tampilkan halaman onboarding/login
      return const OnboardingPage();
    }

    // Token ada — arahkan ke halaman yang sesuai peran
    final String role = ApiService.instance.userRole;
    switch (role) {
      case 'admin':
        return AdminLitePage(userName: ApiService.instance.userName);
      case 'psikolog':
        return PsikologLitePage(userName: ApiService.instance.userName);
      default:
        // 'user' atau role tidak dikenal → tampilkan MainScreen sebagai user terautentikasi
        return const MainScreen(isGuest: false);
    }
  }
}
