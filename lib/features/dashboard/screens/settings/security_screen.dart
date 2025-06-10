import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/theme.dart';
import '../../../../widgets/buttons.dart';
import '../../../auth/models/user.dart';

class SecurityScreen extends StatefulWidget {
  final User user;
  
  const SecurityScreen({
    super.key,
    required this.user,
  });

  @override
  SecurityScreenState createState() => SecurityScreenState();
}

class SecurityScreenState extends State<SecurityScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _biometricEnabled = false;
  bool _autoLockEnabled = true;
  String _autoLockTime = '5 минут';
  
  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }
  
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = prefs.getBool('security_biometric_${widget.user.id}') ?? false;
      _autoLockEnabled = prefs.getBool('security_auto_lock_${widget.user.id}') ?? true;
      _autoLockTime = prefs.getString('security_auto_lock_time_${widget.user.id}') ?? '5 минут';
    });
  }
  
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Пользователь не авторизован');
      }
      
      // Повторная аутентификация пользователя
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Обновление пароля
      await user.updatePassword(_newPasswordController.text);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пароль успешно изменен'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Очистка полей
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Неверный текущий пароль';
          break;
        case 'weak-password':
          errorMessage = 'Новый пароль слишком слабый';
          break;
        case 'requires-recent-login':
          errorMessage = 'Для смены пароля требуется повторный вход';
          break;
        default:
          errorMessage = 'Ошибка при смене пароля: ${e.message}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('security_biometric_${widget.user.id}', _biometricEnabled);
    await prefs.setBool('security_auto_lock_${widget.user.id}', _autoLockEnabled);
    await prefs.setString('security_auto_lock_time_${widget.user.id}', _autoLockTime);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Настройки безопасности сохранены'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _showAutoLockDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Автоблокировка'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              '1 минута',
              '5 минут',
              '10 минут',
              '30 минут',
              'Никогда',
            ].map((time) => RadioListTile<String>(
              title: Text(time),
              value: time,
              groupValue: _autoLockTime,
              onChanged: (value) {
                setState(() {
                  _autoLockTime = value!;
                });
                Navigator.pop(context);
                _saveSecuritySettings();
              },
            )).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Безопасность'),
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
              'Смена пароля',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _currentPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Текущий пароль',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurrentPassword 
                                ? Icons.visibility 
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscureCurrentPassword = !_obscureCurrentPassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        obscureText: _obscureCurrentPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите текущий пароль';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _newPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Новый пароль',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNewPassword 
                                ? Icons.visibility 
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        obscureText: _obscureNewPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите новый пароль';
                          }
                          if (value.length < 6) {
                            return 'Пароль должен содержать минимум 6 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Подтвердите новый пароль',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword 
                                ? Icons.visibility 
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Подтвердите новый пароль';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Пароли не совпадают';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: _isLoading ? 'Изменение...' : 'Изменить пароль',
                          onPressed: _isLoading ? null : _changePassword,
                          type: AppButtonType.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Дополнительная безопасность',
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
                    title: const Text('Биометрическая аутентификация'),
                    subtitle: const Text('Вход по отпечатку пальца или Face ID'),
                    value: _biometricEnabled,
                    onChanged: (value) {
                      setState(() {
                        _biometricEnabled = value;
                      });
                      _saveSecuritySettings();
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Автоблокировка'),
                    subtitle: const Text('Автоматическая блокировка приложения'),
                    value: _autoLockEnabled,
                    onChanged: (value) {
                      setState(() {
                        _autoLockEnabled = value;
                      });
                      _saveSecuritySettings();
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  if (_autoLockEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Время блокировки'),
                      subtitle: Text(_autoLockTime),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showAutoLockDialog,
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Управление сессиями',
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
                    leading: const Icon(Icons.devices),
                    title: const Text('Активные устройства'),
                    subtitle: const Text('Просмотреть и управлять устройствами'),
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
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Завершить все сессии', 
                        style: TextStyle(color: Colors.red)),
                    subtitle: const Text('Выйти со всех устройств'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Завершить все сессии'),
                            content: const Text(
                              'Вы будете выйти со всех устройств. Потребуется повторный вход.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Отмена'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Все сессии завершены'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                child: const Text('Завершить'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.amber[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Безопасность',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Регулярно обновляйте пароль и используйте надежные комбинации символов. Включите биометрическую аутентификацию для дополнительной защиты.',
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