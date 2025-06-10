import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../widgets/buttons.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user.dart';
import '../../courses/models/course.dart';
import '../../courses/services/course_service.dart';
import '../../courses/screens/courses_screen.dart';
import '../../courses/screens/course_detail_screen.dart';
import '../../courses/screens/lesson_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/profile_screen.dart';
import '../../courses/services/recommendation_service.dart';
import '../../gamification/models/achievement.dart';
import '../../gamification/models/daily_task.dart';
import '../../gamification/models/streak.dart';
import '../../gamification/services/gamification_service.dart';
import '../../assistant/screens/assistant_screen.dart';
import '../../../ai_chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  List<Course> _courses = [];
  bool _isLoading = true;
  final CourseService _courseService = CourseService();
  late final RecommendationService _recommendationService = RecommendationService();
  late final GamificationService _gamificationService = GamificationService();
  
  // Данные для геймификации
  List<Achievement> _achievements = [];
  List<DailyTask> _dailyTasks = [];
  Streak? _streak;
  
  // Ключи для доступа к состояниям дочерних виджетов
  final GlobalKey<ProgressScreenState> _progressScreenKey = GlobalKey<ProgressScreenState>();
  final GlobalKey<ProfileScreenState> _profileScreenKey = GlobalKey<ProfileScreenState>();

  @override
  void initState() {
    super.initState();
    loadCourses();
    loadGamificationData();
  }

  Future<void> loadGamificationData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticatedState) {
      final userId = authState.user.id;
      
      final achievements = await _gamificationService.getAchievements(userId);
      final dailyTasks = await _gamificationService.getDailyTasks(userId);
      final streak = await _gamificationService.getStreak(userId);
      
      setState(() {
        _achievements = achievements;
        _dailyTasks = dailyTasks;
        _streak = streak;
      });
    }
  }

  Future<void> loadCourses() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticatedState) {
        final userId = authState.user.id;
        final courses = await _courseService.getUserCourses(userId);
        
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
      } else {
        final courses = await _courseService.getCourses();
        
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка при загрузке курсов: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticatedState) {
          final User user = state.user;
          
          return Scaffold(
            appBar: AppBar(
              title: const Text('IntelectualPath'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.smart_toy),
                  tooltip: 'Чат с ИИ',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AiChatScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // Будет реализовано позже
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle),
                  onSelected: (value) {
                    if (value == 'logout') {
                      context.read<AuthBloc>().add(AuthSignOutEvent());
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'profile',
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text('Профиль ${user.name}'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings, color: AppTheme.primaryColor),
                            SizedBox(width: 8),
                            Text('Настройки'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Выйти'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeTab(user),
                _buildCoursesTab(),
                _buildProgressTab(),
                _buildProfileTab(user),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                // При переключении на вкладку прогресса или профиля, обновляем данные
                if (index == 2 || index == 3) {
                  // Сначала обновляем глобальные данные
                  _refreshGlobalData(user.id).then((_) {
                    // Затем переключаем вкладку
                    setState(() {
                      _selectedIndex = index;
                    });
                    
                    // После переключения обновляем соответствующую вкладку
                    if (index == 2) {
                      refreshProgress();
                    } else if (index == 3) {
                      refreshProfileData();
                    }
                  });
                } else {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primaryColor,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Главная',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.school_outlined),
                  activeIcon: Icon(Icons.school),
                  label: 'Курсы',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined),
                  activeIcon: Icon(Icons.bar_chart),
                  label: 'Прогресс',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Профиль',
                ),
              ],
            ),
          );
        }
        
        // Если пользователь не аутентифицирован, редирект произойдет 
        // на уровне router или BlocBuilder в IntelectualPathApp
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
  
  Widget _buildHomeTab(User user) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final userInterests = <String>[]; // TODO: получить интересы пользователя из профиля
    final completedCourseIds = _courses.where((c) =>
      c.modules.expand((m) => m.lessons).every((lesson) => lesson.isCompleted)
    ).map((c) => c.id).toList();
    final recommendedCourses = _recommendationService.getRecommendedCourses(
      user: user,
      allCourses: _courses,
      userInterests: userInterests,
      completedCourseIds: completedCourseIds,
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Привет, ${user.name}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_streak != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Серия: ${_streak!.currentStreak} дней',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    'Продолжайте обучение',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0, duration: 300.ms),
            
            const SizedBox(height: 24),
            
                          const Text(
              'Ежедневные задания',
                            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms),
            
            const SizedBox(height: 16),
            
            _dailyTasks.isEmpty
              ? Center(
                  child: Text(
                    'Нет доступных заданий',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _dailyTasks.length,
                  itemBuilder: (context, index) {
                    final task = _dailyTasks[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                          color: task.isCompleted ? Colors.green : Colors.grey,
                        ),
                        title: Text(task.title),
                        subtitle: Text(task.description),
                        trailing: Text(
                          '+${task.reward}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 300 + index * 100));
                  },
                ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Достижения',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 300.ms),
            
            const SizedBox(height: 16),
            
            _achievements.isEmpty
              ? Center(
                  child: Text(
                    'Нет доступных достижений',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = _achievements[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            Icon(
                              achievement.icon,
                              size: 32,
                              color: achievement.isUnlocked ? Colors.amber : Colors.grey,
                              ),
                            const SizedBox(height: 8),
                              Text(
                              achievement.title,
                              textAlign: TextAlign.center,
                                style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: achievement.isUnlocked ? Colors.black : Colors.grey,
                                ),
                              ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: achievement.progressPercentage,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                achievement.isUnlocked ? Colors.green : Colors.blue,
                              ),
                      ),
                    ],
                  ),
              ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 400 + index * 100));
                  },
                ),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Мои курсы',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;  // Переключиться на вкладку курсов
                    });
                  },
                  child: const Text('Все курсы'),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: _courses.isEmpty
                ? Center(
                    child: Text(
                      'У вас пока нет курсов',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CourseDetailScreen(course: course),
                              ),
                            ).then((_) => loadCourses());
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  color: course.color.withOpacity(0.8),
                                ),
                                child: Center(
                                  child: Icon(
                                    course.icon,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${course.completedLessons}/${course.modules.expand((m) => m.lessons).length} уроков',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: course.progress,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(course.color),
                                      borderRadius: BorderRadius.circular(4),
                                      minHeight: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 200 + index * 100));
                    },
                  ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Рекомендуемые курсы',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 16),
            
            recommendedCourses.isEmpty
              ? Center(
                  child: Text(
                    'Рекомендаций пока нет',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recommendedCourses.length,
                  itemBuilder: (context, index) {
                    final course = recommendedCourses[index];
                    return CourseCard(
                      course: course,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                            builder: (context) => CourseDetailScreen(course: course),
                            ),
                          ).then((_) => loadCourses());
                        },
                    ).animate().fadeIn(delay: Duration(milliseconds: 500 + index * 100));
                  },
                ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCoursesTab() {
    return const CoursesScreen();
  }
  
  Widget _buildProgressTab() {
    return ProgressScreen(key: _progressScreenKey);
  }
  
  Widget _buildProfileTab(User user) {
    return ProfileScreen(key: _profileScreenKey, user: user);
  }

  // Метод для перехода на вкладку профиля
  void goToProfileTab() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticatedState) {
      final userId = authState.user.id;
      // Обновляем все данные перед переключением
      _refreshGlobalData(userId).then((_) {
        setState(() {
          _selectedIndex = 3; // Индекс вкладки профиля
        });
        refreshProfileData(); // Явно обновляем профиль после переключения
      });
    } else {
      setState(() {
        _selectedIndex = 3;
      });
    }
  }

  // Метод для обновления глобальных данных
  Future<void> _refreshGlobalData(String userId) async {
    final courseService = CourseService();
    // Обновляем данные о подписках
    await courseService.getCoursesWithSubscriptionStatus(userId);
    // Небольшая пауза для применения изменений
    await Future.delayed(const Duration(milliseconds: 100));
    await courseService.getUserSubscribedCourses(userId);
  }

  // Метод для обновления прогресса, вызываемый после подписки на курс
  void refreshProgress() {
    // Сначала обновляем основные данные о курсах
    loadCourses().then((_) {
      // Затем обновляем вкладку прогресса, если она существует
      if (_progressScreenKey.currentState != null) {
        _progressScreenKey.currentState!.loadUserProgress();
      }
    });
  }
  
  // Метод для обновления данных профиля, вызываемый после подписки на курс
  void refreshProfileData() {
    // Обновляем профиль, если он существует
    if (_profileScreenKey.currentState != null) {
      _profileScreenKey.currentState!.loadUserData();
    }
  }
} 