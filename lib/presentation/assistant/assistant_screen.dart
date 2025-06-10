import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/chat_service.dart';
import '../../../domain/message_model.dart';
import '../../../widgets/buttons.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  List<MessageModel> _messages = [];
  bool _isSending = false;
  bool _isLoadingHistory = true;

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
      _messages = decoded.map((e) => MessageModel.fromJson(e)).toList();
    } else {
      _messages = [MessageModel(text: 'Здравствуйте! Я ваш ИИ-ассистент. Чем могу помочь?', isBot: true)];
    }
    setState(() => _isLoadingHistory = false);
    _saveHistory();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_messages.map((e) => e.toJson()).toList());
    await prefs.setString('ai_chat_history', encoded);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(MessageModel(text: text, isBot: false));
      _controller.clear();
      _isSending = true;
    });
    _scrollToBottom();
    _saveHistory();

    try {
      final response = await _chatService.fetchGptAnswer(text, _messages);
      setState(() {
        _messages.add(MessageModel(text: response, isBot: true));
        _isSending = false;
      });
      _scrollToBottom();
      _saveHistory();
    } catch (e) {
      setState(() {
        _messages.add(MessageModel(text: 'Ошибка: $e', isBot: true));
        _isSending = false;
      });
      _scrollToBottom();
      _saveHistory();
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
      appBar: AppBar(title: const Text('AI-ассистент')),
      body: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
  final MessageModel message;
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