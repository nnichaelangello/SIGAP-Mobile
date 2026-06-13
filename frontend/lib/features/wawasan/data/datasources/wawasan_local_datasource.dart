/// Wawasan Feature - Data Layer - Local Data Source
///
/// Menyediakan data statis untuk Edukasi dan Langkah Pelaporan.
/// Dalam arsitektur nyata, ini bisa diganti dengan API call.
library wawasan_local_datasource;

import 'package:sigap_mobile/features/wawasan/domain/entities/education_card.dart';
import 'package:sigap_mobile/features/wawasan/domain/entities/report_step.dart';

class WawasanLocalDataSource {
  /// Data statis untuk Kapan Harus Lapor.
  List<EducationCard> getEducationCards() {
    return const [
      EducationCard(
        id: 'edu_1',
        title: 'Mengalami Tindak Kekerasan',
        imageAsset: 'assets/images/articles/wawasan_community.png',
        contentTitle: 'Mengalami Tindak Kekerasan',
        description:
            'Ketika mengalami kekerasan, tubuh dan pikiran sering memasuki mode bertahan. Banyak korban enggan bercerita karena takut dibalas atau malu.',
        keyPoints: [
          'Rasa takut dan bingung adalah reaksi wajar.',
          'Kekerasan fisik, psikis, seksual adalah pelanggaran HAM.',
          'Mencari pertolongan menyelamatkan diri, bukan aib.',
        ],
        actionSteps: [
          'Keselamatan tidak lagi terjamin.',
          'Luka fisik/tekanan emosional mengganggu aktivitas.',
          'Pelaku semakin mengontrol & mengintimidasi.',
        ],
      ),
      EducationCard(
        id: 'edu_2',
        title: 'Mengetahui Seseorang Menjadi Korban',
        imageAsset: 'assets/images/articles/wawasan_community.png',
        contentTitle: 'Mengetahui Korban',
        description:
            'Kadang kita tidak melihat langsung, tapi menangkap perubahan: teman yang menjauh atau anak yang mendadak murung.',
        keyPoints: [
          'Luka fisik yang alasannya tidak masuk akal.',
          'Ketakutan berlebihan pada pasangan/ortu.',
          'Penurunan drastis prestasi kerja/sekolah.',
        ],
        actionSteps: [
          'Jadilah pendengar yang aman.',
          'Tawarkan bantuan tanpa memaksa.',
          'Melaporkan situasi bahaya adalah bentuk kepedulian.',
        ],
      ),
      EducationCard(
        id: 'edu_3',
        title: 'Membutuhkan Informasi Perlindungan',
        imageAsset: 'assets/images/articles/wawasan_community.png',
        contentTitle: 'Informasi Perlindungan',
        description:
            'Banyak yang ragu melapor karena tidak paham prosedur atau takut balasan pelaku. Pengetahuan adalah kunci keberanian.',
        keyPoints: [
          'Laporan bisa dilakukan meski bukti belum lengkap.',
          'Berhak atas visum medis & konseling psikologis.',
          'Kerahasiaan identitas pelapor dijamin undang-undang.',
        ],
      ),
      EducationCard(
        id: 'edu_4',
        title: 'Menyaksikan Kekerasan Secara Langsung',
        imageAsset: 'assets/images/articles/wawasan_community.png',
        contentTitle: 'Menjadi Saksi Mata',
        description:
            'Dalam hitungan detik, Anda harus memutuskan. Prioritaskan keselamatan diri, tapi jangan abaikan korban.',
        keyPoints: [
          'Bantuan tidak harus berupa perkelahian fisik.',
          'Jangan anggap kekerasan sebagai "urusan pribadi".',
        ],
        actionSteps: [
          'Hubungi satpam/polisi jika mengancam nyawa.',
          'Rekam/Foto diam-diam sebagai bukti.',
          'Alihkan perhatian pelaku jika aman dilakukan.',
        ],
      ),
      EducationCard(
        id: 'edu_5',
        title: 'Situasi Darurat & Mengancam',
        imageAsset: 'assets/images/articles/wawasan_community.png',
        contentTitle: 'Situasi Darurat',
        description:
            'JANGAN MENUNDA! Situasi ini membutuhkan tindakan detik ini juga.',
        keyPoints: [
          'Pelaku membawa senjata tajam/api.',
          'Anak kecil dalam bahaya tanpa perlindungan.',
          'Ancaman pembunuhan atau penyekapan.',
          'Korban butuh medis segera (pingsan/berdarah).',
        ],
        actionSteps: [
          'Segera lari ke tempat aman.',
          'Hubungi 112 atau kantor polisi terdekat.',
        ],
        isEmergency: true,
      ),
    ];
  }

  /// Data statis untuk Cara Lapor - Lapor Daring.
  List<ReportStep> getOnlineReportSteps() {
    return const [
      ReportStep(
        stepNumber: 1,
        iconName: 'description',
        title: 'Isi Formulir Online',
        description:
            'Isi formulir online yang telah disediakan dengan lengkap dan jelas.',
      ),
      ReportStep(
        stepNumber: 2,
        iconName: 'cloud_upload',
        title: 'Unggah Bukti',
        description:
            'Unggah bukti atau informasi pendukung yang relevan dengan kasus.',
      ),
      ReportStep(
        stepNumber: 3,
        iconName: 'check_circle',
        title: 'Terima Kode Unik',
        description: 'Terima kode pelaporan unik Anda untuk tracking progress.',
      ),
      ReportStep(
        stepNumber: 4,
        iconName: 'hourglass_empty',
        title: 'Tunggu Tindak Lanjut',
        description:
            'Tunggu proses verifikasi dan tindak lanjut dari tim kami.',
      ),
    ];
  }

  /// Data statis untuk Cara Lapor - Langkah Penting.
  List<ReportStep> getImportantSteps() {
    return const [
      ReportStep(
        stepNumber: 0, // 0 indicates "!" badge
        iconName: 'save',
        title: 'Simpan Bukti',
        description:
            'Simpan semua bukti komunikasi, foto, atau video yang relevan.',
        isImportant: true,
      ),
      ReportStep(
        stepNumber: 0,
        iconName: 'shield',
        title: 'Jaga Keamanan',
        description: 'Prioritaskan keamanan pribadi Anda sebelum melaporkan.',
        isImportant: true,
      ),
      ReportStep(
        stepNumber: 0,
        iconName: 'group',
        title: 'Cari Dukungan',
        description:
            'Jangan ragu mencari dukungan dari orang terdekat atau profesional.',
        isImportant: true,
      ),
      ReportStep(
        stepNumber: 0,
        iconName: 'schedule',
        title: 'Segera Laporkan',
        description:
            'Semakin cepat dilaporkan, semakin baik untuk proses penanganan.',
        isImportant: true,
      ),
    ];
  }
}
