import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:zappychat/models/message.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final smartReplyProvider = FutureProvider.autoDispose
    .family<List<String>, List<Message>>((ref, messages) async {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: dotenv.env['GEMINI_API_KEY']!,
      );

      final chatHistory =
          messages.map((message) {
            return Content(message.fromId == 'user' ? 'user' : 'model', [
              TextPart(message.msg),
            ]);
          }).toList();

      final chat = model.startChat(history: chatHistory);
      final response = await chat.sendMessage(
        Content.text('Suggest three short replies.'),
      );

      return response.text?.split('\n').where((s) => s.isNotEmpty).toList() ??
          [];
    });
