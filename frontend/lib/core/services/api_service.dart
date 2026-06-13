import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:sigap_mobile/features/onboarding/presentation/pages/onboarding_page.dart' as sigap_onboarding;

/// Service singleton untuk komunikasi dengan Go backend.
/// 
/// Menangani:
/// - JWT token management (simpan/baca/hapus dari SharedPreferences)
/// - Auto-inject Authorization header
/// - Error handling untuk server offline
/// - Base URL configuration
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  /// Global navigator key for handling auto-logout redirects
  GlobalKey<NavigatorState>? navigatorKey;

  /// Base URL server — UBAH sesuai IP laptop Anda.
  /// Cek IP dengan menjalankan `ipconfig` di CMD laptop.
  /// Format: http://<IP_LAPTOP>:8080
  static String _baseUrl = 'http://10.0.2.2:8080'; // Default Android Emulator

  String get baseUrl => _baseUrl;

  /// Set base URL — dipanggil saat app startup
  static void setBaseUrl(String url) {
    _baseUrl = url;
  }

  /// Coba auto-detect base URL berdasarkan platform
  static Future<void> autoConfigureBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
      return;
    }

    // Menggunakan IP Wi-Fi Laptop agar bisa diakses oleh perangkat fisik Android (Mobile)
    if (Platform.isAndroid) {
      _baseUrl = 'http://10.208.67.237:8080';
    } else {
      _baseUrl = 'http://localhost:8080';
    }
  }

  /// Simpan custom base URL (dari settings)
  static Future<void> saveBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_base_url', url);
  }

  // ══════════════════════════════════════════
  // TOKEN MANAGEMENT
  // ══════════════════════════════════════════

  String? _token;
  Map<String, dynamic>? _currentUser;

  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null;
  String get userRole => _currentUser?['role'] ?? 'user';
  String get userName => _currentUser?['nama_lengkap'] ?? 'User';
  int get userId => _currentUser?['id'] ?? 0;

  /// Load token dari SharedPreferences saat app startup
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userJson = prefs.getString('auth_user');
    if (userJson != null) {
      _currentUser = json.decode(userJson);
    }
  }

  /// Simpan token setelah login berhasil
  Future<void> saveAuth(String token, Map<String, dynamic> user) async {
    _token = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_user', json.encode(user));
  }

  /// Hapus token saat logout
  Future<void> clearAuth() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }

  // ══════════════════════════════════════════
  // HTTP METHODS
  // ══════════════════════════════════════════

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// GET request
  Future<ApiResponse> get(String path) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      return _parseResponse(response);
    } on SocketException {
      return ApiResponse(success: false, statusCode: 0, error: 'Server tidak dapat dihubungi. Pastikan server berjalan.');
    } on HttpException {
      return ApiResponse(success: false, statusCode: 0, error: 'Koneksi gagal');
    } catch (e) {
      return ApiResponse(success: false, statusCode: 0, error: 'Error: $e');
    }
  }

  /// POST request
  Future<ApiResponse> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));
      return _parseResponse(response);
    } on SocketException {
      return ApiResponse(success: false, statusCode: 0, error: 'Server tidak dapat dihubungi. Pastikan server berjalan.');
    } on HttpException {
      return ApiResponse(success: false, statusCode: 0, error: 'Koneksi gagal');
    } catch (e) {
      return ApiResponse(success: false, statusCode: 0, error: 'Error: $e');
    }
  }

  /// PUT request
  Future<ApiResponse> put(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));
      return _parseResponse(response);
    } on SocketException {
      return ApiResponse(success: false, statusCode: 0, error: 'Server tidak dapat dihubungi. Pastikan server berjalan.');
    } catch (e) {
      return ApiResponse(success: false, statusCode: 0, error: 'Error: $e');
    }
  }

  /// DELETE request
  Future<ApiResponse> delete(String path) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      return _parseResponse(response);
    } on SocketException {
      return ApiResponse(success: false, statusCode: 0, error: 'Server tidak dapat dihubungi. Pastikan server berjalan.');
    } catch (e) {
      return ApiResponse(success: false, statusCode: 0, error: 'Error: $e');
    }
  }

  ApiResponse _parseResponse(http.Response response) {
    Map<String, dynamic>? data;
    try {
      data = json.decode(response.body);
    } catch (_) {
      data = {'raw': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(success: true, statusCode: response.statusCode, data: data);
    } else {
      if (response.statusCode == 401) {
        // Token expired or invalid -> Auto-logout
        clearAuth().then((_) {
          if (navigatorKey?.currentContext != null) {
            // Using a post-frame callback to avoid build conflicts
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(navigatorKey!.currentContext!).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const sigap_onboarding.OnboardingPage()),
                (route) => false,
              );
            });
          }
        });
      }
      final errorMsg = data?['error'] ?? 'Request gagal (${response.statusCode})';
      return ApiResponse(success: false, statusCode: response.statusCode, error: errorMsg, data: data);
    }
  }

  // ══════════════════════════════════════════
  // HEALTH CHECK
  // ══════════════════════════════════════════

  /// Cek apakah server online
  Future<bool> isServerOnline() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ══════════════════════════════════════════
  // AUTH ENDPOINTS
  // ══════════════════════════════════════════

  /// Login → simpan token
  Future<ApiResponse> login(String email, String password) async {
    final resp = await post('/api/auth/login', {
      'email': email,
      'password': password,
    });

    if (resp.success && resp.data != null) {
      await saveAuth(resp.data!['token'], Map<String, dynamic>.from(resp.data!['user']));
    }

    return resp;
  }

  /// Register → simpan token
  Future<ApiResponse> register({
    required String email,
    required String password,
    required String namaLengkap,
    String subRole = 'mahasiswa',
    String nimNidnNik = '',
    String noHP = '',
    String prodiUnit = '',
  }) async {
    final resp = await post('/api/auth/register', {
      'email': email,
      'password': password,
      'nama_lengkap': namaLengkap,
      'sub_role': subRole,
      'nim_nidn_nik': nimNidnNik,
      'no_hp': noHP,
      'prodi_unit': prodiUnit,
    });

    if (resp.success && resp.data != null) {
      await saveAuth(resp.data!['token'], Map<String, dynamic>.from(resp.data!['user']));
    }

    return resp;
  }

  /// Logout
  Future<void> logout() async {
    await clearAuth();
  }
}

/// Response wrapper untuk API calls
class ApiResponse {
  final bool success;
  final int statusCode;
  final Map<String, dynamic>? data;
  final String? error;

  ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.error,
  });

  @override
  String toString() => 'ApiResponse(success: $success, status: $statusCode, error: $error)';
}
