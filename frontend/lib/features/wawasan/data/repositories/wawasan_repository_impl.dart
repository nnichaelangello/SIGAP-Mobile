import 'package:sigap_mobile/features/wawasan/data/datasources/wawasan_local_datasource.dart';
import 'package:sigap_mobile/features/wawasan/domain/entities/education_card.dart';
import 'package:sigap_mobile/features/wawasan/domain/entities/report_step.dart';
import 'package:sigap_mobile/features/wawasan/domain/entities/article.dart';
import 'package:sigap_mobile/features/wawasan/domain/repositories/wawasan_repository.dart';

class WawasanRepositoryImpl implements WawasanRepository {
  final WawasanLocalDataSource localDataSource;

  WawasanRepositoryImpl({required this.localDataSource});

  @override
  Future<List<EducationCard>> getEducationCards() async {
    // Simulasi delay network
    await Future.delayed(const Duration(milliseconds: 300));
    return localDataSource.getEducationCards();
  }

  @override
  Future<List<ReportStep>> getReportSteps(ReportStepCategory category) async {
    await Future.delayed(const Duration(milliseconds: 200));
    switch (category) {
      case ReportStepCategory.online:
        return localDataSource.getOnlineReportSteps();
      case ReportStepCategory.important:
        return localDataSource.getImportantSteps();
    }
  }

