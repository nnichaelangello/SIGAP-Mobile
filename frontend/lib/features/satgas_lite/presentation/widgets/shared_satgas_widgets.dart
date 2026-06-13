import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/core/widgets/blur_extension.dart';
import 'package:sigap_mobile/features/satgas_lite/domain/entities/kasus_item.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/notifiers/satgas_notifier.dart';

// ─────────────────────────────────────────────────────
//  Shared widgets used by both AdminLitePage and PsikologLitePage
// ─────────────────────────────────────────────────────

/// Stat card — menampilkan angka ringkasan (Darurat, Diproses, dll).
class SatgasStatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const SatgasStatCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              count,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppConstants.textDark,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header untuk list kasus — judul + dropdown filter.
class SatgasListHeader extends StatelessWidget {
  final String title;
  final List<KasusFilter> filterOptions;
  final KasusFilter defaultFilter;

  const SatgasListHeader({
    super.key,
    required this.title,
    required this.filterOptions,
    this.defaultFilter = KasusFilter.terbaru,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppConstants.textDark,
              ),
            ),
            Consumer<SatgasNotifier>(
              builder: (context, notifier, _) {
                final currentFilter = switch (notifier.state) {
                  KasusLoaded(activeFilter: final f) => f,
                  _ => defaultFilter,
                };

                return PopupMenuButton<KasusFilter>(
                  onSelected: notifier.changeFilter,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  itemBuilder: (context) => filterOptions
                      .map((f) => PopupMenuItem(
                            value: f,
                            child: Text(f.label),
                          ))
                      .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          currentFilter.label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 16, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Background blur layer — glassmorphism effect.
class SatgasBackgroundLayer extends StatelessWidget {
  final Color color;
  const SatgasBackgroundLayer({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -20,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
            ).blurred(blur: 80),
          ),
          Positioned(
            top: 150,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
              ),
            ).blurred(blur: 80),
          ),
        ],
      ),
    );
  }
}

/// Empty state configurable.
class SatgasEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const SatgasEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
