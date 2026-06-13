import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/core/services/api_service.dart';

/// Halaman Key Management
/// Untuk mengelola kunci enkripsi laporan (hanya untuk user yang sudah login)
class KeyManagementPage extends StatefulWidget {
  final bool isLoggedIn;

  const KeyManagementPage({super.key, this.isLoggedIn = false});

  @override
  State<KeyManagementPage> createState() => _KeyManagementPageState();
}

class _KeyManagementPageState extends State<KeyManagementPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  bool _showLoginPrompt = false;
  bool _isLoading = true;

  // Daftar kunci enkripsi yang tersimpan (tracking code laporan)
  List<Map<String, dynamic>> _keys = [];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    if (!widget.isLoggedIn) {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerShake());
    } else {
      _fetchKeys();
    }
  }

  Future<void> _fetchKeys() async {
    try {
      final resp = await ApiService.instance.get('/api/reports');
      if (resp.success && resp.data != null) {
        final items = resp.data!['data'] as List? ?? [];
        final List<Map<String, dynamic>> loadedKeys = [];
        for (var item in items) {
          loadedKeys.add({
            'id': item['tracking_code'],
            'time': item['created_at'] != null 
                ? _formatTime(item['created_at'].toString()) 
                : 'Baru saja',
          });
        }
        if (mounted) {
          setState(() {
            _keys = loadedKeys;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Baru saja';
    }
  }

  void _triggerShake() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _showLoginPrompt = true);
    _shakeController.forward().then((_) => _shakeController.reverse());
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String id) {
    Clipboard.setData(ClipboardData(text: id));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ID "$id" berhasil disalin'),
        backgroundColor: AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: widget.isLoggedIn
          ? _buildKeyManagementView()
          : _buildLoginPromptView(),
    );
  }

  Widget _buildLoginPromptView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon Kunci
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Icon(Icons.vpn_key_off_rounded,
                  size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),

            Text(
              'Akses Terbatas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda harus login terlebih dahulu\nuntuk mengakses manajemen kunci',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade500, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Tombol Login dengan Efek Getar
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final shake = Tween(begin: 0.0, end: 1.0)
                    .chain(CurveTween(curve: Curves.elasticIn))
                    .evaluate(_shakeController);
                return Transform.translate(
                  offset: Offset(10 * shake * (shake > 0.5 ? -1 : 1), 0),
                  child: child,
                );
              },
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Masuk atau Daftar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

            // Notifikasi Merah
            if (_showLoginPrompt) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Text(
                      'Silakan login terlebih dahulu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeyManagementView() {
    return Column(
      children: [
        // Header Section
        _buildHeader(),

        // Keys List
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _keys.isEmpty 
              ? const Center(child: Text('Belum ada laporan.'))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: _keys.length,
            itemBuilder: (context, index) => _KeyCard(
              keyData: _keys[index],
              onCopy: () => _copyToClipboard(_keys[index]['id']),
              onRevoke: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Batalkan Kunci'),
                    content: const Text(
                        'Apakah Anda yakin ingin membatalkan kunci ini? Tindakan ini tidak dapat dibatalkan.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _keys.removeAt(index);
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kunci berhasil dibatalkan'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        child: const Text(
                          'Hapus',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Footer
        _buildFooter(),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 6,
                offset: const Offset(3, 3),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 6,
                offset: Offset(-3, -3),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: Colors.grey.shade700,
          ),
        ),
      ),
      title: Text(
        'MANAJEMEN KUNCI',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          // Icon Container
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(4, 4),
                ),
                const BoxShadow(
                  color: Colors.white,
                  blurRadius: 8,
                  offset: Offset(-4, -4),
                ),
              ],
            ),
            child: Icon(
              Icons.lock_person_rounded,
              size: 28,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'BRANKAS TERENKRIPSI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Kelola kunci enkripsi laporan\nAnda dengan aman.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'SIGAP SECURE MODULE v3.0',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade300,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyCard extends StatelessWidget {
  final Map<String, dynamic> keyData;
  final VoidCallback onCopy;
  final VoidCallback onRevoke;

  const _KeyCard({
    required this.keyData,
    required this.onCopy,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Key ID Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor.withValues(alpha: 0.08),
                  AppConstants.primaryColor.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Key Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.vpn_key_rounded,
                    size: 18,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: 14),

                // Key ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        keyData['id'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: Colors.grey.shade800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        keyData['time'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons - Minimalis & Premium
          Row(
            children: [
              // Delete Button
              Expanded(
                child: _buildActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Hapus',
                  color: Colors.red.shade400,
                  bgColor: Colors.red.shade50,
                  onTap: onRevoke,
                ),
              ),
              const SizedBox(width: 12),
              // Copy Button
              Expanded(
                child: _buildActionButton(
                  icon: Icons.copy_rounded,
                  label: 'Salin ID',
                  color: AppConstants.primaryColor,
                  bgColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                  onTap: onCopy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
