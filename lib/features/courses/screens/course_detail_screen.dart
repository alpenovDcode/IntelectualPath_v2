import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/buttons.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import 'lesson_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  
  const CourseDetailScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late Course _course;
  final CourseService _courseService = CourseService();
  bool _isLoading = false;
  bool _isSubscriptionLoading = false;
  
  @override
  void initState() {
    super.initState();
    _course = widget.course;
  }
  
  Future<void> _toggleSubscription() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticatedState) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Необходимо войти в аккаунт для подписки на курс')),
      );
      return;
    }

    final userId = authState.user.id;
    
    setState(() {
      _isSubscriptionLoading = true;
    });
    
    try {
      bool success;
      final isCurrentlySubscribed = _course.isSubscribed;
      
      if (isCurrentlySubscribed) {
        success = await _courseService.unsubscribeFromCourse(userId, _course.id);
      } else {
        success = await _courseService.subscribeToCourse(userId, _course.id);
      }
      
      if (success && mounted) {
        // Ключевое изменение: сначала обновляем глобальные данные в сервисах
        await _courseService.getCoursesWithSubscriptionStatus(userId);
        await _courseService.getUserSubscribedCourses(userId);

        // Обновляем все связанные экраны через Dashboard
        final dashboardState = context.findAncestorStateOfType<DashboardScreenState>();
        if (dashboardState != null) {
          // Обновляем основной экран
          await dashboardState.loadCourses();
          
          // Обновляем прогресс
          if (!isCurrentlySubscribed) {
            dashboardState.refreshProgress();
            
            // Даем время на обновление данных прежде чем показать профиль
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Обновляем профиль
            dashboardState.refreshProfileData();
            
            // Переходим на профиль
            dashboardState.goToProfileTab();
          } else {
            // Если отписались, обновляем другим способом
            dashboardState.refreshProgress();
            dashboardState.refreshProfileData();
          }
        }

        // Получаем обновленные данные о текущем курсе
        final updatedCourse = await _courseService.getCourseById(_course.id);
        if (updatedCourse != null && mounted) {
          setState(() {
            _course = updatedCourse;
          });
          
          // Показываем сообщение об успешной операции
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(!isCurrentlySubscribed
                  ? 'Вы успешно подписались на курс' 
                  : 'Вы отписались от курса'),
              backgroundColor: !isCurrentlySubscribed ? Colors.green : Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubscriptionLoading = false;
        });
      }
    }
  }
  
  Future<void> _toggleLessonCompletion(String lessonId, bool isCompleted) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticatedState) {
        final userId = authState.user.id;
        await _courseService.updateLessonProgress(
          userId,
          _course.id,
          lessonId,
          isCompleted,
        );
        
        // Обновляем курс
        final updatedCourse = await _courseService.getCourseById(_course.id);
        if (updatedCourse != null) {
          setState(() {
            _course = updatedCourse;
          });
        }
      }
    } catch (e) {
      print('Ошибка при обновлении прогресса: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при обновлении прогресса: $e'),
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
    final totalDuration = _course.lessons.fold(
      0, (total, lesson) => total + lesson.durationMinutes);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Заголовок с изображением
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _course.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _course.color,
                      _course.color.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _course.icon,
                    size: 80,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ),
          
          // Основное содержимое
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Карточка с информацией о курсе
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'О курсе',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ).animate().fadeIn(duration: 300.ms),
                          const SizedBox(height: 8),
                          Text(
                            _course.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InfoItem(
                                  icon: Icons.library_books,
                                  title: '${_course.lessons.length}',
                                  subtitle: 'уроков',
                                ),
                              ),
                              Expanded(
                                child: InfoItem(
                                  icon: Icons.access_time,
                                  title: '$totalDuration',
                                  subtitle: 'минут',
                                ),
                              ),
                              Expanded(
                                child: InfoItem(
                                  icon: Icons.check_circle,
                                  title: '${(_course.progress * 100).toInt()}%',
                                  subtitle: 'выполнено',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: _course.progress,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(_course.color),
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Прогресс: ${(_course.progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.equalizer, color: Colors.grey[700], size: 18),
                              const SizedBox(width: 4),
                              Text(
                                _course.difficulty,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rate_rounded,
                                size: 20,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _course.difficulty,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Кнопка подписки на курс
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              text: _course.isSubscribed 
                                ? 'Вы записаны'
                                : 'Подписаться на курс',
                              onPressed: (_isSubscriptionLoading || _course.isSubscribed)
                                ? null
                                : _toggleSubscription,
                              type: _course.isSubscribed
                                ? AppButtonType.secondary
                                : AppButtonType.primary,
                              isLoading: _isSubscriptionLoading,
                              backgroundColor: _course.isSubscribed
                                ? Colors.grey[400]
                                : null,
                              textColor: _course.isSubscribed
                                ? Colors.white
                                : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 24),
                  
                  // Заголовок уроков
                  Text(
                    'Уроки',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Список уроков
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final lesson = _course.lessons[index];
                return LessonCard(
                  lesson: lesson,
                  courseColor: _course.color,
                  onToggleCompletion: (isCompleted) {
                    _toggleLessonCompletion(lesson.id, isCompleted);
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LessonScreen(
                          lesson: lesson,
                          course: _course,
                        ),
                      ),
                    ).then((_) async {
                      final updatedCourse = await _courseService.getCourseById(_course.id);
                      if (updatedCourse != null && mounted) {
                        setState(() {
                          _course = updatedCourse;
                        });
                      }
                    });
                  },
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 400 + index * 100),
                  duration: 300.ms,
                ).slideY(begin: 0.1, end: 0);
              },
              childCount: _course.lessons.length,
            ),
          ),
          
          // Нижний отступ
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }
}

class InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  
  const InfoItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.grey[700],
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final Color courseColor;
  final Function(bool) onToggleCompletion;
  final VoidCallback onTap;
  
  const LessonCard({
    super.key,
    required this.lesson,
    required this.courseColor,
    required this.onToggleCompletion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Индикатор выполнения урока
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: lesson.isCompleted 
                      ? courseColor
                      : courseColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  lesson.isCompleted ? Icons.check : Icons.play_arrow,
                  size: 18,
                  color: lesson.isCompleted ? Colors.white : courseColor,
                ),
              ),
              const SizedBox(width: 16),
              
              // Информация об уроке
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Длительность и переключатель выполнения
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${lesson.durationMinutes} мин',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Switch(
                    value: lesson.isCompleted,
                    onChanged: onToggleCompletion,
                    activeColor: courseColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 