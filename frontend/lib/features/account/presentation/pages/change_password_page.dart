import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/core/services/api_service.dart';

/// Halaman Ubah Password
/// Menggunakan konsep DeepUI Clean & Premium dengan alur keamanan bertingkat (DeepCode).
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with SingleTickerProviderStateMixin {
  // Page Controller untuk navigasi antar langkah
  final PageController _pageController = PageController();

  // --- STATE: VERIFICATION PHASE ---
  String _verifyMode = 'password'; // 'password' or 'otp'
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isOldPasswordObscured = true;
  bool _isLoadingVerify = false;

  // OTP Timer State
  Timer? _timer;
  int _start = 60;
  bool _isTimerActive = false;

  // --- STATE: NEW PASSWORD PHASE ---
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.grey;

  // Validation Flags
  bool _hasMinLength = false; // Min 8
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void dispose() {
    _pageController.dispose();
    _oldPasswordController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // --- LOGIC: VERIFICATION ---

  void _verifyOldPassword() async {
    if (_oldPasswordController.text.isEmpty) {
      _showSnackbar('Masukkan password lama Anda', isError: true);
      return;
    }
    // Lanjut ke step 2 untuk memasukkan password baru. 
    // Validasi kebenaran password lama akan dilakukan bersamaan saat submit akhir di server.
    _nextStep();
  }

  void _sendOtp() {
    setState(() {
      _verifyMode = 'otp';
      _isTimerActive = true;
      _start = 60;
    });
    _startTimer();
    _showSnackbar('Kode OTP dikirim ke email Anda', isError: false);
  }

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            _isTimerActive = false;
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  void _verifyOtp() async {
    if (_otpController.text.length < 4) {
      _showSnackbar('Masukkan 4 digit kode OTP', isError: true);
      return;
    }
    setState(() => _isLoadingVerify = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate Check
    setState(() => _isLoadingVerify = false);
    _nextStep();
  }

  // --- LOGIC: NEW PASSWORD ---

  void _updatePasswordStrength(String value) {
    setState(() {
      // Check Requirments
      _hasMinLength = value.length >= 8;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasLowercase = value.contains(RegExp(r'[a-z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      // Calculate Score
      int score = 0;
      if (_hasMinLength) score++;
      if (_hasUppercase) score++;
      if (_hasLowercase) score++;
      if (_hasNumber) score++;
      if (_hasSpecialChar) score++;

      // UI Update
      if (score <= 2) {
        _passwordStrength = 0.3;
        _passwordStrengthText = 'Lemah';
        _passwordStrengthColor = Colors.red;
      } else if (score <= 4) {
        _passwordStrength = 0.6;
        _passwordStrengthText = 'Sedang';
        _passwordStrengthColor = Colors.orange;
      } else {
        _passwordStrength = 1.0;
        _passwordStrengthText = 'Kuat';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  void _submitNewPassword() async {
    // 1. Validate Strength
    if (!(_hasMinLength &&
        _hasUppercase &&
        _hasLowercase &&
        _hasNumber &&
        _hasSpecialChar)) {
      _showSnackbar('Password belum memenuhi standar keamanan.', isError: true);
      return;
    }

    // 2. Validate Match
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackbar('Konfirmasi password tidak cocok.', isError: true);
      return;
    }

    // 3. Submit
    setState(() => _isLoadingVerify = true);
    final response = await ApiService.instance.post('/api/auth/change-password', {
      'old_password': _oldPasswordController.text,
      'new_password': _newPasswordController.text,
    });
    setState(() => _isLoadingVerify = false);

    if (response.success) {
      _showSuccessDialog();
    } else {
      _showSnackbar(response.error ?? 'Gagal mengubah password', isError: true);
      if (response.error != null && response.error!.toLowerCase().contains('lama')) {
        _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutQuart);
      }
    }
  }

  // --- NAVIGATION ---

  void _nextStep() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutQuart,
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppConstants.errorColor : AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.green, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Password Diubah',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Password Anda berhasil diperbarui. Silakan login kembali dengan password baru.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: _buildAppBar(),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: [
          _buildVerificationStep(),
          _buildNewPasswordStep(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.grey.shade800, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text(
        'UBAH PASSWORD',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade900,
          letterSpacing: 1,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade100, height: 1),
      ),
    );
  }

  // --- STEP 1: VERIFICATION ---

  Widget _buildVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Step Indicator
          _buildStepProgress(1, 2),
          const SizedBox(height: 32),

          // Illustration/Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_person_rounded,
                size: 60, color: AppConstants.primaryColor),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Verifikasi Keamanan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Demi keamanan akun Anda, mohon verifikasi\nidentitas Anda terlebih dahulu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Toggle: Password vs OTP
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleBtn('Password Lama', 'password'),
                ),
                Expanded(
                  child: _buildToggleBtn('Kode OTP', 'otp'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Main Form
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            firstChild: _buildOldPasswordForm(),
            secondChild: _buildOtpForm(),
            crossFadeState: _verifyMode == 'password'
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgress(int current, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        bool isActive = index + 1 == current;
        return Container(
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? AppConstants.primaryColor : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildToggleBtn(String label, String value) {
    bool isSelected = _verifyMode == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _verifyMode = value;
          // Reset otp flow if switching back
          if (value == 'otp' && !_isTimerActive) _sendOtp();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppConstants.textDark : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOldPasswordForm() {
    return Column(
      children: [
        TextField(
          controller: _oldPasswordController,
          obscureText: _isOldPasswordObscured,
          decoration: InputDecoration(
            labelText: 'Password Saat Ini',
            hintText: 'Masukkan password lama',
            prefixIcon: const Icon(Icons.vpn_key_rounded),
            suffixIcon: IconButton(
              icon: Icon(_isOldPasswordObscured
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded),
              onPressed: () => setState(
                  () => _isOldPasswordObscured = !_isOldPasswordObscured),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoadingVerify ? null : _verifyOldPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoadingVerify
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Lanjut',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpForm() {
    return Column(
      children: [
        // OTP Input
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
          maxLength: 4,
          decoration: InputDecoration(
            counterText: "",
            hintText: "• • • •",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tidak menerima kode? ',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            GestureDetector(
              onTap: _isTimerActive ? null : _sendOtp,
              child: Text(
                _isTimerActive ? 'Tunggu ($_start s)' : 'Kirim Ulang',
                style: TextStyle(
                  color:
                      _isTimerActive ? Colors.grey : AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoadingVerify ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoadingVerify
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Verifikasi OTP',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // --- STEP 2: NEW PASSWORD ---

  Widget _buildNewPasswordStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildStepProgress(2, 2)),
          const SizedBox(height: 32),

          const Text(
            'Buat Password Baru',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gunakan kombinasi yang kuat agar akun Anda\ntetap aman terlindungi.',
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Fields
          _buildAuthField(
            controller: _newPasswordController,
            label: 'Password Baru',
            obscured: _isNewPasswordObscured,
            toggleObscure: () => setState(
                () => _isNewPasswordObscured = !_isNewPasswordObscured),
            onChanged: _updatePasswordStrength,
          ),
          const SizedBox(height: 8),

          // Strength Bar
          if (_newPasswordController.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _passwordStrength,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _passwordStrengthText,
                  style: TextStyle(
                      color: _passwordStrengthColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          _buildAuthField(
            controller: _confirmPasswordController,
            label: 'Konfirmasi Password',
            obscured: _isConfirmPasswordObscured,
            toggleObscure: () => setState(
                () => _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
          ),

          const SizedBox(height: 24),

          // Checklist
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Syarat Keamanan:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildCheckItem("Minimal 8 Karakter", _hasMinLength),
                _buildCheckItem("Huruf Besar (A-Z) & Kecil (a-z)",
                    _hasUppercase && _hasLowercase),
                _buildCheckItem("Angka (0-9)", _hasNumber),
                _buildCheckItem("Simbol Spesial (!@#\$...)", _hasSpecialChar),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitNewPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Simpan Password Baru',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthField({
    required TextEditingController controller,
    required String label,
    required bool obscured,
    required VoidCallback toggleObscure,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscured,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(obscured
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded),
          onPressed: toggleObscure,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: isValid ? Colors.green : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? Colors.green.shade700 : Colors.grey.shade500,
              decoration: isValid ? TextDecoration.none : null,
            ),
          ),
        ],
      ),
    );
  }
}
