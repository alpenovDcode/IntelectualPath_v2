import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme.dart';
import '../../../widgets/buttons.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user.dart';
import '../../courses/services/course_service.dart';
import '../../courses/models/course.dart';
import '../../courses/screens/course_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  
  const ProfileScreen({
    super.key,
    required this.user,
  });

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CourseService _courseService = CourseService();
  List<Course> _subscribedCourses = [];
  bool _isLoading = true;
  int _achievementsCount = 0;
  int _totalExperience = 0;
  String _userLevel = 'Новичок';
  String _profileImageUrl = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Принудительно обновляем данные о курсах и их статусы подписки
      await _courseService.getCoursesWithSubscriptionStatus(widget.user.id);
      await Future.delayed(const Duration(milliseconds: 100)); // Небольшая пауза для применения изменений
      
      // Получаем список подписанных курсов с актуальными данными
      final subscribedCourses = await _courseService.getUserSubscribedCourses(widget.user.id);
      
      // Если список пуст, но недавно была подписка, ждем и повторяем запрос
      if (subscribedCourses.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        await _courseService.getCoursesWithSubscriptionStatus(widget.user.id);
        final retriedCourses = await _courseService.getUserSubscribedCourses(widget.user.id);
        // Если повторная попытка успешна, используем эти данные
        if (retriedCourses.isNotEmpty) {
          _updateStateWithCourses(retriedCourses);
          return;
        }
      }
      
      // Загружаем дополнительные данные пользователя из хранилища
      final prefs = await SharedPreferences.getInstance();
      final achievements = prefs.getInt('user_achievements_${widget.user.id}') ?? 0;
      final experience = prefs.getInt('user_experience_${widget.user.id}') ?? 0;
      final level = _calculateUserLevel(experience);
      final imageUrl = prefs.getString('user_avatar_${widget.user.id}') ?? '';
      
      if (mounted) {
        setState(() {
          _subscribedCourses = subscribedCourses;
          _achievementsCount = achievements;
          _totalExperience = experience;
          _userLevel = level;
          _profileImageUrl = imageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка при загрузке данных пользователя: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Вспомогательный метод для обновления состояния
  void _updateStateWithCourses(List<Course> courses) {
    if (mounted) {
      setState(() {
        _subscribedCourses = courses;
        _isLoading = false;
      });
    }
  }
  
  String _calculateUserLevel(int experience) {
    if (experience < 100) return 'Новичок';
    if (experience < 300) return 'Ученик';
    if (experience < 600) return 'Студент';
    if (experience < 1000) return 'Практик';
    if (experience < 1500) return 'Мастер';
    return 'Эксперт';
  }
  
  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выход из аккаунта'),
          content: const Text('Вы уверены, что хотите выйти?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(AuthSignOutEvent());
              },
              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadUserData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Мой профиль',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(duration: 300.ms),
                        
                        const SizedBox(height: 24),
                        
                        // Информация профиля
                        _buildProfileCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Достижения
                        _buildAchievementsCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Табы для переключения между подписками и настройками
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Мои подписки'),
                            Tab(text: 'Настройки'),
                          ],
                          labelColor: AppTheme.primaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: AppTheme.primaryColor,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          height: 300,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildSubscriptionsTab(),
                              _buildSettingsTab(),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Кнопка выхода
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            text: 'Выйти из аккаунта',
                            onPressed: _signOut,
                            type: AppButtonType.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildProfileCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _profileImageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      _profileImageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                : CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.military_tech,
                        size: 16,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _userLevel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($_totalExperience XP)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Дата регистрации: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
  
  Widget _buildAchievementsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Мои достижения',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _achievementsCount > 0
                ? Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: List.generate(
                      _achievementsCount,
                      (index) => _buildAchievementBadge(index),
                    ),
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'У вас пока нет достижений. Завершите курсы, чтобы получить награды!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
  
  Widget _buildAchievementBadge(int index) {
    final List<IconData> achievementIcons = [
      Icons.school,
      Icons.workspace_premium,
      Icons.emoji_events,
      Icons.stars,
      Icons.psychology,
    ];
    
    final List<Color> achievementColors = [
      Colors.blue,
      Colors.green,
      Colors.amber,
      Colors.purple,
      Colors.red,
    ];
    
    final List<String> achievementNames = [
      'Первый шаг',
      'Ученик',
      'Исследователь',
      'Мыслитель',
      'Эксперт',
    ];
    
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: achievementColors[index % achievementColors.length].withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            achievementIcons[index % achievementIcons.length],
            color: achievementColors[index % achievementColors.length],
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          achievementNames[index % achievementNames.length],
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSubscriptionsTab() {
    return _subscribedCourses.isEmpty
        ? const Center(
            child: Text(
              'У вас пока нет подписок на курсы',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          )
        : ListView.builder(
            itemCount: _subscribedCourses.length,
            itemBuilder: (context, index) {
              final course = _subscribedCourses[index];
              return SubscriptionCard(
                course: course,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailScreen(course: course),
                    ),
                  ).then((_) => _loadUserData());
                },
                onUnsubscribe: () => _unsubscribeFromCourse(course.id),
              ).animate().fadeIn(
                delay: Duration(milliseconds: 100 + index * 50),
                duration: 300.ms,
              );
            },
          );
  }
  
  Future<void> _unsubscribeFromCourse(String courseId) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticatedState) {
      final success = await _courseService.unsubscribeFromCourse(
        authState.user.id,
        courseId,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы успешно отписались от курса'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при отписке от курса'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Widget _buildSettingsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Редактировать профиль'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Будет реализовано в следующей версии
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Эта функция будет доступна в следующей версии'),
                ),
              );
            },
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Уведомления'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Будет реализовано в следующей версии
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Эта функция будет доступна в следующей версии'),
                ),
              );
            },
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Безопасность'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Будет реализовано в следующей версии
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Эта функция будет доступна в следующей версии'),
                ),
              );
            },
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Язык'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Будет реализовано в следующей версии
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Эта функция будет доступна в следующей версии'),
                ),
              );
            },
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.info),
            title: const Text('О приложении'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'IntellectualPath',
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(size: 48),
                children: [
                  const Text(
                    'Платформа для онлайн-обучения с различными курсами и интерактивными уроками.',
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // Публичный метод для обновления данных пользователя
  Future<void> loadUserData() async {
    await _loadUserData();
  }
}

class SubscriptionCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final VoidCallback onUnsubscribe;
  
  const SubscriptionCard({
    super.key,
    required this.course,
    required this.onTap,
    required this.onUnsubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: course.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  course.icon,
                  color: course.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      course.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Прогресс: ${(course.progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Отписаться от курса'),
                        content: Text('Вы уверены, что хотите отписаться от курса "${course.title}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onUnsubscribe();
                            },
                            child: const Text('Отписаться'),
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
      ),
    );
  }
} 