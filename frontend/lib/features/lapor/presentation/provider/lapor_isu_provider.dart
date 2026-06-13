import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/result/data_result.dart';
import 'package:sigap_mobile/features/lapor/domain/entities/report_entity.dart';
import 'package:sigap_mobile/features/lapor/domain/usecases/submit_report_usecase.dart';

class LaporIsuProvider extends ChangeNotifier {
  final SubmitReportUseCase submitUseCase;
  final PageController pageController = PageController();

  LaporIsuProvider({required this.submitUseCase});

  // --- UI State ---
  int _currentStep = 0;
  int get currentStep => _currentStep;
  final int totalSteps = 6;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ReportEntity? _submittedReport;
  ReportEntity? get submittedReport => _submittedReport;

  // --- Form Data State ---
  // Step 1: Siapa Penyintasnya
  String? _penyintas;
  String? get penyintas => _penyintas;

  // Step 2: Tingkat Kekhawatiran
  String? _tingkatKekhawatiran;
  String? get tingkatKekhawatiran => _tingkatKekhawatiran;

  // Step 3: Gender Penyintas
  String? _genderPenyintas;
  String? get genderPenyintas => _genderPenyintas;

  // Step 4: Siapa Pelakunya
  String? _pelakuKekerasan;
  String? get pelakuKekerasan => _pelakuKekerasan;

  // Step 5: Detail Kejadian
  DateTime? _waktuKejadian;
  DateTime? get waktuKejadian => _waktuKejadian;

  String? _lokasiKategori;
  String? get lokasiKategori => _lokasiKategori;

  String? _lokasiDetail;
  String? get lokasiDetail => _lokasiDetail;

  String _detailKejadian = "";
  String get detailKejadian => _detailKejadian;

  // Step 6: Data Penyintas (Final)
  String? _emailPenyintas;
  String? get emailPenyintas => _emailPenyintas;

  String? _usiaPenyintas;
  String? get usiaPenyintas => _usiaPenyintas;

  bool _isDisabilitas = false;
  bool get isDisabilitas => _isDisabilitas;

  String? _jenisDisabilitas;
  String? get jenisDisabilitas => _jenisDisabilitas;

  String? _whatsappPenyintas;
  String? get whatsappPenyintas => _whatsappPenyintas;

  bool _isAnonymous = false;
  bool get isAnonymous => _isAnonymous;

  // --- Setters / Actions ---

  void setPenyintas(String val) {
    _penyintas = val;
    notifyListeners();
  }

  void setTingkatKekhawatiran(String val) {
    _tingkatKekhawatiran = val;
    notifyListeners();
  }

  void setGenderPenyintas(String val) {
    _genderPenyintas = val;
    notifyListeners();
  }

  void setPelakuKekerasan(String val) {
    _pelakuKekerasan = val;
    notifyListeners();
  }

  void setWaktuKejadian(DateTime date) {
    _waktuKejadian = date;
    notifyListeners();
  }

  void setLokasiKategori(String val) {
    _lokasiKategori = val;
    notifyListeners();
  }

  void setLokasiDetail(String val) {
    _lokasiDetail = val;
    notifyListeners();
  }

  void setDetailKejadian(String val) {
    _detailKejadian = val;
    notifyListeners();
  }

  void setEmailPenyintas(String val) {
    _emailPenyintas = val;
    notifyListeners();
  }

  void setUsiaPenyintas(String val) {
    _usiaPenyintas = val;
    notifyListeners();
  }

  void setIsDisabilitas(bool val) {
    _isDisabilitas = val;
    if (!val) {
      _jenisDisabilitas = null; // Reset jika tidak disabilitas
    }
    notifyListeners();
  }

  void setJenisDisabilitas(String val) {
    _jenisDisabilitas = val;
    notifyListeners();
  }

  void setWhatsappPenyintas(String val) {
    _whatsappPenyintas = val;
    notifyListeners();
  }

  void setIsAnonymous(bool val) {
    _isAnonymous = val;
    notifyListeners();
  }

  // --- Navigation Logic ---

  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      if (_validateCurrentStep()) {
        _currentStep++;
        pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _errorMessage = null; // Clear previous errors on move
        notifyListeners();
      } else {
        notifyListeners(); // Show the validation error message
      }
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _errorMessage = null;
      notifyListeners();
    }
  }

  void jumpToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }

  // Validasi lokal per langkah sebelum boleh lanjut layar
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Penyintas
        if (_penyintas == null) {
          _errorMessage = "Silakan pilih siapa penyintasnya.";
          return false;
        }
        break;
      case 1: // Kekhawatiran
        if (_tingkatKekhawatiran == null) {
          _errorMessage = "Silakan pilih tingkat kekhawatiran.";
          return false;
        }
        break;
      case 2: // Gender
        if (_genderPenyintas == null) {
          _errorMessage = "Silakan pilih gender penyintas.";
          return false;
        }
        break;
      case 3: // Pelaku
        if (_pelakuKekerasan == null) {
          _errorMessage = "Silakan pilih pelaku kekerasan.";
          return false;
        }
        break;
      case 4: // Detail
        if (_waktuKejadian == null) {
          _errorMessage = "Silakan lengkapi tanggal kejadian.";
          return false;
        }
        if (_lokasiKategori == null) {
          _errorMessage = "Silakan pilih kategori lokasi.";
          return false;
        }
        if (_detailKejadian.trim().length < 10) {
          _errorMessage = "Detail kejadian minimal 10 karakter.";
          return false;
        }
        break;
      case 5: // Final Step (Validation handled on submit button)
        break;
    }
    return true;
  }

  // --- Submission Logic ---

  Future<bool> submitReport({required String reporterId}) async {
    // Validasi final Step 6
    if (_usiaPenyintas == null) {
      _errorMessage = "Usia penyintas wajib dipilih.";
      notifyListeners();
      return false;
    }
    if (_isDisabilitas && _jenisDisabilitas == null) {
      _errorMessage = "Jenis disabilitas wajib dipilih.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Karena Step 1-5 dijamin lewat validasi, kita bisa force (!) tanpa kuatir null
    final result = await submitUseCase.execute(
      penyintas: _penyintas!,
      tingkatKekhawatiran: _tingkatKekhawatiran!,
      genderPenyintas: _genderPenyintas!,
      pelakuKekerasan: _pelakuKekerasan!,
      waktuKejadian: _waktuKejadian!,
      lokasiKategori: _lokasiKategori!,
      lokasiDetail: _lokasiDetail,
      detailKejadian: _detailKejadian,
      emailPenyintas: _emailPenyintas,
      usiaPenyintas: _usiaPenyintas!,
      isDisabilitas: _isDisabilitas,
      jenisDisabilitas: _jenisDisabilitas,
      whatsappPenyintas: _whatsappPenyintas,
      isAnonymous: _isAnonymous,
      reporterId:
          reporterId, // biasanya ditarik dari Auth provider user yg login
    );

    _isLoading = false;

    if (result is Success<ReportEntity>) {
      _submittedReport = result.data;
      notifyListeners();
      return true;
    } else if (result is Error<ReportEntity>) {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }

    return false;
  }
}
