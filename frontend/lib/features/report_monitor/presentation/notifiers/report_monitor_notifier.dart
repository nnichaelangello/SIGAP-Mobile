import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import '../../data/models/report_monitor_record.dart';
import '../widgets/timeline_tracker.dart';
import '../widgets/audit_trail_list.dart';
import 'package:sigap_mobile/core/services/api_service.dart';

/// State sealed class — representasi semua kemungkinan state halaman monitor.
sealed class MonitorViewState {
  const MonitorViewState();
}

class MonitorEmpty extends MonitorViewState {
  const MonitorEmpty();
}

class MonitorLoading extends MonitorViewState {
  const MonitorLoading();
}

class MonitorError extends MonitorViewState {
  final String message;
  const MonitorError(this.message);
}

class MonitorSuccess extends MonitorViewState {
  final ReportMonitorRecord record;
  const MonitorSuccess(this.record);
}

/// Single source of truth untuk seluruh state & logika halaman Report Monitor.
class ReportMonitorNotifier extends ChangeNotifier {
  MonitorViewState _state = const MonitorEmpty();
  MonitorViewState get state => _state;

  ReportMonitorRecord? _activeRecord;
  ReportMonitorRecord? get activeRecord => _activeRecord;

  int _searchRequestId = 0;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  /// Apakah text di search bar berbeda dari record yang sedang ditampilkan?
  bool hasDraftSearch(String currentText) {
    final activeCode = _activeRecord?.reportCode;
    if (activeCode == null) return false;
    return _normalizeQuery(currentText) != activeCode;
  }

