import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zappychat/providers/ai_providers.dart';
import 'package:zappychat/screens/home_screen.dart';
import 'package:zappychat/screens/widgets/ai_message_card.dart';
import '../helper/dialogs.dart';
import '../main.dart';

class AiScreen extends ConsumerWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textC = ref.watch(aiTextControllerProvider);
    final scrollC = ref.watch(aiScrollControllerProvider);
    final list = ref.watch(aiMessagesProvider);

    void scrollDown() {
      Future.delayed(const Duration(milliseconds: 100), () {
        scrollC.animateTo(
          scrollC.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      });
    }

    ref.listen(aiMessagesProvider, (_, __) {
      scrollDown();
    });

    void askQuestion() {
      textC.text = textC.text.trim();
      if (textC.text.isNotEmpty) {
        ref.read(aiMessagesProvider.notifier).askQuestion(textC.text);
        textC.text = '';
      } else {
        Dialogs.showSnackbar(context, 'Ask Something!');
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          },
        ),
        title: const Text('ZappyBot'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: textC,
                textAlign: TextAlign.center,
                onTapOutside: (e) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  filled: true,
                  isDense: true,
                  hintText: 'Ask me anything you want...',
                  hintStyle: const TextStyle(fontSize: 14),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue,
              child: IconButton(
                onPressed: askQuestion,
                icon: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        controller: scrollC,
        padding: EdgeInsets.only(top: mq.height * .02, bottom: mq.height * .1),
        children: list.map((e) => AiMessageCard(message: e)).toList(),
      ),
    );
  }
}
