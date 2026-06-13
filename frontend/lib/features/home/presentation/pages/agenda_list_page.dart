import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Data model internal untuk Agenda
class _AgendaData {
  final String title;
  final String subtitle;
  final String month;
  final String day;
  final String time;
  final String location;
  final String badge;
  final Color badgeColor;
  final IconData categoryIcon;

  const _AgendaData({
    required this.title,
    required this.subtitle,
    required this.month,
    required this.day,
    required this.time,
    required this.location,
    required this.badge,
    required this.badgeColor,
    required this.categoryIcon,
  });
}

class AgendaListPage extends StatefulWidget {
  const AgendaListPage({super.key});

  @override
  State<AgendaListPage> createState() => _AgendaListPageState();
}

class _AgendaListPageState extends State<AgendaListPage> {
  String _selectedFilter = "Semua";

  final List<String> _filters = [
    "Semua",
    "Akademik",
    "Karir",
    "Ormawa",
    "Keamanan",
  ];

  List<_AgendaData> get _allAgendas => const [
        _AgendaData(
          title: "Kuliah Umum: Etika AI",
          subtitle: "Wajib bagi mahasiswa tingkat akhir",
          month: "Feb",
          day: "24",
          time: "13:00 - 15:00",
          location: "Auditorium B",
          badge: "Akademik",
          badgeColor: Color(0xFF3B82F6),
          categoryIcon: Icons.school_rounded,
        ),
        _AgendaData(
          title: "Job Fair Tahunan 2026",
          subtitle: "Buka peluang karir masa depan bersama 50+ perusahaan",
          month: "Mar",
          day: "02",
          time: "09:00 - 16:00",
          location: "Main Hall",
          badge: "Karir",
          badgeColor: Color(0xFF10B981),
          categoryIcon: Icons.work_rounded,
        ),
        _AgendaData(
          title: "Pemilihan Ketua BEM",
          subtitle: "Gunakan hak suara anda untuk kemajuan kampus",
          month: "Mar",
          day: "15",
          time: "Seharian",
          location: "Online Voting",
          badge: "Ormawa",
          badgeColor: Color(0xFFF59E0B),
          categoryIcon: Icons.how_to_vote_rounded,
        ),
        _AgendaData(
          title: "Workshop Pencegahan PPKS",
          subtitle: "Mengenali dan mencegah kekerasan seksual di kampus",
          month: "Mar",
          day: "20",
          time: "10:00 - 12:00",
          location: "Gedung Utama Lt. 3",
          badge: "Keamanan",
          badgeColor: Color(0xFFEF4444),
          categoryIcon: Icons.shield_rounded,
        ),
        _AgendaData(
          title: "Seminar Nasional Teknologi",
          subtitle: "Tren AI & Machine Learning untuk industri masa depan",
          month: "Mar",
          day: "28",
          time: "08:30 - 16:00",
          location: "Auditorium A",
          badge: "Akademik",
          badgeColor: Color(0xFF3B82F6),
          categoryIcon: Icons.school_rounded,
        ),
        _AgendaData(
          title: "Career Coaching Session",
          subtitle: "Sesi 1-on-1 bersama HRD perusahaan terkemuka",
          month: "Apr",
          day: "05",
          time: "13:00 - 17:00",
          location: "Ruang Konseling",
          badge: "Karir",
          badgeColor: Color(0xFF10B981),
          categoryIcon: Icons.work_rounded,
        ),
        _AgendaData(
          title: "Rapat Umum Himpunan",
          subtitle: "Evaluasi program kerja semester ganjil",
          month: "Apr",
          day: "12",
          time: "15:30 - 17:30",
          location: "Aula Fakultas",
          badge: "Ormawa",
          badgeColor: Color(0xFFF59E0B),
          categoryIcon: Icons.how_to_vote_rounded,
        ),
      ];

  List<_AgendaData> get _filteredAgendas {
    if (_selectedFilter == "Semua") return _allAgendas;
    return _allAgendas.where((a) => a.badge == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom SliverAppBar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppConstants.textDark,
                ),
              ),
            ),
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                "Agenda Prioritas",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textDark,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
            ],
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Divider(height: 1, color: Colors.grey.shade100),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isActive = _selectedFilter == filter;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppConstants.primaryColor
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? Colors.white
                                    : AppConstants.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Count indicator
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                "${_filteredAgendas.length} agenda ditemukan",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),

          // Agenda list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList.separated(
              itemCount: _filteredAgendas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _AgendaListTile(agenda: _filteredAgendas[index]);
              },
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }
}

class _AgendaListTile extends StatelessWidget {
  final _AgendaData agenda;

  const _AgendaListTile({required this.agenda});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date block
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: agenda.badgeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    agenda.month.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: agenda.badgeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    agenda.day,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: agenda.badgeColor,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: agenda.badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          agenda.categoryIcon,
                          size: 11,
                          color: agenda.badgeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          agenda.badge.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: agenda.badgeColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    agenda.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    agenda.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Meta row
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        agenda.time,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          agenda.location,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
