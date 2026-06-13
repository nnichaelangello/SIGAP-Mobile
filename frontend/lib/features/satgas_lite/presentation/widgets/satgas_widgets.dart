import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/pages/satgas_detail_page.dart';

/// Kartu kasus swipeable yang dipakai baik oleh Admin maupun Psikolog.
/// Desain premium dengan bayangan halus, indikator warna, dan layout bersih.
class KasusSiagaCard extends StatelessWidget {
  final Map<String, dynamic> item;

  /// Label & warna untuk aksi geser kanan (positif)
  final String swipeRightLabel;
  final IconData swipeRightIcon;
  final Color swipeRightColor;

  /// Label & warna untuk aksi geser kiri (negatif/tutup)
  final String swipeLeftLabel;
  final IconData swipeLeftIcon;
  final Color swipeLeftColor;

  /// Callback saat aksi dikonfirmasi
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;

  const KasusSiagaCard({
    super.key,
    required this.item,
    required this.swipeRightLabel,
    required this.swipeRightIcon,
    required this.swipeRightColor,
    required this.swipeLeftLabel,
    required this.swipeLeftIcon,
    required this.swipeLeftColor,
    required this.onSwipeRight,
    required this.onSwipeLeft,
  });

  @override
  Widget build(BuildContext context) {
    final isDarurat = item['darurat'] == 'darurat';
    final accentColor =
        isDarurat ? AppConstants.urgentColor : AppConstants.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Effect (Glow / Shadow)
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: isDarurat
                  ? Colors.red.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isDarurat
                  ? [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
          ),
          Dismissible(
            key: Key(item['id'].toString()),
            direction: (swipeRightLabel.isNotEmpty && swipeLeftLabel.isNotEmpty)
                ? DismissDirection.horizontal
                : (swipeRightLabel.isNotEmpty)
                    ? DismissDirection.startToEnd
                    : (swipeLeftLabel.isNotEmpty)
                        ? DismissDirection.endToStart
                        : DismissDirection.none,
            // ====== Background (Swipe Kanan) ======
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    swipeRightColor.withValues(alpha: 0.8),
                    swipeRightColor
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              child: Row(
                children: [
                  Icon(swipeRightIcon, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    swipeRightLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // ====== Secondary Background (Swipe Kiri) ======
            secondaryBackground: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    swipeLeftColor,
                    swipeLeftColor.withValues(alpha: 0.8)
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    swipeLeftLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(swipeLeftIcon, color: Colors.white, size: 28),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                if (swipeRightLabel.isNotEmpty) {
                  onSwipeRight();
                  return false;
                }
                return false;
              } else {
                if (swipeLeftLabel.isNotEmpty) {
                  onSwipeLeft();
                }
                return false; 
              }
            },
            // ====== Isi Kartu ======
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDarurat
                      ? AppConstants.urgentColor.withValues(alpha: 0.5)
                      : Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.textDark.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SatgasDetailKasusPage(item: item),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar Icon Bulat
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              isDarurat
                                  ? Icons.warning_rounded
                                  : Icons.folder_shared_rounded,
                              color: accentColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['kode'] ?? '-',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: AppConstants.textDark
                                            .withValues(alpha: 0.9),
                                      ),
                                    ),
                                    _PremiumBadge(
                                        label: item['status'] ?? '-',
                                        color: accentColor),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['info'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppConstants.textSecondary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_filled_rounded,
                                        size: 14,
                                        color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(
                                      item['waktu'] ?? '',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge premium dengan efek soft glassmorphism style
class _PremiumBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PremiumBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Footer "Rambu Disiplin" versi premium
class RambuDisiplinFooter extends StatelessWidget {
  const RambuDisiplinFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.info_rounded, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Perhatian: Mode Aksi Cepat',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Gunakan Web Dashboard (website-satgas) untuk memproses detail dokumentasi kasus secara lengkap.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppConstants.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
