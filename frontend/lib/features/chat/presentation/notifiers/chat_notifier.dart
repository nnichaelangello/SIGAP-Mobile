import 'package:flutter/foundation.dart';
import '../../data/chat_service.dart';
import '../../data/models/chat_bubble_model.dart';

/// Single source of truth untuk seluruh state dan business logic chat.
///
/// Menggantikan semua setState() yang tersebar di _ChatPageState.
/// Pattern: ChangeNotifier + Provider (konsisten dengan SatgasNotifier
/// dan EmergencyLiveProvider yang sudah ada di codebase).
class ChatNotifier extends ChangeNotifier {
  final ChatService _chatService;

  final List<ChatBubbleModel> _messages = [];
  List<ChatBubbleModel> get messages => List.unmodifiable(_messages);

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  bool _canSend = false;
  bool get canSend => _canSend;

  ChatNotifier({required ChatService chatService})
      : _chatService = chatService;

  /// Tambahkan pesan sambutan bot di awal sesi.
  void addWelcomeMessage() {
    _messages.add(ChatBubbleModel(
      text: _chatService.getWelcomeMessage(),
      isUser: false,
      time: _formatTime(DateTime.now()),
    ));
    notifyListeners();
  }

  /// Update flag `canSend` berdasarkan isi input field.
  void onTextChanged(String text) {
    final newCanSend = text.trim().isNotEmpty;
    if (newCanSend != _canSend) {
      _canSend = newCanSend;
      notifyListeners();
    }
  }

  /// Kirim pesan user ke AI dan tunggu respon.
  /// Business logic sepenuhnya di sini — UI hanya memanggil method ini.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    // Tambahkan pesan user
    _messages.add(ChatBubbleModel(
      text: trimmed,
      isUser: true,
      time: _formatTime(DateTime.now()),
    ));
    _isTyping = true;
    _canSend = false;
    notifyListeners();

    try {
      final response = await _chatService.sendMessage(trimmed);

      _messages.add(ChatBubbleModel(
        text: response,
        isUser: false,
        time: _formatTime(DateTime.now()),
      ));
    } catch (e) {
      _messages.add(ChatBubbleModel(
        text: 'Maaf, terjadi gangguan koneksi. Silakan coba kirim pesan kembali.',
        isUser: false,
        time: _formatTime(DateTime.now()),
      ));
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  /// Reset seluruh riwayat percakapan.
  void clearHistory() {
    _chatService.clearHistory();
    _messages.clear();
    notifyListeners();
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
