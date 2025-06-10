import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/theme.dart';
import '../../../../widgets/buttons.dart';
import '../../../auth/models/user.dart';

class LanguageScreen extends StatefulWidget {
  final User user;
  
  const LanguageScreen({
    super.key,
    required this.user,
  });

  @override
  LanguageScreenState createState() => LanguageScreenState();
}

class LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'Русский';
  bool _autoDetect = true;
  bool _isLoading = false;
  
  final List<Map<String, String>> _languages = [
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
  ];
  
  @override
  void initState() {
    super.initState();
    _loadLanguageSettings();
  }
  
  Future<void> _loadLanguageSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language_${widget.user.id}') ?? 'Русский';
      _autoDetect = prefs.getBool('language_auto_detect_${widget.user.id}') ?? true;
    });
  }
  
  Future<void> _saveLanguageSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('language_${widget.user.id}', _selectedLanguage);
      await prefs.setBool('language_auto_detect_${widget.user.id}', _autoDetect);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки языка сохранены'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при сохранении: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showLanguageChangeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Изменение языка'),
          content: const Text(
            'Для полного применения изменений необходимо перезапустить приложение. Применить изменения сейчас?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Позже'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Язык будет изменен при следующем запуске'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('Применить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Язык'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Язык интерфейса',
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
                        SwitchListTile(
                          title: const Text('Автоматическое определение'),
                          subtitle: const Text('Определять язык по системным настройкам'),
                          value: _autoDetect,
                          onChanged: (value) {
                            setState(() {
                              _autoDetect = value;
                            });
                            _saveLanguageSettings();
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        if (!_autoDetect) ...[
                          const Divider(height: 1),
                          ...List.generate(_languages.length, (index) {
                            final language = _languages[index];
                            return RadioListTile<String>(
                              title: Row(
                                children: [
                                  Text(
                                    language['flag']!,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(language['name']!),
                                ],
                              ),
                              value: language['name']!,
                              groupValue: _selectedLanguage,
                              onChanged: (value) {
                                setState(() {
                                  _selectedLanguage = value!;
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Дополнительные настройки',
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
                          leading: const Icon(Icons.download),
                          title: const Text('Загрузить языковые пакеты'),
                          subtitle: const Text('Для работы без интернета'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Функция будет доступна в следующей версии'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.translate),
                          title: const Text('Перевод курсов'),
                          subtitle: const Text('Автоматический перевод содержимого'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Перевод курсов'),
                                  content: const Text(
                                    'Автоматический перевод поможет изучать курсы на вашем языке. Качество перевода может отличаться.',
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
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.location_on),
                          title: const Text('Региональные настройки'),
                          subtitle: const Text('Формат даты, времени и чисел'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Функция будет доступна в следующей версии'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  if (!_autoDetect)
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: 'Применить изменения',
                        onPressed: () {
                          _saveLanguageSettings().then((_) {
                            _showLanguageChangeDialog();
                          });
                        },
                        type: AppButtonType.primary,
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.language, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Многоязычность',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'IntellectualPath поддерживает множество языков. Выберите подходящий язык для комфортного обучения. Некоторые курсы могут быть доступны только на определенных языках.',
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
} 