import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/lapor/presentation/pages/lapor_isu_page.dart';
import 'package:sigap_mobile/features/pantau/presentation/pages/pantau_page.dart';
import 'package:sigap_mobile/features/lapor/presentation/pages/active_emergencies_page.dart';

// Import for Clean Architecture DI
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:sigap_mobile/core/services/api_service.dart';
import 'package:sigap_mobile/features/lapor/data/datasources/report_remote_data_source.dart';
import 'package:sigap_mobile/features/lapor/data/repositories/report_repository_impl.dart';
import 'package:sigap_mobile/features/lapor/domain/usecases/submit_report_usecase.dart';
import 'package:sigap_mobile/features/lapor/presentation/provider/lapor_isu_provider.dart';

/// Grid 2 layanan utama dengan efek Glassmorphism.
/// Pantau Aku: terkunci untuk Guest.
/// Buat Laporan: terbuka untuk semua pengguna.
class ServiceGrid extends StatelessWidget {
  final bool isGuest;

  const ServiceGrid({super.key, this.isGuest = false});

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 30,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Login Diperlukan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Anda harus login terlebih dahulu\nuntuk mengakses fitur ini.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  "Mengerti",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Portal Layanan",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ServiceItem(
                icon: Icons.radar_rounded,
                label: "Pantau Aku",
                isLocked: isGuest,
                onTap: isGuest
                    ? () => _showLoginDialog(context)
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PantauPage(),
                          ),
                        );
                      },
              ),
              _ServiceItem(
                icon: Icons.assignment_add,
                label: "Buat Laporan",
                isLocked: false,
                onTap: () {
                  final remoteDataSource =
                      ReportRemoteDataSourceImpl(client: http.Client());
                  final repository =
                      ReportRepositoryImpl(remoteDataSource: remoteDataSource);
                  final submitUseCase = SubmitReportUseCase(repository);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) =>
                            LaporIsuProvider(submitUseCase: submitUseCase),
                        child: const LaporIsuPage(),
                      ),
                    ),
                  );
                },
              ),
              _ServiceItem(
                icon: Icons.local_hospital_rounded,
                label: "Darurat",
                isLocked: isGuest,
                onTap: isGuest
                    ? () => _showLoginDialog(context)
                    : () async {
                        // Tampilkan loading sebentar
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: CircularProgressIndicator(color: AppConstants.primaryColor),
                          ),
                        );

                        try {
                          final resp = await ApiService.instance.get('/api/emergency/pending');
                          if (context.mounted) Navigator.pop(context); // Tutup loading

                          if (resp.success && resp.data != null) {
                            final dataList = resp.data!['data'] as List? ?? [];
                            if (dataList.isEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Situasi Aman. Tidak ada panggilan darurat.'),
                                  backgroundColor: AppConstants.successColor,
                                ));
                              }
                            } else {
                              // Selalu buka halaman daftar SOS, meski hanya ada 1.
                              // Responder harus selalu melihat konteks lengkap sebelum merespon.
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ActiveEmergenciesPage(
                                      initialEmergencies: dataList,
                                    ),
                                  ),
                                );
                              }
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Gagal memuat status darurat: ${resp.error}'),
                                backgroundColor: AppConstants.urgentColor,
                              ));
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Terjadi kesalahan jaringan: $e'),
                              backgroundColor: AppConstants.urgentColor,
                            ));
                          }
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget item tunggal pada grid layanan — desain glassmorphism.
/// Jika [isLocked] = true, ikon ditimpa gembok + tap menampilkan popup login.
class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLocked;
  final VoidCallback? onTap;

  const _ServiceItem({
    required this.icon,
    required this.label,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Center(
                  child: isLocked
                      ? Icon(
                          Icons.lock_rounded,
                          color: Colors.grey.shade400,
                          size: 32,
                        )
                      : Icon(
                          icon,
                          color: AppConstants.primaryColor,
                          size: 36,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isLocked ? Colors.grey.shade400 : AppConstants.textDark,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
