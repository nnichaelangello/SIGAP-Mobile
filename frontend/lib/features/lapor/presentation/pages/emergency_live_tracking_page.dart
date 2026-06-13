import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../providers/emergency_live_provider.dart';
import '../widgets/emergency_radar_widget.dart';
import '../../services/emergency_audio_service.dart';

/// Halaman tracking realtime responder menuju lokasi korban.
/// Tersambung penuh dengan Provider `EmergencyLiveProvider`.
/// File ini sudah bersih dari data dummies palsu!
class EmergencyLiveTrackingWrapper extends StatelessWidget {
  final String incidentId;
  final LatLng initialKorbanLocation;

  const EmergencyLiveTrackingWrapper({
    super.key,
    required this.incidentId,
    required this.initialKorbanLocation,
  });

  @override
  Widget build(BuildContext context) {
    // Menyuntikkan otak provider secara khusus (scoped) hanya untuk halaman ini
    return ChangeNotifierProvider(
      create: (_) => EmergencyLiveProvider()
        ..startTracking(incidentId, initialKorbanLocation),
      child: EmergencyLiveTrackingPage(incidentId: incidentId),
    );
  }
}

class EmergencyLiveTrackingPage extends StatefulWidget {
  final String incidentId;
  const EmergencyLiveTrackingPage({super.key, required this.incidentId});

  @override
  State<EmergencyLiveTrackingPage> createState() =>
      _EmergencyLiveTrackingPageState();
}

class _EmergencyLiveTrackingPageState extends State<EmergencyLiveTrackingPage> {
  GoogleMapController? _mapController;
  bool _isInitCameraSet = false;
  bool _isResolvingNavigation = false;

  bool _isListeningAudio = false;

  @override
  void initState() {
    super.initState();
    // Do not start audio immediately, wait for user to click button
  }

  @override
  void dispose() {
    _mapController?.dispose();
    if (_isListeningAudio) {
      EmergencyAudioService.instance.stopListening();
    }
    super.dispose();
  }

  void _toggleListenAudio(String incidentId) {
    if (_isListeningAudio) {
      EmergencyAudioService.instance.stopListening();
      setState(() => _isListeningAudio = false);
    } else {
      EmergencyAudioService.instance.startListening(incidentId);
      setState(() => _isListeningAudio = true);
    }
  }

