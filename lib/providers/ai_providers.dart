import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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
    : model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: dotenv.env['GEMINI_API_KEY']!,
      ),
      super([
        AiMessage(msg: 'Hello, How can I help you?', msgType: MessageType.bot),
      ]) {
    chat = model.startChat();
  }

  late final ChatSession chat;
  final GenerativeModel model;

  Future<void> askQuestion(String question) async {
    state = [...state, AiMessage(msg: question, msgType: MessageType.user)];
    state = [...state, AiMessage(msg: '', msgType: MessageType.bot)];

    try {
      final content = Content.text(question);
      final responses = chat.sendMessageStream(content);

      await for (final response in responses) {
        final text = response.text;
        if (text != null) {
          state = [
            ...state.sublist(0, state.length - 1),
            AiMessage(msg: text, msgType: MessageType.bot),
          ];
        }
      }
    } catch (e) {
      state = state..removeLast();
      state = [
        ...state,
        AiMessage(
          msg: 'Something went wrong! Please try again.',
          msgType: MessageType.bot,
        ),
      ];
    }
  }
}
