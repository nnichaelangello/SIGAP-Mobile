/// Model data untuk satu bubble pesan chat.
///
/// Dipindahkan dari inline `_ChatBubble` di chat_page.dart ke data layer
/// agar bisa diakses oleh notifier dan widget secara terpisah.
class ChatBubbleModel {
  final String text;
  final bool isUser;
  final String time;

  const ChatBubbleModel({
    required this.text,
    required this.isUser,
    required this.time,
  });
}
