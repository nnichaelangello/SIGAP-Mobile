import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:sigap_mobile/core/services/api_service.dart';

/// Service untuk merekam audio saat SOS aktif.
///
/// Alur kerja:
///   1. SOS dikirim → startRecording() dipanggil
///   2. Audio direkam secara terus-menerus dalam format M4A
///   3. Saat insiden selesai → stopRecording() dipanggil
///   4. File audio diupload ke server
class SOSAudioService {
  SOSAudioService._();
  static final SOSAudioService instance = SOSAudioService._();

  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;
  String? _currentIncidentId;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get currentPath => _currentPath;

  /// Mulai merekam audio saat SOS aktif
  Future<bool> startRecording({String? incidentId}) async {
    try {
      // Cek permission microphone
      if (!await _recorder.hasPermission()) {
        debugPrint('[SOSAudio] Permission mikrofon ditolak');
        return false;
      }

      // Buat path file
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentPath = '${dir.path}/sos_audio_$timestamp.m4a';
      _currentIncidentId = incidentId;

      // Konfigurasi recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _currentPath!,
      );

      _isRecording = true;
      debugPrint('[SOSAudio] 🎙️ Rekaman dimulai: $_currentPath');
      return true;
    } catch (e) {
      debugPrint('[SOSAudio] Gagal memulai rekaman: $e');
      return false;
    }
  }

  /// Hentikan rekaman dan upload ke server
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _recorder.stop();
      _isRecording = false;

      if (path == null) {
        debugPrint('[SOSAudio] Rekaman null setelah stop');
        return null;
      }

      debugPrint('[SOSAudio] ✅ Rekaman selesai: $path');

      // Upload ke server (background)
      _uploadAudio(path, _currentIncidentId);

      return path;
    } catch (e) {
      debugPrint('[SOSAudio] Error saat stop rekaman: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Upload file audio ke server
  Future<void> _uploadAudio(String filePath, String? incidentId) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('[SOSAudio] File tidak ditemukan: $filePath');
        return;
      }

      final uri = Uri.parse('${ApiService.instance.baseUrl}/api/upload/audio');
      final request = http.MultipartRequest('POST', uri);

      // Auth header
      final token = ApiService.instance.token;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add file
      request.files.add(await http.MultipartFile.fromPath('audio', filePath));

      // Add incident ID if available
      if (incidentId != null) {
        request.fields['incident_id'] = incidentId;
      }

      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[SOSAudio] ✅ Audio berhasil diupload ke server');
      } else {
        debugPrint('[SOSAudio] ❌ Upload gagal: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[SOSAudio] Error upload: $e');
    }
  }

  /// Pembersihan resource
  void dispose() {
    if (_isRecording) {
      _recorder.stop();
    }
    _recorder.dispose();
  }
}
