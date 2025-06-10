import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/theme.dart';
import '../../../../widgets/buttons.dart';
import '../../../auth/models/user.dart';

class NotificationsScreen extends StatefulWidget {
  final User user;
  
  const NotificationsScreen({
    super.key,
    required this.user,
  });

  @override
  NotificationsScreenState createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _courseUpdates = true;
  bool _newCourses = false;
  bool _achievements = true;
  bool _reminders = true;
  bool _weeklyDigest = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('notifications_push_${widget.user.id}') ?? true;
      _courseUpdates = prefs.getBool('notifications_course_updates_${widget.user.id}') ?? true;
      _newCourses = prefs.getBool('notifications_new_courses_${widget.user.id}') ?? false;
      _achievements = prefs.getBool('notifications_achievements_${widget.user.id}') ?? true;
      _reminders = prefs.getBool('notifications_reminders_${widget.user.id}') ?? true;
      _weeklyDigest = prefs.getBool('notifications_weekly_digest_${widget.user.id}') ?? false;
    });
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('notifications_push_${widget.user.id}', _pushNotifications);
      await prefs.setBool('notifications_course_updates_${widget.user.id}', _courseUpdates);
      await prefs.setBool('notifications_new_courses_${widget.user.id}', _newCourses);
      await prefs.setBool('notifications_achievements_${widget.user.id}', _achievements);
      await prefs.setBool('notifications_reminders_${widget.user.id}', _reminders);
      await prefs.setBool('notifications_weekly_digest_${widget.user.id}', _weeklyDigest);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки уведомлений сохранены'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
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
                    'Push-уведомления',
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
                          title: const Text('Push-уведомления'),
                          subtitle: const Text('Основные уведомления от приложения'),
                          value: _pushNotifications,
                          onChanged: (value) {
                            setState(() {
                              _pushNotifications = value;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Обновления курсов'),
                          subtitle: const Text('Уведомления о новых уроках и материалах'),
                          value: _courseUpdates,
                          onChanged: (value) {
                            setState(() {
                              _courseUpdates = value;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Новые курсы'),
                          subtitle: const Text('Уведомления о добавлении новых курсов'),
                          value: _newCourses,
                          onChanged: (value) {
                            setState(() {
                              _newCourses = value;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Образовательные уведомления',
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
                          title: const Text('Достижения'),
                          subtitle: const Text('Уведомления о получении наград и достижений'),
                          value: _achievements,
                          onChanged: (value) {
                            setState(() {
                              _achievements = value;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Напоминания'),
                          subtitle: const Text('Напоминания о продолжении обучения'),
                          value: _reminders,
                          onChanged: (value) {
                            setState(() {
                              _reminders = value;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Еженедельная сводка'),
                          subtitle: const Text('Отчет о вашем прогрессе за неделю'),
                          value: _weeklyDigest,
                          onChanged: (value) {
                            setState(() {
                              _weeklyDigest = value;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Сохранить настройки',
                      onPressed: _saveSettings,
                      type: AppButtonType.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
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
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Информация',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Push-уведомления помогают вам не пропустить важные обновления и напоминания об обучении. Вы можете настроить их под свои предпочтения.',
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