import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/lapor/presentation/provider/lapor_isu_provider.dart';

class Step6DataFinal extends StatefulWidget {
  const Step6DataFinal({super.key});

  @override
  State<Step6DataFinal> createState() => _Step6DataFinalState();
}

class _Step6DataFinalState extends State<Step6DataFinal> {
  final _emailController = TextEditingController();
  final _waController = TextEditingController();

  final List<String> _usiaList = [
    "12-17 tahun",
    "18-25 tahun",
    "26-35 tahun",
    "36-45 tahun",
    "46-55 tahun",
    "56 tahun ke atas"
  ];

  final List<String> _disabilitasTypes = [
    "Kesulitan melihat",
    "Kesulitan mendengar",
    "Kesulitan berkomunikasi",
    "Kesulitan mengingat",
    "Kesulitan perawatan diri",
    "Kesulitan berjalan"
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<LaporIsuProvider>();
    _emailController.text = provider.emailPenyintas ?? '';
    _waController.text = provider.whatsappPenyintas ?? '';

    _emailController.addListener(() {
      context.read<LaporIsuProvider>().setEmailPenyintas(_emailController.text);
    });
    _waController.addListener(() {
      context.read<LaporIsuProvider>().setWhatsappPenyintas(_waController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _waController.dispose();
    super.dispose();
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
                "Input Data Penyintas",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Data penyintas diperlukan untuk proses pelaporan",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // 1. Email
              _buildLabel("Email Anda"),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration("contoh@email.com",
                    icon: Icons.email),
              ),
              const SizedBox(height: 24),

              // 2. Usia
              _buildLabel("Usia Penyintas", isRequired: true),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: provider.usiaPenyintas,
                decoration: _buildInputDecoration("Pilih usia penyintas"),
                items: _usiaList.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) => provider.setUsiaPenyintas(val!),
              ),
              const SizedBox(height: 24),

              // 3. Status Disabilitas
              _buildLabel("Apakah Penyintas Memiliki Disabilitas?"),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text("Ya", style: TextStyle(fontSize: 14)),
                      value: true,
                      // ignore: deprecated_member_use
                      groupValue: provider.isDisabilitas,
                      activeColor: AppConstants.primaryColor,
                      contentPadding: EdgeInsets.zero,
                      // ignore: deprecated_member_use
                      onChanged: (val) => provider.setIsDisabilitas(val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title:
                          const Text("Tidak", style: TextStyle(fontSize: 14)),
                      value: false,
                      // ignore: deprecated_member_use
                      groupValue: provider.isDisabilitas,
                      activeColor: AppConstants.primaryColor,
                      contentPadding: EdgeInsets.zero,
                      // ignore: deprecated_member_use
                      onChanged: (val) => provider.setIsDisabilitas(val!),
                    ),
                  ),
                ],
              ),

              // 4. Jenis Disabilitas (Conditional)
              if (provider.isDisabilitas) ...[
                const SizedBox(height: 16),
                _buildLabel("Jenis Disabilitas Penyintas", isRequired: true),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: provider.jenisDisabilitas,
                  decoration: _buildInputDecoration("Pilih jenis disabilitas"),
                  items: _disabilitasTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) => provider.setJenisDisabilitas(val!),
                ),
              ],
              const SizedBox(height: 24),

              // 5. WhatsApp
              _buildLabel("Nomor WhatsApp"),
              TextFormField(
                controller: _waController,
                keyboardType: TextInputType.phone,
                decoration:
                    _buildInputDecoration("08xxxxxxxxxx", icon: Icons.phone),
              ),

              const SizedBox(height: 32),

              // 6. Anonim Checkbox
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: CheckboxListTile(
                  title: const Text(
                    "Sembunyikan Identitas (Anonim)",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    "Pihak kampus tidak akan melihat nama Anda",
                    style: TextStyle(fontSize: 12),
                  ),
                  activeColor: AppConstants.primaryColor,
                  value: provider.isAnonymous,
                  onChanged: (val) => provider.setIsAnonymous(val ?? false),
                ),
              ),

              const SizedBox(height: 48),

              // Final Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          // Tutup keyboard bawaan jika masih nongol
                          FocusScope.of(context).unfocus();

                          final success = await provider.submitReport(
                              reporterId: "");

                          if (success && context.mounted) {
                            final code = provider.submittedReport?.trackingCode ?? 'UNKNOWN';
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.white,
                                surfaceTintColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                                    SizedBox(width: 8),
                                    Text('Berhasil', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Laporan Anda telah berhasil dicatat oleh sistem.'),
                                    const SizedBox(height: 16),
                                    const Text('Kode Pelacakan Anda:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            code,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy_rounded, size: 20, color: AppConstants.primaryColor),
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: code));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Kode berhasil disalin!')),
                                              );
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Harap simpan kode ini dengan aman. Anda dapat menggunakannya di menu Pantau untuk melihat status laporan.',
                                      style: TextStyle(fontSize: 12, color: Colors.red),
                                    ),
                                  ],
                                ),
                                actions: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppConstants.primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context); // Tutup dialog
                                      Navigator.pop(context); // Kembali ke Home
                                    },
                                    child: const Text('Tutup & Selesai'),
                                  )
                                ],
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text(
                          "Kirim Pengaduan",
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
          Text(text,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          if (isRequired)
            const Text(" *",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade500) : null,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
