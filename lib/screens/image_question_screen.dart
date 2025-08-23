import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zappychat/models/message.dart';
import 'package:zappychat/providers/image_question_provider.dart';

class ImageQuestionScreen extends ConsumerWidget {
  final Message message;
  const ImageQuestionScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Ask a question')),
      body: Column(
        children: [
          Expanded(child: Image.network(message.msg)),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      hintText: 'Ask a question about the image...',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final question = textController.text;
                    if (question.isNotEmpty) {
                      final answer = await ref.read(
                        imageQuestionProvider(
                          ImageQuestion(
                            question: question,
                            imageUrl: message.msg,
                          ),
                        ).future,
                      );
                      showDialog(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: const Text('Answer'),
                              content: Text(answer),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
