import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import '../../../data/models/report_monitor_record.dart';
import '../timeline_tracker.dart';
import '../status_phase_card.dart';
import '../audit_trail_list.dart';
import '../../pages/appointment_slot_page.dart';

class SuccessMonitorView extends StatelessWidget {
  final ReportMonitorRecord record;
  final VoidCallback onDownloadPdf;
  final VoidCallback onRefresh;

  const SuccessMonitorView({
    super.key,
    required this.record,
    required this.onDownloadPdf,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultHeader(record),
        const SizedBox(height: 16),
        _buildDownloadPdfButton(),
        const SizedBox(height: 16),
        Text(
          'Timeline Penanganan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 20),
        TimelineTracker(steps: record.timelineSteps),
        const SizedBox(height: 16),
        // Jadwal terkonfirmasi
        if (record.schedule != null)
          StatusPhaseCard(
            title: 'Jadwal Konsultasi',
            icon: Icons.calendar_month_rounded,
            iconColor: Colors.deepPurple,
            content: _buildScheduleContent(record.schedule!),
          ),
        // Catatan
        StatusPhaseCard(
          title: 'Catatan Konselor',
          icon: Icons.notes_rounded,
          iconColor: Colors.teal,
          content: Text(
            record.consultationNote,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ),
        // Status appointment / aksi user
        StatusPhaseCard(
          title: 'Status Konsultasi',
          icon: Icons.medical_services_rounded,
          iconColor: Colors.orange,
          content: _buildAppointmentContent(context, record),
        ),
        const SizedBox(height: 8),
        AuditTrailList(items: record.auditTrail),
      ],
    );
  }

  Widget _buildDownloadPdfButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onDownloadPdf,
        icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
        label: const Text(
          'Unduh Tiket & Laporan (PDF)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: AppConstants.textDark,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildResultHeader(ReportMonitorRecord record) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConstants.primaryColor, Color(0xFF5D8BBF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  record.reportCode,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: record.statusColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(record.statusIcon, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      record.statusLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            record.title,
            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            record.createdAtLabel,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleContent(ScheduleCardData schedule) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.event_available_rounded, color: Colors.deepPurple),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schedule.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                schedule.subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              if (schedule.tipeLokasi != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: schedule.tipeLokasi == 'online' ? Colors.blue.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: schedule.tipeLokasi == 'online' ? Colors.blue.shade200 : Colors.green.shade200,
                    ),
                  ),
                  child: Text(
                    'Metode: ${(schedule.tipeLokasi ?? '').toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: schedule.tipeLokasi == 'online' ? Colors.blue.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
              if (schedule.linkLokasi != null && schedule.linkLokasi!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  schedule.tipeLokasi == 'online' ? 'Tautan Video Call / Zoom:' : 'Alamat / Lokasi:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                Text(
                  schedule.linkLokasi!,
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700, decoration: TextDecoration.underline),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentContent(BuildContext context, ReportMonitorRecord record) {
    switch (record.feedbackState) {
      // ── User harus pilih slot jadwal ──────────────────────────────────────
      case FeedbackActionState.waitingSlotSelection:
        final isReschedule = record.appointmentStatus == 'reschedule';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isReschedule && (record.rescheduleNote?.isNotEmpty ?? false)) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFB923C).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Psikolog meminta reschedule: ${record.rescheduleNote}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFFEA580C)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Text(
              isReschedule
                  ? 'Silakan pilih jadwal baru dengan psikolog Anda.'
                  : 'Admin telah menunjuk psikolog. Pilih jadwal konsultasi Anda.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
            ),
            if (record.psikologName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Psikolog: ${record.psikologName}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: record.appointmentId != null && record.psikologSchedules.isNotEmpty
                    ? () => _navigateToSlotPage(context, record)
                    : null,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(isReschedule ? 'Pilih Jadwal Baru' : 'Pilih Jadwal Konsultasi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (record.psikologSchedules.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Memuat slot jadwal psikolog...',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ],
        );

      // ── Menunggu konfirmasi psikolog ────────────────────────────────────
      case FeedbackActionState.waitingPsikologConfirmation:
        return _buildStatusInfo(
          title: 'Menunggu Konfirmasi Psikolog',
          description: 'Jadwal Anda telah dikirim ke psikolog. Harap tunggu konfirmasi.',
          color: AppConstants.primaryColor,
          icon: Icons.hourglass_top_rounded,
        );

      // ── Jadwal dikonfirmasi ─────────────────────────────────────────────
      case FeedbackActionState.accepted:
        return _buildStatusInfo(
          title: 'Jadwal Dikonfirmasi ✓',
          description: 'Psikolog telah mengkonfirmasi jadwal konsultasi Anda. Harap hadir tepat waktu.',
          color: AppConstants.successColor,
          icon: Icons.check_circle_rounded,
        );

      // ── Default: masih pending/diterima, belum ada appointment ─────────
      default:
        return Text(
          record.feedbackPrompt,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
        );
    }
  }

  Future<void> _navigateToSlotPage(BuildContext context, ReportMonitorRecord record) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AppointmentSlotPage(
          appointmentId: record.appointmentId!,
          psikologId: record.psikologId!,
          psikologName: record.psikologName ?? 'Psikolog',
          availableSlots: record.psikologSchedules,
          rescheduleNote: record.appointmentStatus == 'reschedule' ? record.rescheduleNote : null,
        ),
      ),
    );

    if (result == true) {
      onRefresh();
    }
  }

  Widget _buildStatusInfo({
    required String title,
    required String description,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
