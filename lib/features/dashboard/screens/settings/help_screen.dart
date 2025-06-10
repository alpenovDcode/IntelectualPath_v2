import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/theme.dart';
import '../../../../widgets/buttons.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  HelpScreenState createState() => HelpScreenState();
}

class HelpScreenState extends State<HelpScreen> {
  final List<_FAQ> _faqs = [
    _FAQ(
      question: 'Как начать изучение курса?',
      answer: 'Выберите интересующий вас курс на главном экране, нажмите "Подписаться" и начните изучение первого урока.',
    ),
    _FAQ(
      question: 'Как отслеживать свой прогресс?',
      answer: 'Прогресс отображается на странице каждого курса. Также вы можете увидеть общую статистику в разделе "Профиль".',
    ),
    _FAQ(
      question: 'Можно ли изучать курсы офлайн?',
      answer: 'Некоторые материалы можно загрузить для изучения без интернета. Эта функция доступна в настройках курса.',
    ),
    _FAQ(
      question: 'Как получить сертификат?',
      answer: 'Сертификат выдается после успешного прохождения всех уроков и тестов курса с результатом не менее 70%.',
    ),
    _FAQ(
      question: 'Что делать, если забыл пароль?',
      answer: 'На экране входа нажмите "Забыли пароль?" и следуйте инструкциям для восстановления доступа.',
    ),
    _FAQ(
      question: 'Как изменить язык интерфейса?',
      answer: 'Перейдите в Профиль → Настройки → Язык и выберите подходящий язык из списка.',
    ),
    _FAQ(
      question: 'Как связаться с поддержкой?',
      answer: 'Вы можете написать нам через форму обратной связи в разделе "О приложении" или по email: support@intellectualpath.com',
    ),
  ];

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Помощь'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Часто задаваемые вопросы',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // FAQ секция
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _faqs.length; i++) ...[
                    _FAQTile(faq: _faqs[i]),
                    if (i < _faqs.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Быстрые действия',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.video_library, color: AppTheme.primaryColor),
                    title: const Text('Как пользоваться приложением'),
                    subtitle: const Text('Видео-руководство для новых пользователей'),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Видео-руководство будет доступно в следующей версии'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.book, color: AppTheme.primaryColor),
                    title: const Text('Руководство пользователя'),
                    subtitle: const Text('Подробная документация'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showUserGuide();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bug_report, color: Colors.orange),
                    title: const Text('Сообщить об ошибке'),
                    subtitle: const Text('Помогите нам улучшить приложение'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showBugReport();
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Контакты',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email, color: AppTheme.primaryColor),
                    title: const Text('Email поддержка'),
                    subtitle: const Text('support@intellectualpath.com'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      _launchURL('mailto:support@intellectualpath.com?subject=Помощь по приложению IntellectualPath');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.chat, color: AppTheme.primaryColor),
                    title: const Text('Онлайн чат'),
                    subtitle: const Text('Быстрые ответы на вопросы'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Онлайн чат будет доступен в следующей версии'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.forum, color: AppTheme.primaryColor),
                    title: const Text('Форум сообщества'),
                    subtitle: const Text('Общение с другими пользователями'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      _launchURL('https://forum.intellectualpath.com');
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Совет',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Для лучшего обучения рекомендуем заниматься регулярно по 15-30 минут в день. Включите уведомления, чтобы не забывать о занятиях!',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showUserGuide() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Руководство пользователя'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '1. Регистрация и вход',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Создайте аккаунт или войдите через Google\n• Заполните свой профиль\n'),
                
                Text(
                  '2. Выбор курсов',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Просмотрите каталог курсов\n• Подпишитесь на интересующие курсы\n'),
                
                Text(
                  '3. Обучение',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Изучайте уроки последовательно\n• Проходите тесты для закрепления\n• Отслеживайте прогресс\n'),
                
                Text(
                  '4. Получение сертификата',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Завершите все уроки курса\n• Пройдите финальный тест\n• Получите сертификат'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Понятно'),
            ),
          ],
        );
      },
    );
  }
  
  void _showBugReport() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text('Сообщить об ошибке'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Опишите проблему, с которой вы столкнулись:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Подробное описание ошибки...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            AppButton(
              text: 'Отправить',
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Спасибо за отчет! Мы рассмотрим его в ближайшее время.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              type: AppButtonType.primary,
            ),
          ],
        );
      },
    );
  }
}

class _FAQ {
  final String question;
  final String answer;
  
  _FAQ({required this.question, required this.answer});
}

class _FAQTile extends StatefulWidget {
  final _FAQ faq;
  
  const _FAQTile({required this.faq});

  @override
  _FAQTileState createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        widget.faq.question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      leading: Icon(
        Icons.help_outline,
        color: AppTheme.primaryColor,
      ),
      trailing: Icon(
        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
      ),
      onExpansionChanged: (expanded) {
        setState(() {
          _isExpanded = expanded;
        });
      },
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.faq.answer,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 