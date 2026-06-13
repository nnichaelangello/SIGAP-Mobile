import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/core/services/api_service.dart';

/// Halaman Edit Profil
/// Untuk mengedit informasi pribadi user
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Controllers untuk form fields
  late final TextEditingController _namaController;
  late final TextEditingController _nimController;
  late final TextEditingController _usernameController;

  late String _selectedRole;
  String _selectedJurusan = 'ti';

  final List<Map<String, String>> _roleOptions = [
    {'value': 'mahasiswa', 'label': 'Mahasiswa'},
    {'value': 'staf', 'label': 'Staf'},
    {'value': 'dosen', 'label': 'Dosen'},
    {'value': 'lainnya', 'label': 'Lainnya'},
  ];

  final List<Map<String, String>> _jurusanOptions = [
    // Fakultas Informatika (FIF)
    {'value': 'informatika', 'label': 'S1 Informatika'},
    {'value': 'rpl', 'label': 'S1 Rekayasa Perangkat Lunak'},
    // Fakultas Teknologi Informasi dan Bisnis (FTIB)
    {'value': 'si', 'label': 'S1 Sistem Informasi'},
    {'value': 'teknik_industri', 'label': 'S1 Teknik Industri'},
    {'value': 'bisnis_digital', 'label': 'S1 Bisnis Digital'},
    // Fakultas Teknik Elektro (FTE)
    {'value': 'te', 'label': 'S1 Teknik Elektro'},
    {'value': 'telekomunikasi', 'label': 'S1 Teknik Telekomunikasi'},
    // Fakultas Ilmu Terapan (FIT)
    {'value': 'digital_connectivity', 'label': 'S1 Digital Connectivity'},
    {'value': 'ti', 'label': 'S1 Teknologi Informasi'},
  ];

  @override
  void initState() {
    super.initState();
    final user = ApiService.instance.currentUser;
    _namaController = TextEditingController(text: ApiService.instance.userName);
    _nimController = TextEditingController(text: user?['identity_number'] ?? '');
    _usernameController = TextEditingController(text: user?['username'] ?? '');
    
    final role = ApiService.instance.userRole;
    _selectedRole = _roleOptions.any((opt) => opt['value'] == role) ? role : 'mahasiswa';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Main Content (Scrollable)
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              children: [
                // Avatar Section
                _buildAvatarSection(),
                const SizedBox(height: 32),

                // Form Fields
                _buildTextField(
                  label: 'Nama Lengkap',
                  controller: _namaController,
                  placeholder: 'Masukkan nama lengkap',
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  label: 'NIM / NIP',
                  controller: _nimController,
                  placeholder: 'Masukkan NIM atau NIP',
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  label: 'Username',
                  controller: _usernameController,
                  placeholder: 'username',
                  prefixText: '@',
                ),
                const SizedBox(height: 20),

                _buildDropdownField(
                  label: 'Role',
                  value: _selectedRole,
                  options: _roleOptions,
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
                const SizedBox(height: 20),

                _buildDropdownField(
                  label: 'Jurusan',
                  value: _selectedJurusan,
                  options: _jurusanOptions,
                  onChanged: (value) =>
                      setState(() => _selectedJurusan = value!),
                ),
              ],
            ),
          ),

          // Bottom CTA
          _buildBottomCTA(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: Colors.grey.shade800,
      ),
      title: Text(
        'Edit Profil',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade900,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          // Avatar
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Icon(
                Icons.person_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          // Edit Button
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade900,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixText: prefixText,
              prefixStyle: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
              contentPadding: EdgeInsets.only(
                left: prefixText != null ? 8 : 16,
                right: 16,
                top: 16,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<Map<String, String>> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              icon:
                  Icon(Icons.expand_more_rounded, color: Colors.grey.shade500),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade900),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(option['label']!),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCTA() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: AppConstants.primaryColor.withValues(alpha: 0.4),
              ),
              child: const Text(
                'Simpan Perubahan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveChanges() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Close loading indicator
    Navigator.pop(context);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Perubahan berhasil disimpan'),
        backgroundColor: AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }
}