  @override
  Future<List<Article>> getArticles({int limit = 5}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Using placeholder network images to ensure they load without local assets
    // Content is generated to be deep, meaningful, and educational.
    return [
      Article(
        id: 'art_1',
        title:
            'Mengenali Red Flags: Tanda-Tanda Kekerasan yang Sering Terabaikan',
        excerpt:
            'Kekerasan tidak selalu berupa pukulan. Seringkali, ia datang dalam bentuk manipulasi halus yang mengikis kepercayaan diri.',
        imageUrl: 'assets/images/articles/wawasan_red_flags.png',
        category: 'Edukasi',
        publishedAt: DateTime(2026, 1, 30),
        author: 'Tim Psikolog SIGAP',
        content: """
Kekerasan dalam hubungan seringkali tidak dimulai dengan ledakan amarah atau serangan fisik. Justru, dalam banyak kasus, ia dimulai dengan "cinta" yang berlebihan, perhatian yang mengekang, dan kontrol yang disamarkan sebagai rasa peduli. Ini adalah fase yang disebut *Love Bombing*, di mana pelaku membanjiri korban dengan afeksi untuk membangun ketergantungan emosional.

Namun, setelah ikatan terbentuk, pola mulai berubah. Kritik-kritik kecil mulai muncul. "Kamu yakin mau pakai baju itu?", "Kenapa kamu lebih sering main sama teman daripada sama aku?", "Aku cuma mau yang terbaik buat kamu." Kalimat-kalimat ini terdengar seperti perhatian, tapi sebenarnya adalah benih isolasi.

Tanda-tanda *Red Flags* yang harus diwaspadai:

1.  **Isolasi**: Pelaku perlahan menjauhkan Anda dari sistem pendukung (keluarga, teman). Tujuannya agar saat terjadi masalah, Anda merasa tidak punya siapa-siapa.
2.  **Gaslighting**: Membuat Anda meragukan kewarasan atau ingatan sendiri. "Ah, kamu terlalu sensitif", "Aku nggak pernah bilang gitu, kamu aja yang ngarang."
3.  **Perubahan Mood Drastis**: Pelaku bisa sangat manis satu menit, lalu meledak marah di menit berikutnya, membuat Anda terus berjalan di atas cangkang telur (*walking on eggshells*).

Jika Anda merasakan tanda-tanda ini, percayalah pada insting Anda. Rasa tidak nyaman itu valid. Anda berhak atas hubungan yang aman, setara, dan menghargai otonomi Anda.
        """,
      ),
      Article(
        id: 'art_2',
        title:
            'Langkah Pertama Setelah Mengalami Pelecehan: Jangan Salahkan Diri Sendiri',
        excerpt:
            'Mengalami pelecehan adalah trauma berat. Langkah pertama pemulihan adalah berhenti menyalahkan diri sendiri atas kejahatan orang lain.',
        imageUrl: 'assets/images/articles/wawasan_healing.png',
        category: 'Pemulihan',
        publishedAt: DateTime(2026, 1, 29),
        author: 'Tim Konselor SIGAP',
        content: """
Reaksi pertama korban pelecehan seringkali adalah *Self-Blame*. "Seharusnya aku nggak lewat jalan itu," "Seharusnya aku nggak pakai baju ini," "Seharusnya aku lebih tegas."

Stop. Berhenti di situ.

Pelecehan seksual adalah 100% kesalahan pelaku. Tidak ada satupun tindakan, pakaian, atau lokasi korban yang membenarkan tindakan kejahatan tersebut. Menyalahkan diri sendiri adalah mekanisme pertahanan otak untuk mencari rasa "kendali" (illusion of control), tapi ini justru menghambat pemulihan.

Yang harus dilakukan:
1.  **Cari Tempat Aman**: Prioritas utama adalah keselamatan fisik Anda saat ini.
2.  **Jangan Mandi/Ganti Baju (Jika ingin lapor)**: Meski sangat tidak nyaman, bukti fisik di tubuh/pakaian sangat krusial untuk visum. Namun jika Anda memilih untuk tidak lapor hukum, lakukan apa saja yang membuat Anda nyaman.
3.  **Hubungi Orang Terpercaya**: Jangan simpan beban ini sendirian. Bercerita pada teman atau konselor bukan berarti lemah, tapi langkah berani untuk bertahan.

Anda berharga. Apa yang terjadi pada Anda tidak mendefinisikan siapa Anda.
        """,
      ),
      Article(
        id: 'art_3',
        title: 'Menuntut Keadilan: Panduan Lengkap UU TPKS untuk Korban',
        excerpt:
            'Payung hukum di Indonesia kini semakin kuat berpihak pada korban. Ketahui hak-hak Anda agar tidak mudah diintimidasi.',
        imageUrl: 'assets/images/articles/wawasan_law.png',
        category: 'Hukum',
        publishedAt: DateTime(2026, 1, 28),
        author: 'Tim Advokasi Hukum',
        content: """
UU TPKS (Undang-Undang Tindak Pidana Kekerasan Seksual) membawa angin segar bagi penegakan hukum di Indonesia. UU ini mengakui bentuk-bentuk kekerasan seksual yang sebelumnya sulit dijerat hukum, seperti pelecehan fisik non-penetratif dan kekerasan berbasis elektronik (KBGO).

Hak-hak fundamental korban dalam UU TPKS:
*   **Hak atas Penanganan**: Korban berhak mendapatkan layanan pengaduan, pemeriksaan kesehatan (visum) gratis, dan pendampingan hukum sejak awal proses.
*   **Hak atas Perlindungan**: Mengatur perlindungan dari ancaman fisik maupun psikis pelaku. Identitas korban wajib dirahasiakan oleh aparat.
*   **Hak atas Pemulihan**: Negara wajib menyediakan layanan pemulihan fisik, psikologis, dan sosial bagi korban.

Restitusi (ganti rugi) dari pelaku kepada korban kini juga menjadi fokus utama, bukan sekadar hukuman penjara bagi pelaku. Pengetahuan adalah kekuatan. Dengan memahami hak hukum, Anda memiliki posisi tawar yang lebih kuat untuk menuntut keadilan.
        """,
      ),
      Article(
        id: 'art_4',
        title: 'Digital Wellness: Menjaga Kewarasan di Era KBGO',
        excerpt:
            'Kekerasan Berbasis Gender Online (KBGO) meningkat tajam. Bagaimana menjaga jejak digital tetap aman?',
        imageUrl: 'assets/images/articles/wawasan_digital_safety.png',
        category: 'Panduan',
        publishedAt: DateTime(2026, 1, 25),
        author: 'Tim Cyber Security',
        content: """
Internet adalah ruang publik baru, dan sayangnya, juga menjadi tempat baru bagi kekerasan seksual. Penyebaran konten intim tanpa izin (Non-Consensual Intimate Images/NCII), doxing, dan cyber-stalking adalah ancaman nyata.

Tips *Digital Hygiene* untuk Keamanan:
1.  **Think before you share**: Sekali data masuk internet, Anda kehilangan kendali atasnya. Berhati-hatilah membagikan informasi lokasi atau data pribadi.
2.  **Two-Factor Authentication (2FA)**: Wajib aktifkan di semua akun media sosial dan email. Ini adalah lapisan pertahanan terkuat.
3.  **Jaga Lingkaran Privasi**: Selektif menerima permintaan pertemanan. Lakukan audit pengikut media sosial secara berkala.

Jika menjadi korban KBGO:
*   Simpan bukti (screenshot URL, chat, profil pelaku).
*   Jangan hapus akun Anda dulu (bukti bisa hilang).
*   Laporkan ke platform (Report) dan ke lembaga bantuan seperti SAFENet.
        """,
      ),
      Article(
        id: 'art_5',
        title:
            'Bystander Intervention: Apa yang Harus Dilakukan Saat Melihat Pelecehan?',
        excerpt:
            'Diam bukan berarti netral, diam berarti membiarkan. Kita semua bisa menjadi pahlawan dengan metode 5D.',
        imageUrl: 'assets/images/articles/wawasan_community.png',
        category: 'Edukasi',
        publishedAt: DateTime(2026, 1, 20),
        author: 'Tim Kampanye Publik',
        content: """
Banyak orang ingin menolong saat melihat pelecehan di tempat umum, tapi bingung atau takut. Metode 5D adalah panduan intervensi saksi yang aman dan efektif:

1.  **Direct (Tegur Langsung)**: Jika situasi aman, tegur pelaku. "Hei, itu tidak sopan!" atau "Mbak, kamu gak apa-apa digituin?"
2.  **Distract (Alihkan)**: Pura-pura tanya jam, tanya jalan, atau jatuhkan barang untuk memecah fokus pelaku dan memberi kesempatan korban menjauh.
3.  **Delegate (Lapor)**: Minta bantuan orang lain yang berwenang (satpam, kondektur bus, polisi). "Pak, tolong ada yang mengganggu di sana."
4.  **Delay (Tunggu)**: Jika tidak berani saat kejadian, tunggu sampai pelaku pergi lalu dekati korban. "Kamu butuh bantuan? Mau ditemani?" Ini sangat berarti untuk validasi perasaan korban.
5.  **Document (Rekam)**: Rekam kejadian dari jarak aman sebagai bukti, tapi JANGAN unggah ke medsos tanpa izin korban. Serahkan bukti ke korban.

Keberanian kita untuk tidak diam bisa mengubah nasib seseorang hari itu.
        """,
      ),
    ].take(limit).toList();
  }

  @override
  Future<Article?> getArticleById(String id) async {
    final articles = await getArticles(limit: 10);
    try {
      return articles.firstWhere((article) => article.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Article>> searchArticles(String query) async {
    await Future.delayed(
        const Duration(milliseconds: 300)); // Make it feel real but fast
    final allArticles = await getArticles(limit: 20); // Get all articles data
    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    return allArticles.where((article) {
      return article.title.toLowerCase().contains(lowercaseQuery) ||
          article.excerpt.toLowerCase().contains(lowercaseQuery) ||
          article.category.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}
