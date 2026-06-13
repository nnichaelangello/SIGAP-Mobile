import 'package:sigap_mobile/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Repository untuk mengelola jadwal psikolog dan penjadwalan appointment
class ApiScheduleRepository {
  /// Mengambil daftar psikolog
  Future<List<Map<String, dynamic>>> getPsikologList() async {
    final resp = await ApiService.instance.get('/api/users?role=psikolog');
    if (!resp.success) {
      throw Exception(resp.error ?? 'Gagal mengambil daftar psikolog');
    }
    final data = resp.data?['data'] as List? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  /// Mengambil jadwal ketersediaan psikolog tertentu
  Future<List<Map<String, dynamic>>> getPsikologSchedules(int psikologId) async {
    final resp = await ApiService.instance.get('/api/schedules/psikolog?psikolog_id=$psikologId');
    if (!resp.success) {
      throw Exception(resp.error ?? 'Gagal mengambil jadwal psikolog');
    }
    final data = resp.data?['data'] as List? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  /// Admin menjadwalkan konsultasi (assign psikolog ke laporan)
  Future<bool> initiateAppointment({
    required int reportId,
    required int psikologId,
  }) async {
    final resp = await ApiService.instance.post('/api/appointments/initiate', {
      'report_id': reportId,
      'psikolog_id': psikologId,
    });
    
    if (!resp.success) {
      throw Exception(resp.error ?? 'Gagal menginisiasi jadwal konsultasi');
    }
    return true;
  }

  /// Psikolog menambahkan jadwal ketersediaan mereka
  Future<bool> addPsikologSchedule({
    required String hari, // Hari (Senin, Selasa, dst)
    required String jamMulai, // Format HH:MM
    required String jamSelesai, // Format HH:MM
  }) async {
    final resp = await ApiService.instance.post('/api/schedules/psikolog', {
      'hari': hari,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
    });

    if (!resp.success) {
      throw Exception(resp.error ?? 'Gagal menambahkan jadwal');
    }
    return true;
  }

  /// Psikolog menghapus jadwal ketersediaan mereka
  Future<bool> deletePsikologSchedule(int scheduleId) async {
    try {
      // Menggunakan request DELETE manual jika ApiService.instance tidak mendukung DELETE dengan body
      final url = Uri.parse('${ApiService.instance.baseUrl}/api/schedules/psikolog');
      final headers = {
        'Content-Type': 'application/json',
        if (ApiService.instance.token != null)
          'Authorization': 'Bearer ${ApiService.instance.token}',
      };
      final body = jsonEncode({'schedule_id': scheduleId});
      final response = await http.delete(url, headers: headers, body: body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Gagal menghapus jadwal: $e');
    }
  }
}
