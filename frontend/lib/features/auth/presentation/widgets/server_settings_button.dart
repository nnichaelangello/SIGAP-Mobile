import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/core/services/api_service.dart';

/// Widget kecil di halaman login untuk mengatur IP server.
/// Muncul sebagai ikon settings di pojok kanan atas.
class ServerSettingsButton extends StatelessWidget {
  const ServerSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_ethernet_rounded, color: AppConstants.textSecondary),
      tooltip: 'Pengaturan Server',
      onPressed: () => _showServerDialog(context),
    );
  }

  void _showServerDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiService.instance.baseUrl);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.dns_rounded, color: AppConstants.primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Server', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan alamat IP server (laptop):',
              style: GoogleFonts.poppins(fontSize: 13, color: AppConstants.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'http://192.168.x.x:8080',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                prefixIcon: const Icon(Icons.link_rounded, color: AppConstants.primaryColor),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            Text(
              'Jalankan ipconfig di CMD laptop untuk\nmelihat IP Address Wi-Fi Anda.',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                await ApiService.saveBaseUrl(url);

                if (!ctx.mounted) return;
                Navigator.pop(ctx);

                // Test koneksi
                final online = await ApiService.instance.isServerOnline();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          online ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            online
                                ? 'Server terhubung! ✅'
                                : 'Server tidak dapat dihubungi. Periksa IP dan pastikan server menyala.',
                            style: GoogleFonts.poppins(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: online ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ));
              }
            },
            child: Text('Simpan & Tes', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
