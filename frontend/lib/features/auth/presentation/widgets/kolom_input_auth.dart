import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Widget input field reusable untuk seluruh halaman auth.
///
/// Jika [adalahSandi] = true, widget mengelola toggle show/hide
/// secara internal — parent tidak perlu mengatur state visibility.
/// Jika [ikonAwalan] tidak diisi pada mode sandi, otomatis pakai
/// ikon gembok.
class KolomInputAuth extends StatefulWidget {
  final TextEditingController kontroler;
  final String label;
  final String? petunjuk;
  final IconData? ikonAwalan;
  final bool adalahSandi;
  final TextInputType tipeInput;
  final TextInputAction aksiInput;
  final Iterable<String>? petunjukIsiOtomatis;
  final String? Function(String?)? validasi;

  const KolomInputAuth({
    super.key,
    required this.kontroler,
    required this.label,
    this.petunjuk,
    this.ikonAwalan,
    this.adalahSandi = false,
    this.tipeInput = TextInputType.text,
    this.aksiInput = TextInputAction.next,
    this.petunjukIsiOtomatis,
    this.validasi,
  });

  @override
  State<KolomInputAuth> createState() => _KolomInputAuthState();
}

class _KolomInputAuthState extends State<KolomInputAuth> {
  bool _tersembunyi = true;

  /// Fallback ikon: jika sandi tanpa ikon eksplisit → pakai gembok.
  IconData? get _ikonPrefix =>
      widget.ikonAwalan ??
      (widget.adalahSandi ? Icons.lock_outline_rounded : null);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.kontroler,
      obscureText: widget.adalahSandi && _tersembunyi,
      keyboardType:
          widget.adalahSandi ? TextInputType.visiblePassword : widget.tipeInput,
      textInputAction: widget.aksiInput,
      autofillHints: widget.petunjukIsiOtomatis,
      validator: widget.validasi,
      style: GoogleFonts.poppins(fontSize: 14, color: AppConstants.textDark),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.petunjuk,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppConstants.textSecondary,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: AppConstants.textSecondary.withValues(alpha: 0.5),
        ),
        prefixIcon: _ikonPrefix != null
            ? Icon(_ikonPrefix,
                size: 20,
                color: AppConstants.textSecondary.withValues(alpha: 0.6))
            : null,
        suffixIcon: widget.adalahSandi ? _bangunToggleSandi() : null,
        filled: true,
        fillColor: AppConstants.backgroundColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _bingkai(Colors.grey.shade200),
        enabledBorder: _bingkai(Colors.grey.shade200),
        focusedBorder: _bingkai(AppConstants.primaryColor, lebar: 1.5),
        errorBorder: _bingkai(AppConstants.errorColor),
        focusedErrorBorder: _bingkai(AppConstants.errorColor, lebar: 1.5),
      ),
    );
  }

  Widget _bangunToggleSandi() {
    return IconButton(
      icon: Icon(
        _tersembunyi ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        color: AppConstants.textSecondary.withValues(alpha: 0.45),
        size: 20,
      ),
      onPressed: () => setState(() => _tersembunyi = !_tersembunyi),
    );
  }

  OutlineInputBorder _bingkai(Color warna, {double lebar = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: warna, width: lebar),
    );
  }
}
