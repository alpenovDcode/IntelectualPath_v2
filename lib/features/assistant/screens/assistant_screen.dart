import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/buttons.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  List<_Message> _messages = [];
  bool _isSending = false;
  bool _isLoadingHistory = true;

  final String? apiKey = const String.fromEnvironment('OPENAI_API_KEY');

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getString('ai_chat_history');
    if (history != null) {
      final List<dynamic> decoded = jsonDecode(history);
      setState(() {
        _messages = decoded.map((e) => _Message.fromJson(e)).toList();
        _isLoadingHistory = false;
      });
    } else {
      final welcome = _Message(text: 'Здравствуйте! Я ваш ИИ-ассистент. Чем могу помочь?', isBot: true);
      setState(() {
        _messages = [welcome];
        _isLoadingHistory = false;
      });
      _saveHistory();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_messages.map((e) => e.toJson()).toList());
    await prefs.setString('ai_chat_history', encoded);
  }

  Future<String> _fetchGptAnswer(String prompt) async {
    if (apiKey == null || apiKey!.isEmpty) {
      return 'Ошибка: API ключ OpenAI не настроен. Пожалуйста, добавьте его в переменные окружения.';
    }
    
    const endpoint = 'https://api.openai.com/v1/chat/completions';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': [
        {'role': 'system', 'content': 'Ты helpful AI-ассистент для образовательного приложения.'},
        ..._messages
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
      final content = data['choices'][0]['message']['content'] as String?;
      return content?.trim() ?? 'Нет ответа от ИИ.';
    } else {
      return 'Ошибка: ${response.statusCode}\n${response.body}';
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(text: text, isBot: false));
      _controller.clear();
      _isSending = true;
    });
    _saveHistory();
    try {
      final answer = await _fetchGptAnswer(text);
      setState(() {
        _messages.add(_Message(text: answer, isBot: true));
        _isSending = false;
      });
      _saveHistory();
    } catch (e) {
      setState(() {
        _messages.add(_Message(text: 'Ошибка при обращении к ИИ: $e', isBot: true));
        _isSending = false;
      });
      _saveHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI-ассистент'),
      ),
      body: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _ChatBubble(message: msg);
                    },
                  ),
                ),
                Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Введите сообщение...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppButton(
                        text: 'Отправить',
                        onPressed: _isSending ? null : _sendMessage,
                        isLoading: _isSending,
                        type: AppButtonType.primary,
                        size: AppButtonSize.small,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _Message message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isBot = message.isBot;
    final color = isBot ? Colors.grey[200] : Theme.of(context).primaryColorLight;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isBot ? const Radius.circular(4) : const Radius.circular(16),
      bottomRight: isBot ? const Radius.circular(16) : const Radius.circular(4),
    );
    final avatar = CircleAvatar(
      backgroundColor: isBot ? Colors.blueGrey[100] : Colors.blue[100],
      child: Icon(isBot ? Icons.smart_toy : Icons.person, color: isBot ? Colors.blueGrey : Colors.blue),
    );
    final name = isBot ? 'Ассистент' : 'Вы';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot) avatar,
          if (isBot) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Text(name, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: borderRadius,
                  ),
                  child: Text(message.text),
                ),
              ],
            ),
          ),
          if (!isBot) const SizedBox(width: 8),
          if (!isBot) avatar,
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isBot;
  _Message({required this.text, required this.isBot});

  Map<String, dynamic> toJson() => {'text': text, 'isBot': isBot};
  factory _Message.fromJson(Map<String, dynamic> json) => _Message(
    text: json['text'] as String,
    isBot: json['isBot'] as bool,
  );
} 