  /// Cari laporan berdasarkan kode ID.
  Future<void> performSearch(String query) async {
    final normalized = _normalizeQuery(query);

    if (normalized.isEmpty) {
      _state = const MonitorError('Silakan masukkan ID laporan terlebih dahulu.');
      notifyListeners();
      return;
    }

    final requestId = ++_searchRequestId;

    _state = const MonitorLoading();
    notifyListeners();

    try {
      final resp = await ApiService.instance.get('/api/reports');

      if (requestId != _searchRequestId) return;

      if (!resp.success || resp.data == null) {
        _state = MonitorError('Gagal terhubung ke server: ${resp.error}');
        notifyListeners();
        return;
      }

      final items = resp.data!['data'] as List? ?? [];

      final rawRecord = items.firstWhere(
        (item) => (item['tracking_code']?.toString().toUpperCase() ?? '') == normalized,
        orElse: () => null,
      );

      if (rawRecord == null) {
        _state = MonitorError(
            'Laporan dengan ID "$normalized" tidak ditemukan. Periksa kembali kode yang Anda masukkan.');
        notifyListeners();
        return;
      }

      // Fetch detail untuk mendapatkan audit_trail
      final reportId = rawRecord['id'];
      final detailResp = await ApiService.instance.get('/api/reports/$reportId');

      Map<String, dynamic> detailData = rawRecord;
      List<dynamic> audits = [];

      if (detailResp.success && detailResp.data != null) {
        detailData = detailResp.data!['data'] ?? rawRecord;
        audits = detailResp.data!['data']['audit_trail'] as List? ?? [];
      }

      // Fetch appointment jika status sudah lewat 'pending'
      int? appointmentId;
      String? appointmentStatus;
      int? psikologId;
      String? psikologName;
      List<PsikologSlot> psikologSchedules = [];
      String? rescheduleNote;
      ScheduleCardData? scheduleCard;
      String? tipeLokasi;
      String? linkLokasi;
      String consultationNote = 'Belum ada catatan dari konselor.';

      final reportStatus = detailData['status'] ?? 'pending';

      if (['dijadwalkan', 'menunggu_penjadwalan', 'diproses', 'selesai'].contains(reportStatus)) {
        final apptResp = await ApiService.instance.get('/api/appointments');
        if (apptResp.success && apptResp.data != null) {
          final allAppts = apptResp.data!['data'] as List? ?? [];
          final myApptsForReport = allAppts.where((a) => a['report_id'] == reportId).toList();
          myApptsForReport.sort((a, b) => b['id'].compareTo(a['id']));
          final myAppt = myApptsForReport.isNotEmpty ? myApptsForReport.first : null;

          if (myAppt != null) {
            appointmentId = myAppt['id'];
            appointmentStatus = myAppt['status'];
            psikologId = myAppt['psikolog_id'];
            psikologName = myAppt['nama_psikolog'] ?? myAppt['psikolog_nama'];
            rescheduleNote = myAppt['catatan_reschedule'];
            tipeLokasi = myAppt['tipe_lokasi'];
            linkLokasi = myAppt['link_lokasi'];

            // Jadwal terkonfirmasi
            if (appointmentStatus == 'diterima' && (myAppt['tanggal'] ?? '').isNotEmpty) {
              scheduleCard = ScheduleCardData(
                title: 'Konsultasi dengan $psikologName',
                subtitle: '${myAppt['tanggal']} · ${myAppt['jam_mulai'] ?? ''} – ${myAppt['jam_selesai'] ?? ''}',
                tipeLokasi: myAppt['tipe_lokasi'],
                linkLokasi: myAppt['link_lokasi'],
              );
            }

            // Fetch slot jadwal psikolog jika masih perlu pilih
            if (['menunggu_user', 'reschedule'].contains(appointmentStatus) && psikologId != null) {
              final schedResp = await ApiService.instance.get('/api/schedules/psikolog?psikolog_id=$psikologId');
              if (schedResp.success && schedResp.data != null) {
                final slots = schedResp.data!['data'] as List? ?? [];
                psikologSchedules = slots.map((s) => PsikologSlot.fromMap(s as Map<String, dynamic>)).toList();
              }
            }

            // Fetch catatan sesi psikolog dari session_notes
            // Catatan hanya tersedia setelah sesi berlangsung (status diterima/selesai)
            if (['diterima', 'selesai'].contains(appointmentStatus)) {
              try {
                final noteResp = await ApiService.instance.get('/api/session-notes?appointment_id=$appointmentId');
                if (noteResp.success && noteResp.data != null && noteResp.data!['data'] != null) {
                  final noteData = noteResp.data!['data'] as Map<String, dynamic>;
                  final parts = <String>[];
                  if ((noteData['assessment'] ?? '').isNotEmpty) {
                    parts.add('📋 Penilaian: ${noteData['assessment']}');
                  }
                  if ((noteData['plan'] ?? '').isNotEmpty) {
                    parts.add('🎯 Rencana: ${noteData['plan']}');
                  }
                  if ((noteData['subjective'] ?? '').isNotEmpty) {
                    parts.add('💬 Keluhan: ${noteData['subjective']}');
                  }
                  if ((noteData['objective'] ?? '').isNotEmpty) {
                    parts.add('🔍 Observasi: ${noteData['objective']}');
                  }
                  if (parts.isNotEmpty) {
                    consultationNote = parts.join('\n\n');
                  }
                }
              } catch (_) {
                // Gagal fetch notes — gunakan default
              }
            }
          }
        }
      }

      // Build status UI
      final statusBackend = detailData['status'] ?? 'pending';
      String statusLabel = 'MENUNGGU TINJAUAN';
      Color statusColor = Colors.orange;
      IconData statusIcon = Icons.hourglass_top_rounded;

      if (statusBackend == 'diterima') {
        statusLabel = 'DITERIMA';
        statusColor = AppConstants.primaryColor;
        statusIcon = Icons.thumb_up_rounded;
      } else if (statusBackend == 'menunggu_penjadwalan') {
        statusLabel = 'MENUNGGU PENJADWALAN';
        statusColor = Colors.blueGrey;
        statusIcon = Icons.schedule_rounded;
      } else if (statusBackend == 'dijadwalkan') {
        statusLabel = 'DIJADWALKAN';
        statusColor = Colors.deepPurple;
        statusIcon = Icons.calendar_month_rounded;
      } else if (statusBackend == 'diproses') {
        statusLabel = 'DIPROSES';
        statusColor = AppConstants.primaryColor;
        statusIcon = Icons.autorenew_rounded;
      } else if (statusBackend == 'selesai') {
        statusLabel = 'SELESAI';
        statusColor = AppConstants.successColor;
        statusIcon = Icons.check_circle_rounded;
      } else if (statusBackend == 'ditolak') {
        statusLabel = 'DITOLAK';
        statusColor = AppConstants.urgentColor;
        statusIcon = Icons.cancel_rounded;
      }

      // Tentukan feedbackState berdasarkan appointment status
      FeedbackActionState feedbackState = FeedbackActionState.waiting;
      if (appointmentStatus == 'menunggu_user' || appointmentStatus == 'reschedule') {
        feedbackState = FeedbackActionState.waitingSlotSelection;
      } else if (appointmentStatus == 'menunggu_psikolog') {
        feedbackState = FeedbackActionState.waitingPsikologConfirmation;
      } else if (appointmentStatus == 'diterima') {
        feedbackState = FeedbackActionState.accepted;
      }

      // Build audit trail
      List<AuditTrailItem> auditTrailList = [];
      if (audits.isNotEmpty) {
        auditTrailList = audits.map((a) {
          return AuditTrailItem(
            date: _formatWaktu(a['created_at']),
            description: a['action']?.toString() ?? 'Update',
            details: a['detail']?.toString() ?? '',
          );
        }).toList();
      } else {
        auditTrailList = [
          AuditTrailItem(
            date: _formatWaktu(detailData['created_at']),
            description: 'Laporan Dibuat',
            details: 'Laporan berhasil masuk ke sistem.',
          ),
        ];
      }

      final record = ReportMonitorRecord(
        reportCode: normalized,
        reportId: reportId,
        title: detailData['kategori_kekhawatiran'] ?? 'Kasus Darurat',
        createdAtLabel: _formatWaktu(detailData['created_at']),
        statusLabel: statusLabel,
        statusColor: statusColor,
        statusIcon: statusIcon,
        schedule: scheduleCard,
        consultationNote: consultationNote,
        feedbackPrompt: _buildFeedbackPrompt(appointmentStatus),
        feedbackState: feedbackState,
        timelineSteps: _buildTimelineForStatus(statusBackend, detailData, appointmentStatus),
        auditTrail: auditTrailList,
        appointmentId: appointmentId,
        appointmentStatus: appointmentStatus,
        psikologId: psikologId,
        psikologName: psikologName,
        psikologSchedules: psikologSchedules,
        rescheduleNote: rescheduleNote,
        tipeLokasi: tipeLokasi,
        linkLokasi: linkLokasi,
      );

      _activeRecord = record;
      _state = MonitorSuccess(record);
      notifyListeners();
    } catch (e) {
      if (requestId != _searchRequestId) return;
      _state = MonitorError('Terjadi kesalahan jaringan: $e');
      notifyListeners();
    }
  }

