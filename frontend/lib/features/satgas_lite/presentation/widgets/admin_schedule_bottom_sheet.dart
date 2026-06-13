import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/satgas_lite/data/repositories/api_schedule_repository.dart';

class AdminScheduleBottomSheet extends StatefulWidget {
  final int reportId;
  final VoidCallback onSuccess;

  const AdminScheduleBottomSheet({
    super.key,
    required this.reportId,
    required this.onSuccess,
  });

  @override
  State<AdminScheduleBottomSheet> createState() => _AdminScheduleBottomSheetState();
}

class _AdminScheduleBottomSheetState extends State<AdminScheduleBottomSheet> {
  final _repository = ApiScheduleRepository();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _psikologList = [];
  int? _selectedPsikologId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPsikologs();
  }

  Future<void> _loadPsikologs() async {
    try {
      final data = await _repository.getPsikologList();
      setState(() {
        _psikologList = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedPsikologId == null) return;
    
    setState(() => _isSubmitting = true);
    try {
      await _repository.initiateAppointment(
        reportId: widget.reportId,
        psikologId: _selectedPsikologId!,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jadwalkan Konsultasi',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(
              _error!,
              style: GoogleFonts.poppins(color: Colors.red),
            )
          else ...[
            Text(
              'Pilih Psikolog untuk Kasus Ini',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  hint: Text(
                    '-- Pilih Psikolog --',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  value: _selectedPsikologId,
                  items: _psikologList.map((p) {
                    return DropdownMenuItem<int>(
                      value: p['id'],
                      child: Text(
                        p['nama'] ?? 'Unknown',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedPsikologId = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _selectedPsikologId == null || _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Tugaskan & Jadwalkan',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
