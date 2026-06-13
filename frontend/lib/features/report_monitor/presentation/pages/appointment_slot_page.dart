import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/core/services/api_service.dart';
import 'package:sigap_mobile/features/report_monitor/data/models/report_monitor_record.dart';

/// Halaman user memilih slot jadwal konsultasi dengan psikolog.
/// Dipanggil ketika status laporan = 'dijadwalkan' atau appointment status = 'reschedule'.
class AppointmentSlotPage extends StatefulWidget {
  final int appointmentId;
  final int psikologId;
  final String psikologName;
  final List<PsikologSlot> availableSlots;
  final String? rescheduleNote; // catatan reschedule dari psikolog (jika ada)

  const AppointmentSlotPage({
    super.key,
    required this.appointmentId,
    required this.psikologId,
    required this.psikologName,
    required this.availableSlots,
    this.rescheduleNote,
  });

  @override
  State<AppointmentSlotPage> createState() => _AppointmentSlotPageState();
}

class _AppointmentSlotPageState extends State<AppointmentSlotPage> {
  DateTime? _selectedDate;
  PsikologSlot? _selectedSlot;
  String _tipeLokasi = 'online';
  bool _isLoading = false;
  String? _errorMessage;

  // Mapping hari Indonesia ke weekday dart
  static const _hariToWeekday = {
    'senin': DateTime.monday,
    'selasa': DateTime.tuesday,
    'rabu': DateTime.wednesday,
    'kamis': DateTime.thursday,
    'jumat': DateTime.friday,
    'sabtu': DateTime.saturday,
  };

  static const _hariLabel = {
    'senin': 'Senin',
    'selasa': 'Selasa',
    'rabu': 'Rabu',
    'kamis': 'Kamis',
    'jumat': 'Jumat',
    'sabtu': 'Sabtu',
  };

  List<PsikologSlot> get _slotsForSelectedDay {
    if (_selectedDate == null) return [];
    final weekday = _selectedDate!.weekday;
    return widget.availableSlots
        .where((s) => _hariToWeekday[s.hari] == weekday)
        .toList();
  }

  bool _isDateAllowed(DateTime date) {
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) return false;
    if (date.weekday == DateTime.sunday) return false;
    final weekday = date.weekday;
    return widget.availableSlots.any((s) => _hariToWeekday[s.hari] == weekday);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      selectableDayPredicate: _isDateAllowed,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null; // reset slot saat tanggal berubah
      });
    }
  }

  Future<void> _submitSlot() async {
    if (_selectedDate == null || _selectedSlot == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();

    try {
      final tanggal = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final resp = await ApiService.instance.post('/api/appointments/select', {
        'appointment_id': widget.appointmentId,
        'tanggal': tanggal,
        'jam_mulai': _selectedSlot!.jamMulai,
        'jam_selesai': _selectedSlot!.jamSelesai,
        'tipe_lokasi': _tipeLokasi,
      });

      if (!mounted) return;

      if (resp.success) {
        Navigator.of(context).pop(true); // true = refresh parent
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Jadwal berhasil dipilih! Menunggu konfirmasi psikolog.')),
              ],
            ),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        setState(() {
          _errorMessage = resp.error ?? 'Gagal memilih jadwal. Coba lagi.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reschedule notice
                    if (widget.rescheduleNote != null) ...[
                      _buildRescheduleNotice(),
                      const SizedBox(height: 16),
                    ],
                    // Psikolog info
                    _buildPsikologCard(),
                    const SizedBox(height: 20),
                    // Available hari
                    _buildAvailableHari(),
                    const SizedBox(height: 20),
                    // Date picker
                    _buildDateSelector(),
                    const SizedBox(height: 20),
                    // Slot picker
                    if (_selectedDate != null) ...[
                      _buildSlotPicker(),
                      const SizedBox(height: 24),
                      _buildLocationSelector(),
                      const SizedBox(height: 24),
                    ],
                    // Error
                    if (_errorMessage != null) ...[
                      _buildErrorBanner(),
                      const SizedBox(height: 16),
                    ],
                    // Submit
                    _buildSubmitButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: Icon(Icons.arrow_back_rounded, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Jadwal Konsultasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  'Pilih tanggal & waktu yang tersedia',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRescheduleNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFB923C).withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Psikolog Meminta Perubahan Jadwal',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEA580C),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.rescheduleNote!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPsikologCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConstants.primaryColor, Color(0xFF5D8BBF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Psikolog yang Ditunjuk',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.psikologName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableHari() {
    final hariList = widget.availableSlots.map((s) => s.hari).toSet().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hari Konsultasi Tersedia',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hariList.map((hari) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
              ),
              child: Text(
                _hariLabel[hari] ?? hari,
                style: const TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final dateText = _selectedDate != null
        ? DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate!)
        : 'Ketuk untuk memilih tanggal';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Tanggal',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _selectedDate != null
                    ? AppConstants.primaryColor
                    : Colors.grey.shade200,
                width: _selectedDate != null ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: _selectedDate != null
                      ? AppConstants.primaryColor
                      : Colors.grey.shade400,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                      color: _selectedDate != null
                          ? Colors.grey.shade800
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotPicker() {
    final slots = _slotsForSelectedDay;
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFB923C).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tidak ada slot tersedia di hari ini. Pilih tanggal lain.',
                style: TextStyle(color: Color(0xFFEA580C), fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Waktu',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),
        ...slots.map((slot) {
          final isSelected = _selectedSlot?.scheduleId == slot.scheduleId;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedSlot = slot);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppConstants.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppConstants.primaryColor : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppConstants.primaryColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
                    : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.2) : AppConstants.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.access_time_rounded,
                      color: isSelected ? Colors.white : AppConstants.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${slot.jamMulai} – ${slot.jamSelesai}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isSelected ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          '${_hariLabel[slot.hari] ?? slot.hari} · ${slot.jamMulai} s.d. ${slot.jamSelesai}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white70 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metode Konsultasi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _tipeLokasi = 'online');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _tipeLokasi == 'online' ? AppConstants.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _tipeLokasi == 'online' ? AppConstants.primaryColor : Colors.grey.shade300,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_camera_front_rounded, 
                        color: _tipeLokasi == 'online' ? Colors.white : Colors.grey.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text('Online', style: TextStyle(
                        color: _tipeLokasi == 'online' ? Colors.white : Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                      )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _tipeLokasi = 'offline');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _tipeLokasi == 'offline' ? AppConstants.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _tipeLokasi == 'offline' ? AppConstants.primaryColor : Colors.grey.shade300,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_rounded, 
                        color: _tipeLokasi == 'offline' ? Colors.white : Colors.grey.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text('Offline', style: TextStyle(
                        color: _tipeLokasi == 'offline' ? Colors.white : Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.urgentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.urgentColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppConstants.urgentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: AppConstants.urgentColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _selectedDate != null && _selectedSlot != null && !_isLoading;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: canSubmit ? _submitSlot : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          disabledBackgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.grey.shade400,
          elevation: canSubmit ? 4 : 0,
          shadowColor: AppConstants.primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Konfirmasi Pilihan Jadwal',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
      ),
    );
  }
}