  // ══════════════════════════════════════════════════
  // NAVIGASI KE GOOGLE MAPS EXTERNAL
  // ══════════════════════════════════════════════════
  Future<void> _openMapApp(LatLng korbanLoc) async {
    final uri = Uri.parse(
        'google.navigation:q=${korbanLoc.latitude},${korbanLoc.longitude}&mode=d');
    try {
      final launched = await canLaunchUrl(uri);
      if (launched) {
        await launchUrl(uri);
      } else {
        final webUri = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=${korbanLoc.latitude},${korbanLoc.longitude}&travelmode=driving');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka aplikasi peta eksternal.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════
  // KAMERA OTOMATIS BERGESER & ZOOM (BOUNDING BOX)
  // ══════════════════════════════════════════════════
  void _updateCameraBounds(LatLng p1, LatLng p2, {bool animate = true}) {
    if (_mapController == null) return;
    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(p1.latitude, p2.latitude),
        math.min(p1.longitude, p2.longitude),
      ),
      northeast: LatLng(
        math.max(p1.latitude, p2.latitude),
        math.max(p1.longitude, p2.longitude),
      ),
    );

    if (animate) {
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } else {
      _mapController!.moveCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  }

  // ══════════════════════════════════════════════════
  // DIALOG KONFIRMASI (Mencegah Salah Tekan)
  // ══════════════════════════════════════════════════
  void _confirmResolve(BuildContext context, EmergencyLiveProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Lapor Konfirmasi Tiba'),
        content: const Text(
            'Apakah Anda yakin sudah bersamanya dan situasi sudah dapat dikendalikan? Aksi ini akan menghentikan sistem pelacakan (mematikan GPS korban dan Anda) dan memberitahu Admin Utama.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.resolveIncident();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Saya Bersamanya'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // BUILD UI UTAMA (REAKTIF/TERIKAT DENGAN PROVIDER)
  // ══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmergencyLiveProvider>();

    // >> LISTENER STATUS: SELESAI
    // Guard untuk menghentikan build berulang yang mendaftarkan
    // addPostFrameCallback berkali-kali sehingga Navigator.pop() ganda.
    if (provider.state == EmergencyLiveState.resolved) {
      if (!_isResolvingNavigation) {
        _isResolvingNavigation = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          
          String msg = 'Misi Penyelamatan Selesai ✔️';
          Color bgColor = Colors.green;
          
          if (provider.errorMessage == 'stopped_by_user' || provider.errorMessage == 'cancelled') {
            msg = 'Korban telah membatalkan sinyal darurat (Situasi Aman).';
            bgColor = Colors.orange;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: bgColor,
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.of(context).pop();
        });
      }
      return const Scaffold(backgroundColor: Colors.white);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // >> STATUS: ERROR (IZIN GPS DITOLAK ATAU OFFLINE)
          if (provider.state == EmergencyLiveState.error)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_off, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage ?? 'Gagal mengakses lokasi',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kembali'),
                    )
                  ],
                ),
              ),
            ),

          // >> STATUS: LOADING (Cari GPS Awal)
          if (provider.state == EmergencyLiveState.initial ||
              provider.state == EmergencyLiveState.loading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EmergencyRadarWidget(color: Colors.red, isActive: true),
                  SizedBox(height: 20),
                  Text(
                    'Menghubungkan & Meminta Izin Lokasi...',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),

          // >> STATUS: TRACKING AKTIF (Map Tampil)
          if (provider.state == EmergencyLiveState.active &&
              provider.responderPos != null &&
              provider.victimPos != null)
            _buildLiveMap(context, provider),

          // >> PANEL BAWAH
          if (provider.state == EmergencyLiveState.active)
            _buildBottomPanel(context, provider),

          // >> TOMBOL RESET KAMERA
          if (provider.state == EmergencyLiveState.active)
            Positioned(
              right: 16,
              bottom: 280,
              child: FloatingActionButton.small(
                onPressed: () {
                  if (provider.responderPos != null &&
                      provider.victimPos != null) {
                    _updateCameraBounds(
                        provider.responderPos!, provider.victimPos!);
                  }
                },
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 4,
                child: const Icon(Icons.center_focus_strong),
              ),
            ),
        ],
      ),
    );
  }

  // >> WIDGET PETA GOOGLE
  Widget _buildLiveMap(BuildContext context, EmergencyLiveProvider provider) {
    final markers = {
      Marker(
        markerId: const MarkerId('korban'),
        position: provider.victimPos!,
        infoWindow: const InfoWindow(title: 'Lokasi Korban Terakhir'),
        // Warna Pucat Biru jika OFFLINE, Merah tajam jika ONLINE!
        icon: BitmapDescriptor.defaultMarkerWithHue(provider.isVictimOffline
            ? BitmapDescriptor.hueAzure
            : BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: const MarkerId('responder'),
        position: provider.responderPos!,
        infoWindow: const InfoWindow(title: 'Posisi Penyelamat (Anda)'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    final polylines = {
      Polyline(
        polylineId: const PolylineId('route_distance'),
        points: [provider.responderPos!, provider.victimPos!],
        // Garis putus-putus kelabu jika offline signal, garis solid biru jika online!
        color: provider.isVictimOffline ? Colors.grey : Colors.blue,
        width: 5,
        patterns: provider.isVictimOffline
            ? [PatternItem.dash(20), PatternItem.gap(10)]
            : [],
      ),
    };

    return GoogleMap(
      mapType: MapType.normal,
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      initialCameraPosition:
          CameraPosition(target: provider.victimPos!, zoom: 14.5),
      markers: markers,
      polylines: polylines,
      onMapCreated: (controller) {
        _mapController = controller;
        // Reset flag karena controller baru (misal: setelah resume dari background)
        _isInitCameraSet = false;

        // Simpan referensi provider SEBELUM async gap agar tidak melanggar lint
        final providerRef = context.read<EmergencyLiveProvider>();

        if (!_isInitCameraSet) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            if (providerRef.responderPos != null &&
                providerRef.victimPos != null) {
              _updateCameraBounds(
                  providerRef.responderPos!, providerRef.victimPos!);
            }
            _isInitCameraSet = true;
          });
        }
      },
    );
  }

  // >> WIDGET PANEL BAWAH
  Widget _buildBottomPanel(
      BuildContext context, EmergencyLiveProvider provider) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4))
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),

            // >> INDIKATOR STATUS ONLINE / OFFLINE
            if (provider.isVictimOffline)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.signal_wifi_off_rounded,
                        size: 16, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Sinyal Korban Hilang. Titik ini adalah lokasi terakhir diketahui.',
                        style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text(
                'SOS: Respons Bahaya',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),

            const SizedBox(height: 12),

            // >> INFO JARAK TERJAUH
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.near_me, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  'Jarak ± ${(provider.distanceInMeters / 1000).toStringAsFixed(2)} km',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 16),

            // >> TOMBOL BUKA MAPS UTAMA
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _openMapApp(provider.victimPos!),
                icon: const Icon(Icons.navigation, size: 20),
                label: const Text('NAVIGASI GOOGLE MAPS',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // >> TOMBOL DENGARKAN AUDIO
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (provider.currentIncidentId != null) {
                    _toggleListenAudio(provider.currentIncidentId!);
                  }
                },
                icon: Icon(_isListeningAudio ? Icons.stop_circle : Icons.headphones, size: 20),
                label: Text(_isListeningAudio ? 'STOP MENDENGARKAN' : 'PANTAU AUDIO REAL-TIME',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isListeningAudio ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // >> TOMBOL KONFIRMASI AMAN / TUNTAS
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _confirmResolve(context, provider),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('SAYA SUDAH TIBA BERSAMANYA',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
