class MessageModel {
  final String text;
  final bool isBot;

  MessageModel({required this.text, required this.isBot});

  Map<String, dynamic> toJson() => {'text': text, 'isBot': isBot};

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      text: json['text'] as String,
      isBot: json['isBot'] as bool,
    );
  }
} 