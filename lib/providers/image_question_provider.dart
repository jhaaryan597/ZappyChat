import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ImageQuestion {
  final String question;
  final String imageUrl;

  ImageQuestion({required this.question, required this.imageUrl});
}

final imageQuestionProvider = FutureProvider.autoDispose
    .family<String, ImageQuestion>((ref, imageQuestion) async {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: dotenv.env['GEMINI_API_KEY']!,
      );

      final response = await http.get(Uri.parse(imageQuestion.imageUrl));
      final Uint8List imageBytes = response.bodyBytes;

      final content = [
        Content.multi([
          TextPart(imageQuestion.question),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final result = await model.generateContent(content);

      return result.text ?? '...';
    });
