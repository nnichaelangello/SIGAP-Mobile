import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/report_monitor/presentation/notifiers/report_monitor_notifier.dart';
import 'package:sigap_mobile/features/report_monitor/presentation/widgets/monitor_states/monitor_status_views.dart';
import 'package:sigap_mobile/features/report_monitor/presentation/widgets/monitor_states/success_state_view.dart';
import 'package:sigap_mobile/features/report_monitor/presentation/widgets/monitor_states/search_panel_view.dart';

/// Halaman Pantau Laporan — thin shell menggunakan Provider.
///
/// REFACTORED: Semua state (_state, _activeRecord, _searchRequestId)
/// dan business logic (search, accept, reschedule, download)
/// dipindahkan ke [ReportMonitorNotifier].
class ReportMonitorPage extends StatelessWidget {
  const ReportMonitorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportMonitorNotifier(),
      child: const _ReportMonitorView(),
    );
  }
}

class _ReportMonitorView extends StatefulWidget {
  const _ReportMonitorView();

  @override
  State<_ReportMonitorView> createState() => _ReportMonitorViewState();
}

class _ReportMonitorViewState extends State<_ReportMonitorView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    FocusScope.of(context).unfocus();
    context.read<ReportMonitorNotifier>().performSearch(_searchController.text);
  }

  void _onInputChanged(String value) {
    context.read<ReportMonitorNotifier>().onSearchInputChanged(value);
  }

  Future<void> _handleDownloadPdf() async {
    final notifier = context.read<ReportMonitorNotifier>();

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: AppConstants.primaryColor),
      ),
    );

    try {
      await notifier.downloadPdf();
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.download_done_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Dokumen PDF berhasil diunduh ke perangkat Anda.')),
            ],
          ),
          backgroundColor: AppConstants.successColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tutup dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh dokumen: $e'),
          backgroundColor: AppConstants.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Consumer<ReportMonitorNotifier>(
                builder: (context, notifier, _) {
                  final isLoading = notifier.state is MonitorLoading;

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              SearchPanelView(
                                controller: _searchController,
                                isLoading: isLoading,
                                onChanged: _onInputChanged,
                                onSearch: _onSearch,
                              ),
                              if (notifier.state is MonitorError) ...[
                                const SizedBox(height: 20),
                                ErrorBannerView(
                                  errorMessage:
                                      (notifier.state as MonitorError)
                                          .message,
                                ),
                              ],
                              if (notifier.hasDraftSearch(
                                  _searchController.text)) ...[
                                const SizedBox(height: 16),
                                DraftInfoBannerView(
                                  currentCode:
                                      notifier.activeRecord?.reportCode ??
                                          '',
                                ),
                              ],
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildContentArea(notifier),
                        ),
                      ),
                      const SliverToBoxAdapter(
                          child: SizedBox(height: 40)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea(ReportMonitorNotifier notifier) {
    return switch (notifier.state) {
      MonitorEmpty() => const EmptyMonitorView(),
      MonitorLoading() => const LoadingMonitorView(),
      MonitorError() => const NotFoundMonitorView(),
      MonitorSuccess(record: final record) => SuccessMonitorView(
          record: record,
          onDownloadPdf: _handleDownloadPdf,
          onRefresh: () => context.read<ReportMonitorNotifier>().refresh(),
        ),
    };
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PANTAU',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Pantau Progres Laporan Anda',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
