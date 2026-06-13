import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

class SatgasDetailKasusPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const SatgasDetailKasusPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isDarurat = item['darurat'] == 'darurat';
    final accentColor =
        isDarurat ? AppConstants.urgentColor : AppConstants.primaryColor;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppConstants.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Laporan',
          style: TextStyle(
            color: AppConstants.textDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Kasus
            _buildInfoCard(accentColor, isDarurat),
            const SizedBox(height: 24),

            // Deskripsi Penjelasan
            const Text(
              'Kronologi / Deskripsi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                item['info'] ?? 'Tidak ada deskripsi rinci.',
                style: const TextStyle(
                  color: AppConstants.textSecondary,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Timeline Status (Mini visualisasi)
            const Text(
              'Rekam Jejak Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimelineNode(
              title: 'Laporan Masuk',
              time: item['waktu'] ?? '',
              isActive: true,
              isFirst: true,
            ),
            _buildTimelineNode(
              title: 'Menunggu Tanggapan',
              time: '-',
              isActive: false,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Color accentColor, bool isDarurat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['kode'] ?? '-',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDarurat ? Colors.red : Colors.orange)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDarurat ? Colors.red : Colors.orange)
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDarurat ? Icons.warning_rounded : Icons.info_outline,
                      size: 14,
                      color: isDarurat ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['status'] ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarurat ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.person_pin, size: 20, color: Colors.grey),
              SizedBox(width: 8),
              Text('Pelapor Anonim',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.date_range_rounded,
                  size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Masuk: ${item['waktu']}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode({
    required String title,
    required String time,
    required bool isActive,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 10,
                  color: isFirst ? Colors.transparent : Colors.grey.shade300,
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? AppConstants.primaryColor
                        : Colors.grey.shade300,
                    border: Border.all(
                      color: isActive
                          ? AppConstants.primaryColor.withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: 4,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? AppConstants.textDark : Colors.grey,
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
