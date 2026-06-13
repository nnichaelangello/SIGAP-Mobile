import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/core/services/api_service.dart';
import 'package:sigap_mobile/features/lapor/presentation/pages/emergency_live_tracking_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ActiveEmergenciesPage extends StatefulWidget {
  final List<dynamic> initialEmergencies;

  const ActiveEmergenciesPage({super.key, required this.initialEmergencies});

  @override
  State<ActiveEmergenciesPage> createState() => _ActiveEmergenciesPageState();
}

class _ActiveEmergenciesPageState extends State<ActiveEmergenciesPage> {
  late List<dynamic> emergencies;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    emergencies = widget.initialEmergencies;
  }

  Future<void> _fetchEmergencies() async {
    setState(() => _isLoading = true);
    try {
      final resp = await ApiService.instance.get('/api/emergency/pending');
      if (resp.success && resp.data != null) {
        setState(() {
          emergencies = resp.data!['data'] as List? ?? [];
        });
      }
    } catch (e) {
      // Ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onRespond(Map<String, dynamic> emergency) async {
    // ── Field yang benar dari API backend ──
    // Backend mengembalikan: id (int), incident_id (string), lat (double), lng (double)
    final incidentDbId = emergency['id'] as int? ?? 0;
    final incidentStrId = emergency['incident_id']?.toString() ?? '';
    final lat = (emergency['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (emergency['lng'] as num?)?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppConstants.primaryColor),
      ),
    );

    try {
      // Kirim keduanya agar backend kompatibel (incident_db_id + incident_id)
      final resp = await ApiService.instance.post('/api/emergency/respond', {
        'incident_db_id': incidentDbId,
        'incident_id': incidentStrId,
      });
      if (mounted) Navigator.pop(context); // close loading

      if (resp.success) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EmergencyLiveTrackingWrapper(
                incidentId: incidentStrId,
                initialKorbanLocation: LatLng(lat, lng),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal merespons: ${resp.error}'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Kesalahan jaringan: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Daftar Panggilan Darurat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppConstants.urgentColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchEmergencies,
            tooltip: 'Refresh daftar',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.urgentColor))
          : emergencies.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Tidak ada panggilan darurat aktif.',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: emergencies.length,
                  itemBuilder: (context, index) {
                    final item = emergencies[index];
                    final date = DateTime.tryParse(item['created_at'] ?? '')?.toLocal();
                    final timeStr = date != null
                        ? '${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')} ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}'
                        : '-';
                    final responderCount = item['responder_count'] as int? ?? 0;

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppConstants.urgentColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.warning_rounded, color: AppConstants.urgentColor, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['nama_korban'] ?? 'Pengguna #${item['korban_id']}',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item['no_hp_korban'] ?? '',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppConstants.urgentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (item['status'] ?? 'active').toUpperCase(),
                                    style: const TextStyle(
                                      color: AppConstants.urgentColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.people_outline,
                                  size: 14,
                                  color: responderCount > 0 ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$responderCount responder',
                                  style: TextStyle(
                                    color: responderCount > 0 ? Colors.green : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _onRespond(item),
                                icon: const Icon(Icons.navigation_rounded, size: 18),
                                label: const Text('Merespon & Navigasi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.urgentColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
