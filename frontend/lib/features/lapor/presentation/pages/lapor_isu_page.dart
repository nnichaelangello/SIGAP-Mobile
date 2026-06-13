import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/lapor/presentation/provider/lapor_isu_provider.dart';

// Import step widgets (to be created)
import 'widgets/steps/step1_penyintas.dart';
import 'widgets/steps/step2_kekhawatiran.dart';
import 'widgets/steps/step3_gender.dart';
import 'widgets/steps/step4_pelaku.dart';
import 'widgets/steps/step5_detail.dart';
import 'widgets/steps/step6_data_final.dart';

class LaporIsuPage extends StatelessWidget {
  const LaporIsuPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Karena LaporIsuProvider butuh SubmitReportUseCase yg butuh Repo,
    // idealnya di-inject via get_it atau MultiProvider di main.dart.
    // Untuk kesederhanaan context ini, asumsikan provider sudah disuntikkan dari luar Route
    // atau kita bungkus langsung disini jika belum ada DI global.

    return const _LaporIsuView();
  }
}

class _LaporIsuView extends StatelessWidget {
  const _LaporIsuView();

  @override
  Widget build(BuildContext context) {
    return Consumer<LaporIsuProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          appBar: AppBar(
            title: const Text(
              "Formulir Lapor Isu",
              style: TextStyle(
                color: AppConstants.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: AppConstants.textDark),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (provider.currentStep > 0) {
                  provider.previousStep();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Column(
                children: [
                  Container(color: Colors.grey.shade200, height: 1),
                  _buildProgressBar(context, provider),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              // Error Message Banner
              if (provider.errorMessage != null)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade50,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Main Form Pager
              Expanded(
                child: PageView(
                  controller: provider.pageController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable swipe
                  children: const [
                    Step1Penyintas(),
                    Step2Kekhawatiran(),
                    Step3Gender(),
                    Step4Pelaku(),
                    Step5Detail(),
                    Step6DataFinal(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(BuildContext context, LaporIsuProvider provider) {
    final stepProgress = (provider.currentStep + 1) / provider.totalSteps;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Langkah ${provider.currentStep + 1} dari ${provider.totalSteps}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stepProgress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppConstants.primaryColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
