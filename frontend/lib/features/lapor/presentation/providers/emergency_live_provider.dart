import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sigap_mobile/core/services/api_service.dart';

enum EmergencyLiveState { initial, loading, active, error, resolved }

class EmergencyLiveProvider extends ChangeNotifier {
  EmergencyLiveState _state = EmergencyLiveState.initial;
  EmergencyLiveState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _currentIncidentId;
  String? get currentIncidentId => _currentIncidentId;

  LatLng? _responderPos;
  LatLng? get responderPos => _responderPos;

  LatLng? _victimPos;
  LatLng? get victimPos => _victimPos;

  bool _isVictimOffline = false;
  bool get isVictimOffline => _isVictimOffline;

  double _distanceInMeters = 0.0;
  double get distanceInMeters => _distanceInMeters;

  StreamSubscription<Position>? _responderLocationSub;
  Timer? _offlineTimer;

  static const int _offlineThresholdSeconds = 30;

  Timer? _statusPollTimer;

  /// Memulai layanan pelacakan GPS
  Future<void> startTracking(String incidentId, LatLng initialVictimPos) async {
    _state = EmergencyLiveState.loading;
    _currentIncidentId = incidentId;
    notifyListeners();

    try {
      // 1. Cek Service GPS dinyalakan atau tidak di HP
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
            'Layanan Lokasi (GPS) tidak aktif. Harap nyalakan GPS Anda.');
      }

      // 2. Cek Izin Lokasi (Permissions) dari Android/iOS
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
              'Izin lokasi ditolak. Aplikasi butuh lokasi Anda untuk menolong korban.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Izin lokasi ditolak permanen. Buka pengaturan lokasi di Setelan Ponsel Anda.');
      }

      // Izin aman. Set titik koordinat awal korban
      _victimPos = initialVictimPos;

      // 3. Dapatkan lokasi awal Penolong dengan toleransi batas waktu 10 detik agar tak hang.
      Position currentPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _responderPos = LatLng(currentPos.latitude, currentPos.longitude);

      _calculateDistance();

      _state = EmergencyLiveState.active;
      notifyListeners();

      // 4. Mulai streaming perubahan lokasi Responder (Penolong berjalan/menyetir)
      _responderLocationSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        ),
      ).listen(
        (Position position) {
          _responderPos = LatLng(position.latitude, position.longitude);
          _calculateDistance();
          notifyListeners();
        },
        onError: (error) {
          // Tangkap glitch GPS (sering di Xiaomi/Redmi) agar stream tidak mati diam-diam
          _errorMessage = 'GPS perangkat bermasalah. Coba restart lokasi.';
          _state = EmergencyLiveState.error;
          notifyListeners();
        },
      );

      // 5. Mulai polling status dan lokasi korban dari backend setiap 3 detik
      _startStatusPolling(incidentId);

    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = EmergencyLiveState.error;
      notifyListeners();
    }
  }

  void _startStatusPolling(String incidentId) {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        // 1. Ambil status korban
        final resp = await ApiService.instance.get('/api/emergency/$incidentId/location');
        if (resp.success && resp.data != null) {
          final data = resp.data!;
          final status = data['status']?.toString() ?? 'active';

          if (status == 'resolved' || status == 'stopped_by_user' || status == 'cancelled') {
            _state = EmergencyLiveState.resolved;
            _errorMessage = status; // Simpan status akhir untuk dicek di UI
            closeSubscriptions();
            notifyListeners();
            return;
          }

          final lat = (data['korban_lat'] as num?)?.toDouble();
          final lng = (data['korban_lng'] as num?)?.toDouble();
          
          if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
            syncVictimLocation(LatLng(lat, lng));
          }
        }
        
        // 2. Kirim lokasi responder ke backend agar korban/admin bisa melihat pergerakan
        if (_responderPos != null) {
          await ApiService.instance.post('/api/emergency/responder-location', {
            'incident_db_id': int.tryParse(incidentId) ?? 0,
            'lat': _responderPos!.latitude,
            'lng': _responderPos!.longitude,
            'status': 'navigating'
          });
        }
      } catch (e) {
        // Ignore network errors during polling
      }
    });
  }

  /// Fungsi sinkronasi ini dipanggil saat polling mendapat lokasi baru
  void syncVictimLocation(LatLng newLocation) {
    _victimPos = newLocation;
    _resetOfflineTimer(); // Karena data baru tiba, cabut label offlinenya
    _calculateDistance();
    notifyListeners();
  }

  void _calculateDistance() {
    if (_responderPos != null && _victimPos != null) {
      _distanceInMeters = Geolocator.distanceBetween(
        _responderPos!.latitude,
        _responderPos!.longitude,
        _victimPos!.latitude,
        _victimPos!.longitude,
      );
    }
  }

  void _resetOfflineTimer() {
    _offlineTimer?.cancel();
    _isVictimOffline = false;

    // Jika lewat batas tanpa ada kontak, ubah menjadi "Offline"
    _offlineTimer =
        Timer(const Duration(seconds: _offlineThresholdSeconds), () {
      _isVictimOffline = true;
      notifyListeners();
    });
  }

  /// Dipanggil saat Responder mengeklik konfirmasi berhasil mengamankan.
  Future<void> resolveIncident() async {
    // Di aplikasi produksi: Ini waktunya POST ke HTTP backend sebelum tutup layar.
    closeSubscriptions(); // HENTIKAN GPS! Sangat fatal kalau GPS bocor/masih jalan background.
    _state = EmergencyLiveState.resolved;
    notifyListeners();
  }

  /// Matikan seluruh streaming agar tak terjadi Memory Leak/Battery Drain
  void closeSubscriptions() {
    _responderLocationSub?.cancel();
    _offlineTimer?.cancel();
    _statusPollTimer?.cancel();
  }

  @override
  void dispose() {
    closeSubscriptions();
    super.dispose();
  }
}
