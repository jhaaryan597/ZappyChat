import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:zappychat/models/message.dart';

final aiTextControllerProvider = Provider.autoDispose<TextEditingController>((
  ref,
) {
  return TextEditingController();
});

final aiScrollControllerProvider = Provider.autoDispose<ScrollController>((
  ref,
) {
  return ScrollController();
});

final aiMessagesProvider =
    StateNotifierProvider<AiMessagesNotifier, List<AiMessage>>((ref) {
      return AiMessagesNotifier();
    });

class AiMessagesNotifier extends StateNotifier<List<AiMessage>> {
  AiMessagesNotifier()
    : super([
        AiMessage(msg: 'Hello, How can I help you?', msgType: MessageType.bot),
      ]);

  Future<void> askQuestion(String question) async {
    state = [...state, AiMessage(msg: question, msgType: MessageType.user)];
    state = [...state, AiMessage(msg: '', msgType: MessageType.bot)];

    final res = await _getAnswer(question);

    state = state..removeLast();
    state = [...state, AiMessage(msg: res, msgType: MessageType.bot)];
  }

  Future<String> _getAnswer(final String question) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    const modelName = 'models/gemini-2.0-flash';
    const baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

    try {
      final url = Uri.parse('$baseUrl/$modelName:generateContent?key=$apiKey');

      final headers = {'Content-Type': 'application/json'};

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': question},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topP': 1,
          'topK': 40,
          'maxOutputTokens': 1024,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_NONE',
          },
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_NONE',
          },
        ],
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text = json['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null) {
          return text.toString().trim();
        } else {
          return '🤖 Empty response from AI';
        }
      } else {
        final error = jsonDecode(response.body);
        final message = error['error']?['message'] ?? 'Unknown error';
        debugPrint('❗ API Error: $message');

        if (response.statusCode == 403) {
          return '🔐 Access denied. Check API key and billing setup.';
        } else if (response.statusCode == 404) {
          return '🔍 Model not found. Try "models/gemini-pro" instead.';
        } else {
          return '🚨 Error ${response.statusCode}: $message';
        }
      }
    } catch (e, stack) {
      debugPrint('Exception: $e');
      debugPrint('Stack: $stack');
      return '⚠️ Network or parsing error: ${e.toString().split(':').first}';
    }
  }
}
