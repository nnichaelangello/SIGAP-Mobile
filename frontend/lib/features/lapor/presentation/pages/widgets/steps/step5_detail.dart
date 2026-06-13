import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/lapor/presentation/provider/lapor_isu_provider.dart';
import 'package:intl/intl.dart';

class Step5Detail extends StatefulWidget {
  const Step5Detail({super.key});

  @override
  State<Step5Detail> createState() => _Step5DetailState();
}

class _Step5DetailState extends State<Step5Detail> {
  final _detailController = TextEditingController();
  final _lokasiDetailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller kalau user kembali ke page ini
    final provider = context.read<LaporIsuProvider>();
    _detailController.text = provider.detailKejadian;
    _lokasiDetailController.text = provider.lokasiDetail ?? '';

    _detailController.addListener(() {
      context
          .read<LaporIsuProvider>()
          .setDetailKejadian(_detailController.text);
    });
    _lokasiDetailController.addListener(() {
      context
          .read<LaporIsuProvider>()
          .setLokasiDetail(_lokasiDetailController.text);
    });
  }

  @override
  void dispose() {
    _detailController.dispose();
    _lokasiDetailController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
      BuildContext context, LaporIsuProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.waktuKejadian ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setWaktuKejadian(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Consumer<LaporIsuProvider>(builder: (context, provider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Detail Kejadian",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Ceritakan apa yang terjadi",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // 1. Kapan Kejadiannya
              _buildLabel("Kapan kejadiannya?", isRequired: true),
              GestureDetector(
                onTap: () => _pickDate(context, provider),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        provider.waktuKejadian != null
                            ? DateFormat('dd MMMM yyyy', 'id_ID')
                                .format(provider.waktuKejadian!)
                            : "Pilih tanggal kejadian",
                        style: TextStyle(
                          color: provider.waktuKejadian != null
                              ? AppConstants.textDark
                              : Colors.grey.shade500,
                          fontSize: 15,
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 2. Kategori Lokasi
              _buildLabel("Di mana kejadiannya?", isRequired: true),
              Text(
                "Pilih lokasi umum, detail bisa ditambahkan di bawah",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _LokasiChip("Gedung Utama", Icons.business, provider),
                  _LokasiChip("Gedung SBS", Icons.school, provider),
                  _LokasiChip("Area Parkir", Icons.local_parking, provider),
                  _LokasiChip("Masjid", Icons.mosque, provider),
                  _LokasiChip("Kantin", Icons.restaurant, provider),
                  _LokasiChip("Outdoor", Icons.park, provider),
                  _LokasiChip("Luar Kampus", Icons.home, provider),
                  _LokasiChip("Tidak Ingat", Icons.question_mark, provider),
                ],
              ),

              const SizedBox(height: 16),

              // 3. Detail Lokasi
              _buildLabel("Detail Lokasi", isRequired: false),
              TextFormField(
                controller: _lokasiDetailController,
                decoration: InputDecoration(
                  hintText: 'Contoh: "Lantai 2 depan perpustakaan"',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 24),

              // 4. Detail Kejadian
              _buildLabel("Apa yang terjadi?", isRequired: true),
              Text(
                "Ceritakan secara detail minimal 10 karakter.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "Ketik di sini...",
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 48),

              // Submit Buttom
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => provider.nextStep(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Lanjutkan",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        }));
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppConstants.textDark,
            ),
          ),
          if (isRequired)
            const Text(" *",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          if (!isRequired)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "Opsional",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            )
        ],
      ),
    );
  }
}

class _LokasiChip extends StatelessWidget {
  final String label;
  final IconData iconData;
  final LaporIsuProvider provider;

  const _LokasiChip(this.label, this.iconData, this.provider);

  @override
  Widget build(BuildContext context) {
    final isSelected = provider.lokasiKategori == label;

    return GestureDetector(
      onTap: () => provider.setLokasiKategori(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? AppConstants.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData,
                size: 16,
                color: isSelected ? Colors.white : AppConstants.textDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppConstants.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
