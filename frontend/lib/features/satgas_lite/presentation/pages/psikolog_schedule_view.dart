import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/features/satgas_lite/data/repositories/api_schedule_repository.dart';
import 'package:sigap_mobile/core/services/api_service.dart';

class PsikologScheduleView extends StatefulWidget {
  const PsikologScheduleView({super.key});

  @override
  State<PsikologScheduleView> createState() => _PsikologScheduleViewState();
}

class _PsikologScheduleViewState extends State<PsikologScheduleView> {
  final _repository = ApiScheduleRepository();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _schedules = [];

  final _formKey = GlobalKey<FormState>();
  String _selectedHari = 'Senin';
  final _hariOptions = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  
  TimeOfDay _jamMulai = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _jamSelesai = const TimeOfDay(hour: 12, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final psikologId = ApiService.instance.userId;
      if (psikologId == 0) throw Exception('Psikolog ID tidak ditemukan');
      
      final data = await _repository.getPsikologSchedules(psikologId);
      setState(() {
        _schedules = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    
    final tMulai = '${_jamMulai.hour.toString().padLeft(2, '0')}:${_jamMulai.minute.toString().padLeft(2, '0')}';
    final tSelesai = '${_jamSelesai.hour.toString().padLeft(2, '0')}:${_jamSelesai.minute.toString().padLeft(2, '0')}';

    try {
      await _repository.addPsikologSchedule(
        hari: _selectedHari,
        jamMulai: tMulai,
        jamSelesai: tSelesai,
      );
      _loadSchedules();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal berhasil ditambahkan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  Future<void> _deleteSchedule(int scheduleId) async {
    try {
      await _repository.deletePsikologSchedule(scheduleId);
      _loadSchedules();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  Future<void> _pickTime(BuildContext context, bool isMulai) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isMulai ? _jamMulai : _jamSelesai,
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _jamMulai = picked;
        } else {
          _jamSelesai = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildAddForm(context),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _error != null 
              ? Center(child: Text(_error!))
              : _buildScheduleList(),
        )
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: Colors.teal),
          const SizedBox(width: 8),
          Text(
            'Kelola Jadwal Ketersediaan',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddForm(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedHari,
              decoration: const InputDecoration(labelText: 'Hari'),
              items: _hariOptions.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
              onChanged: (v) => setState(() => _selectedHari = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Mulai'),
                      child: Text(_jamMulai.format(context)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Selesai'),
                      child: Text(_jamSelesai.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addSchedule,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Tambah Slot', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    if (_schedules.isEmpty) {
      return const Center(child: Text('Belum ada jadwal yang ditambahkan.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final s = _schedules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.access_time_rounded, color: Colors.teal),
            title: Text(s['hari'] ?? ''),
            subtitle: Text('${s['jam_mulai']} - ${s['jam_selesai']}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteSchedule(s['id']),
            ),
          ),
        );
      },
    );
  }
}
