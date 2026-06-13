import 'package:flutter/material.dart';
import '../../presentation/widgets/timeline_tracker.dart';
import '../../presentation/widgets/audit_trail_list.dart';

enum FeedbackActionState { waiting, waitingSlotSelection, waitingPsikologConfirmation, accepted, rescheduleRequested }

class ScheduleCardData {
  final String title;
  final String subtitle;
  final String? tipeLokasi;
  final String? linkLokasi;

  const ScheduleCardData({
    required this.title,
    required this.subtitle,
    this.tipeLokasi,
    this.linkLokasi,
  });
}

class PsikologSlot {
  final int scheduleId;
  final String hari;
  final String jamMulai;
  final String jamSelesai;

  const PsikologSlot({
    required this.scheduleId,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
  });

  factory PsikologSlot.fromMap(Map<String, dynamic> m) => PsikologSlot(
        scheduleId: m['id'] ?? 0,
        hari: m['hari'] ?? '',
        jamMulai: m['jam_mulai'] ?? '',
        jamSelesai: m['jam_selesai'] ?? '',
      );
}

class ReportMonitorRecord {
  final String reportCode;
  final String title;
  final String createdAtLabel;
  final String statusLabel;
  final IconData statusIcon;
  final Color statusColor;
  final List<TimelineStepModel> timelineSteps;
  final ScheduleCardData? schedule;
  final String consultationNote;
  final String feedbackPrompt;
  final FeedbackActionState feedbackState;
  final List<AuditTrailItem> auditTrail;

  // Appointment data
  final int? appointmentId;
  final String? appointmentStatus; // menunggu_user, menunggu_psikolog, reschedule, diterima, selesai
  final int? psikologId;
  final String? psikologName;
  final List<PsikologSlot> psikologSchedules;
  final String? rescheduleNote;
  final String? tipeLokasi;
  final String? linkLokasi;
  final int? reportId; // raw backend ID

  const ReportMonitorRecord({
    required this.reportCode,
    required this.title,
    required this.createdAtLabel,
    required this.statusLabel,
    required this.statusIcon,
    required this.statusColor,
    required this.timelineSteps,
    required this.schedule,
    required this.consultationNote,
    required this.feedbackPrompt,
    required this.feedbackState,
    required this.auditTrail,
    this.appointmentId,
    this.appointmentStatus,
    this.psikologId,
    this.psikologName,
    this.psikologSchedules = const [],
    this.rescheduleNote,
    this.tipeLokasi,
    this.linkLokasi,
    this.reportId,
  });

  ReportMonitorRecord copyWith({
    String? reportCode,
    String? title,
    String? createdAtLabel,
    String? statusLabel,
    IconData? statusIcon,
    Color? statusColor,
    List<TimelineStepModel>? timelineSteps,
    ScheduleCardData? schedule,
    bool clearSchedule = false,
    String? consultationNote,
    String? feedbackPrompt,
    FeedbackActionState? feedbackState,
    List<AuditTrailItem>? auditTrail,
    int? appointmentId,
    String? appointmentStatus,
    int? psikologId,
    String? psikologName,
    List<PsikologSlot>? psikologSchedules,
    String? rescheduleNote,
    String? tipeLokasi,
    String? linkLokasi,
    int? reportId,
  }) {
    return ReportMonitorRecord(
      reportCode: reportCode ?? this.reportCode,
      title: title ?? this.title,
      createdAtLabel: createdAtLabel ?? this.createdAtLabel,
      statusLabel: statusLabel ?? this.statusLabel,
      statusIcon: statusIcon ?? this.statusIcon,
      statusColor: statusColor ?? this.statusColor,
      timelineSteps: timelineSteps ?? this.timelineSteps,
      schedule: clearSchedule ? null : schedule ?? this.schedule,
      consultationNote: consultationNote ?? this.consultationNote,
      feedbackPrompt: feedbackPrompt ?? this.feedbackPrompt,
      feedbackState: feedbackState ?? this.feedbackState,
      auditTrail: auditTrail ?? this.auditTrail,
      appointmentId: appointmentId ?? this.appointmentId,
      appointmentStatus: appointmentStatus ?? this.appointmentStatus,
      psikologId: psikologId ?? this.psikologId,
      psikologName: psikologName ?? this.psikologName,
      psikologSchedules: psikologSchedules ?? this.psikologSchedules,
      rescheduleNote: rescheduleNote ?? this.rescheduleNote,
      tipeLokasi: tipeLokasi ?? this.tipeLokasi,
      linkLokasi: linkLokasi ?? this.linkLokasi,
      reportId: reportId ?? this.reportId,
    );
  }
}
