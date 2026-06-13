import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import '../notifiers/chat_notifier.dart';
import 'animated_icon_button.dart';

/// Area input pesan chat dengan tombol voice dan send.
/// Dipindahkan dari inline _buildInputArea() di chat_page.dart.
class ChatInputArea extends StatefulWidget {
  const ChatInputArea({super.key});

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _onVoicePressed() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fitur voice sedang dalam pengembangan 🎤'),
        backgroundColor: AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleSend() {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    _messageController.clear();
    context.read<ChatNotifier>().sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ChatNotifier>();

    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16, MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            AnimatedIconButton(
              icon: Icons.mic_rounded,
              onPressed: _onVoicePressed,
              backgroundColor:
                  AppConstants.primaryColor.withValues(alpha: 0.1),
              iconColor: AppConstants.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _inputFocusNode,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                ),
                onChanged: (v) => notifier.onTextChanged(v),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedScale(
              scale: notifier.canSend ? 1.0 : 0.85,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: notifier.canSend ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: AnimatedIconButton(
                  icon: Icons.send_rounded,
                  onPressed:
                      notifier.canSend && !notifier.isTyping
                          ? _handleSend
                          : null,
                  backgroundColor: notifier.canSend
                      ? AppConstants.primaryColor
                      : Colors.grey.shade300,
                  iconColor: notifier.canSend
                      ? Colors.white
                      : Colors.grey.shade500,
                  isGradient: notifier.canSend,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
