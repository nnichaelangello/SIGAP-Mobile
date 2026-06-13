/// Chat Feature - Chat Service
/// Handles communication with Groq API for AI chatbot functionality
library chat_service;

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:sigap_mobile/features/chat/data/chat_api_config.dart';

/// Model untuk pesan chat
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.user(String content) => ChatMessage(
        role: 'user',
        content: content,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.assistant(String content) => ChatMessage(
        role: 'assistant',
        content: content,
        timestamp: DateTime.now(),
      );

  Map<String, dynamic> toApiFormat() => {
        'role': role,
        'content': content,
      };
}

/// Service untuk berkomunikasi dengan Groq API
class ChatService {
  static const int _maxHistoryLength = 20; // Limit history untuk performa
  static const int _contextWindowSize = 10; // Pesan yang dikirim ke API

  final List<ChatMessage> _conversationHistory = [];

  List<ChatMessage> get history => List.unmodifiable(_conversationHistory);

  /// Mengirim pesan ke AI dan mendapatkan respons
  Future<String> sendMessage(String userMessage) async {
    // Tambahkan pesan user ke history
    _conversationHistory.add(ChatMessage.user(userMessage));
    _trimHistoryIfNeeded();

    try {
      // Bangun messages array untuk API
      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': ChatApiConfig.systemPrompt},
        // Ambil N pesan terakhir untuk konteks
        ..._conversationHistory
            .take(_contextWindowSize)
            .map((m) => m.toApiFormat()),
      ];

      developer.log(
        'Sending message to Groq API',
        name: 'ChatService',
      );

      final response = await http
          .post(
            Uri.parse(ChatApiConfig.groqApiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${ChatApiConfig.groqApiKey}',
            },
            body: jsonEncode({
              'model': ChatApiConfig.groqModel,
              'messages': messages,
              'max_tokens': 500,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;

        if (choices.isEmpty) {
          throw Exception('Empty response from API');
        }

        final aiResponse = choices[0]['message']['content'] as String;

        // Tambahkan respons AI ke history
        _conversationHistory.add(ChatMessage.assistant(aiResponse));

        developer.log(
          'Response received successfully',
          name: 'ChatService',
        );

        return aiResponse;
      } else {
        developer.log(
          'API Error: ${response.statusCode}',
          name: 'ChatService',
          error: response.body,
        );
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      developer.log(
        'Error sending message',
        name: 'ChatService',
        error: e.toString(),
      );

      // Fallback response jika API gagal
      const fallbackResponse =
          'Maaf, aku sedang mengalami kendala teknis. Tapi aku tetap di sini untukmu 💙\n\nCoba kirim pesanmu lagi ya.';

      _conversationHistory.add(ChatMessage.assistant(fallbackResponse));

      return fallbackResponse;
    }
  }

  /// Trim history jika melebihi batas
  void _trimHistoryIfNeeded() {
    if (_conversationHistory.length > _maxHistoryLength) {
      _conversationHistory.removeRange(
        0,
        _conversationHistory.length - _maxHistoryLength,
      );
    }
  }

  /// Mendapatkan pesan sambutan awal
  String getWelcomeMessage() {
    return 'Hai! 👋 Aku TemanKu.\n\nMau cerita apa hari ini? Tenang aja, semua yang kamu ceritain aman sama aku kok. 💙';
  }

  /// Reset conversation history
  void clearHistory() {
    _conversationHistory.clear();
  }
}
