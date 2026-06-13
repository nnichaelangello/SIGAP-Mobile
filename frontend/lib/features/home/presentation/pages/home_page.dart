import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/core/widgets/blur_extension.dart';
import 'package:sigap_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:sigap_mobile/features/home/presentation/widgets/service_grid.dart';
import 'package:sigap_mobile/features/home/presentation/widgets/agenda_card.dart';
import 'package:sigap_mobile/features/home/presentation/pages/agenda_list_page.dart';

/// Halaman Beranda — Orchestrator ringan.
/// Mendukung mode Guest (belum login) dan mode Logged In.
class HomePage extends StatelessWidget {
  final bool isGuest;

  const HomePage({super.key, this.isGuest = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppConstants.backgroundColor,
      child: Stack(
        children: [
          const _BackgroundLayer(),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                HomeHeader(isGuest: isGuest),
                const SizedBox(height: 24),
                ServiceGrid(isGuest: isGuest),
                const SizedBox(height: 32),
                _buildAgendaSection(context),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section Agenda Prioritas.
  /// Jika Guest: judul & tombol "Lihat Semua" tetap muncul, tapi kartu kosong.
  Widget _buildAgendaSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Agenda Prioritas",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AgendaListPage(),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        "Lihat Semua",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppConstants.primaryColor,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 290,
          child:
              isGuest ? _buildGuestAgendaCards() : _buildLoggedInAgendaCards(),
        ),
      ],
    );
  }

  /// Kartu agenda kosong/putih untuk Guest.
  Widget _buildGuestAgendaCards() {
    return ListView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      clipBehavior: Clip.none,
      children: const [
        _EmptyAgendaCard(),
        SizedBox(width: 20),
        _EmptyAgendaCard(),
        SizedBox(width: 20),
        _EmptyAgendaCard(),
      ],
    );
  }

  /// Kartu agenda berisi untuk user yang sudah login.
  Widget _buildLoggedInAgendaCards() {
    return ListView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      clipBehavior: Clip.none,
      children: const [
        AgendaCard(
          title: "Kuliah Umum: Etika AI",
          subtitle: "Wajib bagi mahasiswa tingkat akhir",
          month: "Okt",
          day: "24",
          time: "13:00 - 15:00",
          location: "Auditorium B",
          badge: "Akademik",
          imageUrl:
              "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?ixlib=rb-1.2.1&auto=format&fit=crop&w=600&q=80",
        ),
        SizedBox(width: 20),
        AgendaCard(
          title: "Job Fair Tahunan",
          subtitle: "Buka peluang karir masa depan",
          month: "Nov",
          day: "02",
          time: "09:00 - 16:00",
          location: "Main Hall",
          badge: "Karir",
          imageUrl:
              "https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?ixlib=rb-1.2.1&auto=format&fit=crop&w=600&q=80",
        ),
        SizedBox(width: 20),
        AgendaCard(
          title: "Pemilihan Ketua BEM",
          subtitle: "Gunakan hak suara anda",
          month: "Nov",
          day: "15",
          time: "Seharian",
          location: "Online Voting",
          badge: "Ormawa",
          imageUrl:
              "https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?ixlib=rb-1.2.1&auto=format&fit=crop&w=600&q=80",
        ),
      ],
    );
  }
}

/// Kartu agenda kosong untuk Guest — putih bersih dengan placeholder halus.
class _EmptyAgendaCard extends StatelessWidget {
  const _EmptyAgendaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 36,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            "Login untuk melihat agenda",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Layer background Glassmorphism (Glow Blobs + Gradient Fade).
class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Positioned(
          top: -50,
          right: 40,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.primaryColor.withValues(alpha: 0.2),
            ),
          ).blurred(blur: 100),
        ),
        Positioned(
          top: screenHeight * 0.4,
          left: -30,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
            ),
          ).blurred(blur: 80),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 600,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppConstants.primaryColor.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
