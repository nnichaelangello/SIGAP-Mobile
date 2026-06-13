import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/satgas_lite/domain/entities/kasus_item.dart';
import 'package:sigap_mobile/features/satgas_lite/data/repositories/api_kasus_repository.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/notifiers/satgas_notifier.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/widgets/satgas_widgets.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/widgets/shared_satgas_widgets.dart';
import 'package:sigap_mobile/features/auth/presentation/pages/masuk_page.dart';

import 'package:sigap_mobile/features/satgas_lite/presentation/pages/psikolog_schedule_view.dart';

class PsikologLitePage extends StatelessWidget {
  final String userName;

  const PsikologLitePage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SatgasNotifier>(
      create: (_) {
        final notifier = SatgasNotifier(
          repository: ApiKasusRepository(role: SatgasRole.psikolog),
        );
        notifier.loadKasus();
        return notifier;
      },
      child: _PsikologLiteView(userName: userName),
    );
  }
}

/// View dengan navigasi tab untuk Psikolog
class _PsikologLiteView extends StatefulWidget {
  final String userName;

  const _PsikologLiteView({required this.userName});

  @override
  State<_PsikologLiteView> createState() => _PsikologLiteViewState();
}

class _PsikologLiteViewState extends State<_PsikologLiteView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        children: [
          const SatgasBackgroundLayer(color: Colors.teal),
          Column(
            children: [
              _PsikologHeader(userName: widget.userName),
              Expanded(
                child: _currentIndex == 0 
                  ? _buildKasusTab() 
                  : const PsikologScheduleView(),
              ),
              if (_currentIndex == 0) const RambuDisiplinFooter(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Antrean Kasus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Jadwal Saya',
          ),
        ],
      ),
    );
  }

  Widget _buildKasusTab() {
    return Consumer<SatgasNotifier>(
      builder: (context, notifier, _) {
        return switch (notifier.state) {
          KasusInitial() || KasusLoading() =>
            const Center(
              child: CircularProgressIndicator(
                color: AppConstants.primaryColor,
              ),
            ),
          KasusError(message: final msg) =>
            Center(child: Text(msg)),
          KasusLoaded(items: final items) =>
            items.isEmpty
                ? const SatgasEmptyState(
                    title: 'Hari Ini Kosong',
                    subtitle: 'Tidak ada jadwal konsultasi\nyang perlu ditangani.',
                    icon: Icons.event_available_outlined,
                  )
                : _PsikologKasusList(items: items),
        };
      },
    );
  }
}

// ─────────────────────────────────────────────────────
//  PSIKOLOG HEADER
// ─────────────────────────────────────────────────────

class _PsikologHeader extends StatelessWidget {
  final String userName;

  const _PsikologHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Klinik Satgas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Psikolog $userName',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.textDark,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MasukPage()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppConstants.textDark, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  KASUS LIST
// ─────────────────────────────────────────────────────

class _PsikologKasusList extends StatelessWidget {
  final List<KasusItem> items;

  const _PsikologKasusList({required this.items});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<SatgasNotifier>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                SatgasStatCard(
                  title: 'Hari Ini',
                  count: notifier.totalAntrean.toString(),
                  icon: Icons.calendar_today_rounded,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                SatgasStatCard(
                  title: 'Menunggu',
                  count: notifier.jumlahDarurat.toString(),
                  icon: Icons.hourglass_top_rounded,
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ),
        const SatgasListHeader(
          title: 'Agenda Konsultasi',
          filterOptions: [
            KasusFilter.mendesak,
            KasusFilter.hariIni,
            KasusFilter.mingguIni,
          ],
          defaultFilter: KasusFilter.mendesak,
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              return KasusSiagaCard(
                item: item.toMap(),
                swipeRightLabel: 'Mulai Sesi',
                swipeRightIcon: Icons.play_arrow_rounded,
                swipeRightColor: Colors.blue.shade600,
                swipeLeftLabel: 'Selesai & Catat',
                swipeLeftIcon: Icons.edit_note_rounded,
                swipeLeftColor: Colors.teal.shade600,
                onSwipeRight: () => _onMulaiSesi(context, item),
                onSwipeLeft: () => _onBeriCatatan(context, item),
              );
            },
            childCount: items.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  Future<void> _onMulaiSesi(BuildContext context, KasusItem item) async {
    final notifier = context.read<SatgasNotifier>();
    final result = await notifier.mulaiSesi(item.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.success
                  ? Icons.videocam_rounded
                  : Icons.error_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(result.message)),
          ],
        ),
        backgroundColor:
            result.success ? Colors.blue.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _onBeriCatatan(BuildContext context, KasusItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _BottomSheetCatatanPsikolog(
        onSimpan: (catatan) async {
          final notifier = context.read<SatgasNotifier>();
          final result = await notifier.selesaikanSesi(item.id, catatan);

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    result.success
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: result.success
                  ? Colors.teal.shade600
                  : Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  BOTTOM SHEET CATATAN PSIKOLOG
// ─────────────────────────────────────────────────────

class _BottomSheetCatatanPsikolog extends StatefulWidget {
  final Function(String) onSimpan;

  const _BottomSheetCatatanPsikolog({required this.onSimpan});

  @override
  State<_BottomSheetCatatanPsikolog> createState() =>
      _BottomSheetCatatanPsikologState();
}

class _BottomSheetCatatanPsikologState
    extends State<_BottomSheetCatatanPsikolog> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.medical_services_rounded,
                    color: Colors.teal.shade600),
              ),
              const SizedBox(width: 12),
              const Text(
                'Catatan Rekam Sesi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Kesimpulan awal (P3K Psikologis):',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tuliskan observasi singkat, mood, atau saran...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.teal.shade600),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () {
                if (_ctrl.text.trim().isEmpty) return;
                Navigator.pop(context);
                widget.onSimpan(_ctrl.text);
              },
              child: const Text('Simpan & Tutup Sesi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