  /// Logika saat user mengubah text di search bar.
  void onSearchInputChanged(String value) {
    if (_state is MonitorError) {
      if (value.trim().isEmpty) {
        _state = const MonitorEmpty();
      }
      notifyListeners();
      return;
    }
    if (_activeRecord != null) {
      notifyListeners();
    }
  }

  /// Refresh setelah user memilih slot jadwal (kembali dari AppointmentSlotPage).
  Future<void> refresh() async {
    if (_activeRecord == null) return;
    await performSearch(_activeRecord!.reportCode);
  }

  /// Download PDF (Receipt) dari backend.
  Future<void> downloadPdf() async {
    if (_isDownloading || _activeRecord == null) return;
    _isDownloading = true;
    notifyListeners();

    try {
      // Panggil endpoint backend (meskipun mungkin saat ini backend hanya me-return URL/teks)
      final response = await ApiService.instance.get('/api/reports/download/${_activeRecord!.reportId}');
      
      if (response.success) {
        // Logika save/open file dapat diimplementasikan di sini
        debugPrint('File siap diunduh: ${response.data}');
      }
    } catch (e) {
      debugPrint('Gagal unduh dokumen: $e');
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────
  //  Helpers
  // ──────────────────────────────────────────────

  String _buildFeedbackPrompt(String? apptStatus) {
    switch (apptStatus) {
      case 'menunggu_user':
        return 'Admin telah menunjuk psikolog. Silakan pilih jadwal konsultasi.';
      case 'reschedule':
        return 'Psikolog meminta perubahan jadwal. Silakan pilih jadwal baru.';
      case 'menunggu_psikolog':
        return 'Jadwal Anda telah dikirim. Menunggu konfirmasi psikolog.';
      case 'diterima':
        return 'Jadwal konsultasi Anda telah dikonfirmasi oleh psikolog.';
      case 'selesai':
        return 'Sesi konsultasi telah selesai. Menunggu arahan atau sesi lanjutan dari tim Admin.';
      default:
        return 'Laporan Anda sedang ditinjau oleh tim kami.';
    }
  }

  String _normalizeQuery(String value) => value.trim().toUpperCase();

  String _buildNowLabel() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _formatWaktu(dynamic isoDateTime) {
    if (isoDateTime == null || isoDateTime.toString().isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoDateTime.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDateTime.toString();
    }
  }

  List<TimelineStepModel> _buildTimelineForStatus(
      String status, Map<String, dynamic> raw, String? apptStatus) {
    return [
      TimelineStepModel(
        title: 'Laporan Diterima',
        description: 'Laporan Anda telah berhasil masuk ke sistem SIGAP.',
        date: _formatWaktu(raw['created_at']),
        status: TimelineStatus.success,
      ),
      TimelineStepModel(
        title: 'Verifikasi & Tinjauan',
        description: 'Tim Satgas sedang memverifikasi laporan Anda.',
        date: status != 'pending' ? _formatWaktu(raw['updated_at']) : 'Menunggu',
        status: status == 'pending' ? TimelineStatus.pending : TimelineStatus.success,
      ),
      TimelineStepModel(
        title: status == 'ditolak' ? 'Laporan Ditolak' : 'Penjadwalan Konsultasi',
        description: status == 'ditolak'
            ? 'Laporan ditolak. Alasan: ${raw['alasan_tolak'] ?? '-'}'
            : _scheduleTimelineDesc(apptStatus),
        date: (['dijadwalkan', 'diproses', 'selesai', 'ditolak'].contains(status))
            ? _formatWaktu(raw['updated_at'])
            : 'Menunggu',
        status: status == 'ditolak'
            ? TimelineStatus.failed
            : (['dijadwalkan', 'diproses', 'selesai'].contains(status))
                ? (['diterima', 'selesai'].contains(apptStatus) ? TimelineStatus.success : TimelineStatus.pending)
                : TimelineStatus.pending,
      ),
      TimelineStepModel(
        title: 'Konsultasi Berlangsung',
        description: 'Sesi konsultasi dengan psikolog.',
        date: status == 'diproses' || status == 'selesai' ? _formatWaktu(raw['updated_at']) : 'Menunggu',
        status: status == 'selesai'
            ? TimelineStatus.success
            : status == 'diproses'
                ? TimelineStatus.pending
                : TimelineStatus.pending,
      ),
    ];
  }

  String _scheduleTimelineDesc(String? apptStatus) {
    switch (apptStatus) {
      case 'menunggu_user':
        return 'Menunggu Anda memilih jadwal konsultasi.';
      case 'menunggu_psikolog':
        return 'Menunggu konfirmasi jadwal dari psikolog.';
      case 'reschedule':
        return 'Psikolog meminta perubahan jadwal.';
      case 'diterima':
        return 'Jadwal konsultasi dikonfirmasi.';
      default:
        return 'Penjadwalan konseling dengan psikolog.';
    }
  }
}
