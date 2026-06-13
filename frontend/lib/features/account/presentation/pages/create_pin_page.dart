import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Halaman Buat / Ganti PIN
/// Untuk membuat PIN baru atau mengganti PIN lama
class CreatePinPage extends StatefulWidget {
  const CreatePinPage({super.key});

  @override
  State<CreatePinPage> createState() => _CreatePinPageState();
}

class _CreatePinPageState extends State<CreatePinPage>
    with SingleTickerProviderStateMixin {
  // PIN input state
  final List<String> _pin = [];
  final List<String> _confirmPin = [];
  final int _pinLength = 6;

  // Current step: 'enter' atau 'confirm'
  String _currentStep = 'enter';

  // Animation controller untuk shake effect on error
  late AnimationController _shakeController;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberTap(String number) {
    HapticFeedback.lightImpact();

    if (_currentStep == 'enter') {
      if (_pin.length < _pinLength) {
        setState(() {
          _pin.add(number);
          _isError = false;
        });

        // Auto move to confirm step
        if (_pin.length == _pinLength) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              setState(() => _currentStep = 'confirm');
            }
          });
        }
      }
    } else {
      if (_confirmPin.length < _pinLength) {
        setState(() {
          _confirmPin.add(number);
          _isError = false;
        });

        // Auto verify
        if (_confirmPin.length == _pinLength) {
          _verifyPin();
        }
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();

    if (_currentStep == 'enter') {
      if (_pin.isNotEmpty) {
        setState(() {
          _pin.removeLast();
          _isError = false;
        });
      }
    } else {
      if (_confirmPin.isNotEmpty) {
        setState(() {
          _confirmPin.removeLast();
          _isError = false;
        });
      }
    }
  }

  void _verifyPin() {
    if (_pin.join() == _confirmPin.join()) {
      // PIN matched - success!
      HapticFeedback.heavyImpact();
      _showSuccessDialog();
    } else {
      // PIN tidak cocok
      HapticFeedback.vibrate();
      setState(() {
        _isError = true;
        _confirmPin.clear();
      });
      _shakeController.forward().then((_) => _shakeController.reset());
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon with glow
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.successColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.successColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppConstants.successColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'PIN Berhasil Dibuat!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PIN Anda telah berhasil disimpan.\nGunakan PIN ini untuk mengamankan aplikasi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to PIN Management
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Selesai',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goBackToEnter() {
    setState(() {
      _currentStep = 'enter';
      _confirmPin.clear();
      _isError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),
            // Main Content - use Expanded + LayoutBuilder for responsive
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate responsive sizes
                  final isSmallScreen = constraints.maxHeight < 500;

                  return Column(
                    children: [
                      // Top section with icon, text, and dots
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: isSmallScreen ? 16 : 32),
                                // Lock icon with glow
                                _buildLockIcon(isSmallScreen),
                                SizedBox(height: isSmallScreen ? 24 : 32),
                                // Instruction text
                                _buildInstructionText(),
                                SizedBox(height: isSmallScreen ? 24 : 32),
                                // PIN Dots
                                _buildPinDots(),
                                // Error message
                                if (_isError) _buildErrorMessage(),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Numpad (flat design) - fixed at bottom
                      _buildNumpad(isSmallScreen),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back button (left)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                if (_currentStep == 'confirm') {
                  _goBackToEnter();
                } else {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.arrow_back_rounded),
              iconSize: 24,
              color: Colors.grey.shade800,
            ),
          ),
          // Title (center)
          Text(
            _currentStep == 'enter' ? 'BUAT PIN BARU' : 'KONFIRMASI PIN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockIcon(bool isSmall) {
    final double iconContainerSize = isSmall ? 72 : 88;
    final double iconSize = isSmall ? 28 : 32;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        Container(
          width: iconContainerSize + 20,
          height: iconContainerSize + 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        // Icon container
        Container(
          width: iconContainerSize,
          height: iconContainerSize,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade100, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            _currentStep == 'enter'
                ? Icons.lock_rounded
                : Icons.lock_open_rounded,
            size: iconSize,
            color: AppConstants.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionText() {
    return Text(
      _currentStep == 'enter'
          ? 'Masukkan 6 digit angka untuk\nPIN keamanan Anda'
          : 'Masukkan ulang PIN untuk\nmemastikan kecocokan',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade500,
        height: 1.5,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildPinDots() {
    final currentPin = _currentStep == 'enter' ? _pin : _confirmPin;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shake = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticIn))
            .evaluate(_shakeController);
        return Transform.translate(
          offset: Offset(12 * shake * (shake > 0.5 ? -1 : 1), 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pinLength, (index) {
          final isFilled = index < currentPin.length;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isError
                  ? AppConstants.errorColor.withValues(alpha: 0.8)
                  : isFilled
                      ? AppConstants.primaryColor
                      : Colors.transparent,
              border: Border.all(
                color: _isError
                    ? AppConstants.errorColor
                    : isFilled
                        ? AppConstants.primaryColor
                        : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: isFilled && !_isError
                  ? [
                      BoxShadow(
                        color: AppConstants.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        'PIN tidak cocok. Silakan coba lagi.',
        style: TextStyle(
          fontSize: 12,
          color: Colors.red.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNumpad(bool isSmall) {
    final double buttonSize = isSmall ? 56 : 64;
    final double fontSize = isSmall ? 26 : 30;
    final double verticalSpacing = isSmall ? 12 : 16;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 8, 24, isSmall ? 16 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: 1, 2, 3
          _buildNumpadRow(['1', '2', '3'], buttonSize, fontSize),
          SizedBox(height: verticalSpacing),
          // Row 2: 4, 5, 6
          _buildNumpadRow(['4', '5', '6'], buttonSize, fontSize),
          SizedBox(height: verticalSpacing),
          // Row 3: 7, 8, 9
          _buildNumpadRow(['7', '8', '9'], buttonSize, fontSize),
          SizedBox(height: verticalSpacing),
          // Row 4: empty, 0, backspace
          _buildLastRow(buttonSize, fontSize),
        ],
      ),
    );
  }

  Widget _buildNumpadRow(List<String> numbers, double size, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers
          .map((number) => _buildFlatNumpadButton(number, size, fontSize))
          .toList(),
    );
  }

  Widget _buildLastRow(double size, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Empty space
        SizedBox(width: size, height: size),
        // 0 button
        _buildFlatNumpadButton('0', size, fontSize),
        // Backspace button
        _buildBackspaceButton(size),
      ],
    );
  }

  /// Flat numpad button - no circle/border wrapper, just text
  Widget _buildFlatNumpadButton(String number, double size, double fontSize) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumberTap(number),
        borderRadius: BorderRadius.circular(size / 2),
        splashColor: AppConstants.primaryColor.withValues(alpha: 0.1),
        highlightColor: AppConstants.primaryColor.withValues(alpha: 0.05),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(double size) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onBackspace,
        borderRadius: BorderRadius.circular(size / 2),
        splashColor: Colors.grey.withValues(alpha: 0.1),
        highlightColor: Colors.grey.withValues(alpha: 0.05),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: size * 0.35,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}
