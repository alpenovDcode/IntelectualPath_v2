import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../domain/message_model.dart';

class ChatService {
  Future<String> fetchGptAnswer(String prompt, List<MessageModel> history) async {
    const endpoint = 'https://api.openai.com/v1/chat/completions';
    final apiKey = dotenv.env['OPENAI_API_KEY'];

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': [
        {'role': 'system', 'content': 'Ты helpful AI-ассистент для образовательного приложения.'},
        ...history
            .where((m) => !m.isBot)
            .map((m) => {'role': 'user', 'content': m.text})
            .toList(),
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': 256,
      'temperature': 0.7,
    });

    final response = await http.post(Uri.parse(endpoint), headers: headers, body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content']?.trim() ?? 'Нет ответа от ИИ.';
    } else {
      throw Exception('Ошибка от API: ${response.statusCode}');
    }
  }
} 