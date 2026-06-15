import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:sigap_mobile/core/services/api_service.dart';

/// Service untuk merekam audio (Victim) dan memainkan audio streaming (Responder)
class EmergencyAudioService {
  static final EmergencyAudioService _instance = EmergencyAudioService._internal();
  static EmergencyAudioService get instance => _instance;

  EmergencyAudioService._internal();

  // Recorder variables (Victim)
  final _audioRecorder = AudioRecorder();
  Timer? _recordTimer;
  String? _currentIncidentId;
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  // Player variables (Responder)
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _pollTimer;
  StreamSubscription? _playerCompleteSubscription;
  String? _listeningIncidentId;
  bool _isPlaying = false;
  final List<String> _playlist = [];
  final Set<int> _playedAudioIds = {};

  // ══════════════════════════════════════════════════
  // VICTIM: RECORDING CHUNKS
  // ══════════════════════════════════════════════════

  Future<void> startRecordingChunks(String incidentId) async {
    if (_isRecording) return;
    
    if (await _audioRecorder.hasPermission()) {
      _isRecording = true;
      _currentIncidentId = incidentId;
      _startNextChunk();
      
      // Rekam per 3 detik untuk latensi lebih kecil (real-time feel)
      _recordTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _startNextChunk();
      });
    }
  }

  Future<void> _startNextChunk() async {
    if (!_isRecording) return;
    
    try {
      // Stop previously recording chunk
      if (await _audioRecorder.isRecording()) {
        final path = await _audioRecorder.stop();
        if (path != null) {
          _uploadChunk(path);
        }
        // Jeda agar OS benar-benar melepaskan kunci (lock) microphone
        await Future.delayed(const Duration(milliseconds: 150));
      }

      if (!_isRecording) return;

      // Start new chunk
      final dir = await getApplicationDocumentsDirectory();
      final filepath = '${dir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: filepath,
      );
    } catch (e) {
      debugPrint("[AudioService] Gagal merekam siklus chunk: $e");
    }
  }

  Future<void> _uploadChunk(String filePath) async {
    if (_currentIncidentId == null) return;
    try {
      final url = Uri.parse('${ApiService.instance.baseUrl}/api/upload/audio');
      final request = http.MultipartRequest('POST', url);
      
      final token = ApiService.instance.token;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.fields['incident_id'] = _currentIncidentId!;
      request.files.add(await http.MultipartFile.fromPath('audio', filePath));
        
      final response = await request.send();
      
      if (response.statusCode == 200) {
        // File terkirim, bisa dihapus lokal
        try {
          await File(filePath).delete();
        } catch (_) {}
      } else {
        final respStr = await response.stream.bytesToString();
        debugPrint("[AudioService] Gagal upload chunk audio. HTTP ${response.statusCode}: $respStr");
      }
    } catch (e) {
      debugPrint("[AudioService] Exception upload chunk audio: $e");
    }
  }

  void stopRecording() {
    _recordTimer?.cancel();
    _audioRecorder.stop().then((path) {
      if (path != null) _uploadChunk(path);
    });
    _isRecording = false;
    _currentIncidentId = null;
  }

  // ══════════════════════════════════════════════════
  // RESPONDER: PLAYING CHUNKS
  // ══════════════════════════════════════════════════

  void startListening(String incidentId) {
    if (_isPlaying) return;
    _isPlaying = true;
    _listeningIncidentId = incidentId;
    _playedAudioIds.clear();
    _playlist.clear();

    _audioPlayer.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    ));

    _playerCompleteSubscription?.cancel();
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      _playNextInPlaylist();
    });

    // Polling chunk baru setiap 3 detik — sama dengan interval rekaman
    // sehingga latensi audio ~3-6 detik (real-time praktis)
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchNewAudios();
    });
    _fetchNewAudios();
  }

  Future<void> _fetchNewAudios() async {
    if (!_isPlaying || _listeningIncidentId == null) return;

    try {
      final resp = await ApiService.instance.get('/api/emergency/audio?incident_id=$_listeningIncidentId');
      if (resp.success && resp.data != null) {
        final audios = resp.data!['data']?['data'] as List? ?? [];
        bool addedNew = false;

        for (var audio in audios) {
          final id = audio['id'] as int;
          if (!_playedAudioIds.contains(id)) {
            _playedAudioIds.add(id);
            // rawPath sudah berisi "audio_records/filename.m4a", jadi langsung gabungkan
            final rawPath = audio['file_path']?.toString() ?? '';
            final baseUrl = ApiService.instance.baseUrl.endsWith('/') 
                ? ApiService.instance.baseUrl.substring(0, ApiService.instance.baseUrl.length - 1) 
                : ApiService.instance.baseUrl;
            final cleanPath = rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;
            final url = '$baseUrl/$cleanPath';
            _playlist.add(url);
            addedNew = true;
          }
        }

        // Jika player idle dan ada file baru, langsung mainkan
        if (addedNew && _audioPlayer.state != PlayerState.playing) {
          _playNextInPlaylist();
        }
      }
    } catch (e) {
      debugPrint("Gagal fetch audio: $e");
    }
  }

  void _playNextInPlaylist() async {
    if (!_isPlaying || _playlist.isEmpty) return;
    
    if (_audioPlayer.state != PlayerState.playing) {
      final url = _playlist.removeAt(0);
      try {
        await _audioPlayer.play(UrlSource(url));
      } catch (e) {
        debugPrint("[AudioService] Error memutar audio: $e");
        // Lanjut memutar url berikutnya jika gagal
        _playNextInPlaylist();
      }
    }
  }

  void stopListening() {
    _pollTimer?.cancel();
    _audioPlayer.stop();
    _isPlaying = false;
    _listeningIncidentId = null;
    _playlist.clear();
    _playerCompleteSubscription?.cancel();
  }
}
