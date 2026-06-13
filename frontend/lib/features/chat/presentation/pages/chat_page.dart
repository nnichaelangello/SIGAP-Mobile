/// Chat Feature - ChatPage (Halaman Percakapan)
/// Premium UI dengan DeepUI, DeepUX & DeepAnimation principles
///
/// REFACTORED: God Widget (800 lines) → thin shell (~140 lines).
/// Business logic → ChatNotifier
/// Widget components → widgets/ folder
/// Data model → data/models/
library chat_page;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigap_mobile/features/chat/data/chat_service.dart';
import 'package:sigap_mobile/features/chat/presentation/notifiers/chat_notifier.dart';
import 'package:sigap_mobile/features/chat/presentation/widgets/chat_app_bar.dart';
import 'package:sigap_mobile/features/chat/presentation/widgets/chat_bubble_widget.dart';
import 'package:sigap_mobile/features/chat/presentation/widgets/chat_input_area.dart';
import 'package:sigap_mobile/features/chat/presentation/widgets/typing_indicator_widget.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final notifier = ChatNotifier(chatService: ChatService());
        // Delay welcome message untuk efek dramatis setelah animasi masuk
        Future.delayed(const Duration(milliseconds: 600), () {
          notifier.addWelcomeMessage();
        });
        return notifier;
      },
      child: const _ChatView(),
    );
  }
}

/// View utama — hanya orchestrate layout dan animasi entry.
/// Tidak memiliki business logic apapun.
class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> with TickerProviderStateMixin {
  // Animasi entry — dikelola di page level karena harus sinkron
  late final AnimationController _pageEntryController;
  late final AnimationController _inputAreaController;

  late final Animation<double> _headerFadeAnimation;
  late final Animation<Offset> _headerSlideAnimation;
  late final Animation<double> _inputFadeAnimation;
  late final Animation<Offset> _inputSlideAnimation;
  late final Animation<double> _inputScaleAnimation;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pageEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageEntryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageEntryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _inputAreaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _inputFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _inputAreaController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    _inputSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _inputAreaController,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );
    _inputScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _inputAreaController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _pageEntryController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _inputAreaController.forward();
    });
  }

  @override
  void dispose() {
    _pageEntryController.dispose();
    _inputAreaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: ChatAppBar(
        headerFadeAnimation: _headerFadeAnimation,
        headerSlideAnimation: _headerSlideAnimation,
      ),
      body: Column(
        children: [
          // Chat Messages Area
          Expanded(
            child: FadeTransition(
              opacity: _headerFadeAnimation,
              child: Consumer<ChatNotifier>(
                builder: (context, notifier, _) {
                  // Auto-scroll saat ada pesan baru
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: notifier.messages.length +
                        (notifier.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == notifier.messages.length &&
                          notifier.isTyping) {
                        return const ChatTypingIndicator();
                      }
                      return ChatBubbleWidget(
                        bubble: notifier.messages[index],
                        index: index,
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Input Area
          SlideTransition(
            position: _inputSlideAnimation,
            child: FadeTransition(
              opacity: _inputFadeAnimation,
              child: ScaleTransition(
                scale: _inputScaleAnimation,
                child: const ChatInputArea(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
