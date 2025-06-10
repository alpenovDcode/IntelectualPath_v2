import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _isSending = false;

  // Вставь свой Gemini API ключ сюда!
  final String apiKey = 'AIzaSyCM347dioAZcjU06QvH6joLakvOxtFJTuc';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    if (_messages.isEmpty) {
      _messages.add(_Message(text: 'Здравствуйте! Я ваш ИИ-ассистент. Чем могу помочь?', isBot: true));
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = _messages.map((m) => jsonEncode({'text': m.text, 'isBot': m.isBot})).toList();
    await prefs.setStringList('ai_chat_history', history);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('ai_chat_history') ?? [];
    setState(() {
      _messages.clear();
      _messages.addAll(history.map((e) {
        final map = jsonDecode(e);
        return _Message(text: map['text'], isBot: map['isBot']);
      }));
    });
  }

  Future<String> _fetchGeminiAnswer(String prompt) async {
    final endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });
    final response = await http.post(Uri.parse(endpoint), headers: headers, body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
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
      _messages.add(_Message(text: '...', isBot: true)); // индикатор ожидания
    });
    _scrollToBottom();
    await _saveHistory();
    try {
      final answer = await _fetchGeminiAnswer(text);
      setState(() {
        _messages.removeLast(); // убираем индикатор ожидания
        _messages.add(_Message(text: answer, isBot: true));
        _isSending = false;
      });
      await _saveHistory();
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(_Message(text: 'Ошибка при обращении к ИИ: $e', isBot: true));
        _isSending = false;
      });
      await _saveHistory();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Чат с ИИ')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _ChatBubble(message: msg);
              },
            ),
          ),
          const Divider(height: 1),
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
                ElevatedButton(
                  onPressed: _isSending ? null : _sendMessage,
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Отправить'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isBot;
  _Message({required this.text, required this.isBot});
}

class _ChatBubble extends StatelessWidget {
  final _Message message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isBot = message.isBot;
    final color = isBot ? Colors.grey[200] : Colors.blue[100];
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
                  decoration: BoxDecoration(color: color, borderRadius: borderRadius),
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