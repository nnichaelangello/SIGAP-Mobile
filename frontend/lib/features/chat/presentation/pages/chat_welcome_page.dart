import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/chat/presentation/pages/chat_page.dart';

/// Halaman pembuka (Cover Page) untuk fitur Chatbot.
/// Menggunakan pendekatan DeepEmpathy & DeepUI untuk memberikan rasa tenang.
class ChatWelcomePage extends StatefulWidget {
  const ChatWelcomePage({super.key});

  @override
  State<ChatWelcomePage> createState() => _ChatWelcomePageState();
}

class _ChatWelcomePageState extends State<ChatWelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  /// Lock navigasi — mencegah double/triple-tap push multiple route.
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Animasi masuk yang halus (1.2 detik)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToChat() async {
    // Cegah double/triple-tap push multiple route ke stack
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    // DeepAnimation: Navigasi dengan Hero transition + slide smoothing
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ChatPage(),
        // Durasi lebih panjang untuk Hero transition yang mulus
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // DeepAnimation: Kombinasi Fade + Slide untuk efek premium
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              // Fade dimulai cepat, selesai di 70% untuk memberi ruang Hero
              curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05), // Slide ringan dari bawah
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
    );

    // Release lock saat user kembali dari ChatPage
    if (mounted) {
      setState(() => _isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tidak menggunakan Scaffold karena sudah ada di MainScreen
    // Menggunakan Container dengan background color
    return Container(
      color: AppConstants.backgroundColor,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top spacing
              const SizedBox(height: 32),

              // --- GIF SECTION with Hero Animation ---
              FadeTransition(
                opacity: _fadeAnimation,
                child: Hero(
                  tag: 'chatbot_avatar', // Tag untuk transisi ke ChatPage
                  child: Container(
                    height: 240,
                    width: 240,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        // Efek shadow lembut untuk memberi kesan "floating"
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primaryColor
                                .withValues(alpha: 0.08),
                            blurRadius: 40,
                            spreadRadius: 10,
                            offset: const Offset(0, 10),
                          )
                        ]),
                    child: ClipOval(
                      // Menampilkan GIF yang diberikan user
                      child: Image.asset(
                        'assets/animations/chat_welcome.gif',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback jika gif gagal dimuat
                          return const Center(
                            child: Icon(Icons.favorite_rounded,
                                size: 80, color: Colors.pinkAccent),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Spacing between GIF and Text
              const SizedBox(height: 28),

              // --- TEXT SECTION (PSYCHOLOGICAL & EMPATHY) ---
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Column(
                    children: [
                      Text(
                        "Hai, Sahabat...",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Ada yang ingin dibicarakan?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.textDark,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Aku di sini untuk mendengarkan setiap keluh kesahmu, tanpa menghakimi. Ceritakan saja, lepaskan bebanmu disini.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppConstants.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Spacing between Text and Button
              const SizedBox(height: 36),

              // --- BUTTON SECTION ---
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isNavigating ? null : _navigateToChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        shadowColor:
                            AppConstants.primaryColor.withValues(alpha: 0.4),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Mulai Bercerita",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Jarak besar di bawah untuk clearance FAB + BottomAppBar (~66 FAB + ~60 navbar + margin)
              const SizedBox(height: 160),
            ],
          ),
        ),
      ),
    );
  }
}
