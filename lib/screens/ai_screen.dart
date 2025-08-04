import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:zappychat/screens/home_screen.dart';
import 'package:zappychat/screens/widgets/ai_message_card.dart';
import '../helper/dialogs.dart';
import '../main.dart';
import '../models/message.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _textC = TextEditingController();
  final _scrollC = ScrollController();

  final _list = <AiMessage>[
    AiMessage(msg: 'Hello, How can I help you?', msgType: MessageType.bot),
  ];

  Future<void> _askQuestion() async {
    _textC.text = _textC.text.trim();

    if (_textC.text.isNotEmpty) {
      // user message
      _list.add(AiMessage(msg: _textC.text, msgType: MessageType.user));
      _list.add(AiMessage(msg: '', msgType: MessageType.bot));
      setState(() {});

      _scrollDown();

      final res = await _getAnswer(_textC.text);

      // bot response
      _list.removeLast();
      _list.add(AiMessage(msg: res, msgType: MessageType.bot));
      _scrollDown();

      setState(() {});

      _textC.text = '';
      return;
    }

    Dialogs.showSnackbar(context, 'Ask Something!');
  }

  // For scrolling down
  void _scrollDown() {
    _scrollC.animateTo(
      _scrollC.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }


  Future<String> _getAnswer(final String question) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    const modelName = 'models/gemini-2.0-flash';
    const baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

    try {
      final url = Uri.parse('$baseUrl/$modelName:generateContent?key=$apiKey');

      final headers = {
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': question}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topP': 1,
          'topK': 40,
          'maxOutputTokens': 1024
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_NONE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_NONE'
          },
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_NONE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_NONE'
          }
        ]
      });

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

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

  @override
  void dispose() {
    _textC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context); // Pop screen if it can be popped
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
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
                controller: _textC,
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
                onPressed: _askQuestion,
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
        controller: _scrollC,
        padding: EdgeInsets.only(top: mq.height * .02, bottom: mq.height * .1),
        children: _list.map((e) => AiMessageCard(message: e)).toList(),
      ),
    );
  }
}
