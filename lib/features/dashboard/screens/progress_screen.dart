import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user.dart';
import '../../courses/models/course.dart';
import '../../courses/services/course_service.dart';
import '../../courses/screens/course_detail_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  ProgressScreenState createState() => ProgressScreenState();
}

class ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CourseService _courseService = CourseService();
  List<Course> _courses = [];
  bool _isLoading = true;
  int _completedLessons = 0;
  int _totalLessons = 0;
  double _overallProgress = 0.0;
  Map<String, int> _categoryCompletionMap = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadUserProgress();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> loadUserProgress() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticatedState) {
        final userId = authState.user.id;
        
        // Важно: сначала обновляем все данные в сервисе
        await _courseService.getCoursesWithSubscriptionStatus(userId);
        await Future.delayed(const Duration(milliseconds: 100)); // Небольшая задержка для обработки
        
        // Получаем только курсы, на которые подписан пользователь
        final subscribedCourses = await _courseService.getUserSubscribedCourses(userId);
        
        // Явно проверяем, если список подписок пуст, повторяем запрос
        if (subscribedCourses.isEmpty) {
          // Возможно данные еще не обновились, повторяем запрос
          await Future.delayed(const Duration(milliseconds: 300));
          await _courseService.getCoursesWithSubscriptionStatus(userId);
          final retriedSubscribedCourses = await _courseService.getUserSubscribedCourses(userId);
          
          // Используем повторно полученные данные, если они есть
          if (retriedSubscribedCourses.isNotEmpty) {
            setState(() {
              _courses = retriedSubscribedCourses;
              _completedLessons = _calculateCompletedLessons(retriedSubscribedCourses);
              _totalLessons = _calculateTotalLessons(retriedSubscribedCourses);
              _overallProgress = _totalLessons > 0 ? _completedLessons / _totalLessons : 0;
              _categoryCompletionMap = _calculateCategoryCompletion(retriedSubscribedCourses);
              _isLoading = false;
            });
            return;
          }
        }
        
        // Получаем прогресс пользователя для всех курсов
        final allCourses = await _courseService.getUserCourses(userId);
        
        // Фильтруем курсы, оставляя только те, на которые подписан пользователь
        final userSubscribedCourses = allCourses.where((course) => 
          subscribedCourses.any((subscribedCourse) => subscribedCourse.id == course.id) || course.isSubscribed
        ).toList();
        
        if (userSubscribedCourses.isEmpty && subscribedCourses.isNotEmpty) {
          // Если фильтрация не дала результатов, но подписки есть - используем их напрямую
          setState(() {
            _courses = subscribedCourses;
            _completedLessons = _calculateCompletedLessons(subscribedCourses);
            _totalLessons = _calculateTotalLessons(subscribedCourses);
            _overallProgress = _totalLessons > 0 ? _completedLessons / _totalLessons : 0;
            _categoryCompletionMap = _calculateCategoryCompletion(subscribedCourses);
            _isLoading = false;
          });
          return;
        }
        
        if (mounted) {
          setState(() {
            _courses = userSubscribedCourses;
            _completedLessons = _calculateCompletedLessons(userSubscribedCourses);
            _totalLessons = _calculateTotalLessons(userSubscribedCourses);
            _overallProgress = _totalLessons > 0 ? _completedLessons / _totalLessons : 0;
            _categoryCompletionMap = _calculateCategoryCompletion(userSubscribedCourses);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Ошибка при загрузке прогресса: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Вспомогательный метод для подсчета выполненных уроков
  int _calculateCompletedLessons(List<Course> courses) {
    return courses.fold(0, (total, course) => total + course.completedLessons);
  }
  
  // Вспомогательный метод для подсчета всех уроков
  int _calculateTotalLessons(List<Course> courses) {
    return courses.fold(0, (total, course) => total + course.lessons.length);
  }
  
  // Вспомогательный метод для подсчета статистики по категориям
  Map<String, int> _calculateCategoryCompletion(List<Course> courses) {
    Map<String, int> categoryCompletion = {};
    
    for (final course in courses) {
      final category = course.category;
      if (categoryCompletion.containsKey(category)) {
        categoryCompletion[category] = (categoryCompletion[category] ?? 0) + course.completedLessons;
      } else {
        categoryCompletion[category] = course.completedLessons;
      }
    }
    
    return categoryCompletion;
  }
  
  List<PieChartSectionData> _generatePieChartSections() {
    final List<Color> categoryColors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.red,
    ];
    
    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    
    _categoryCompletionMap.forEach((category, count) {
      if (count > 0) {
        sections.add(
          PieChartSectionData(
            color: categoryColors[colorIndex % categoryColors.length],
            value: count.toDouble(),
            title: category,
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
        colorIndex++;
      }
    });
    
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: loadUserProgress,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ваш прогресс',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(duration: 300.ms),
                        
                        const SizedBox(height: 24),
                        
                        // Общая статистика
                        _buildOverallProgressCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Табы для переключения между графиками и списком курсов
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Статистика'),
                            Tab(text: 'Курсы'),
                          ],
                          labelColor: AppTheme.primaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: AppTheme.primaryColor,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildStatisticsTab(),
                              _buildCoursesProgressTab(),
                            ],
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
  
  Widget _buildOverallProgressCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Общий прогресс',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_overallProgress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Выполнено $_completedLessons из $_totalLessons уроков',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: _overallProgress,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '${(_overallProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _overallProgress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
  
  Widget _buildStatisticsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // График по категориям
        Card(
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
                  'Статистика по категориям',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _categoryCompletionMap.isEmpty || _completedLessons == 0
                    ? const Center(
                        child: Text(
                          'Нет данных для отображения',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 250,
                        child: PieChart(
                          PieChartData(
                            sections: _generatePieChartSections(),
                            centerSpaceRadius: 40,
                            sectionsSpace: 0,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 200.ms),
        
        const SizedBox(height: 24),
        
        // Легенда
        if (_categoryCompletionMap.isNotEmpty && _completedLessons > 0)
          Card(
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
                    'Распределение по категориям',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._categoryCompletionMap.entries.map((entry) {
                    final percentage = _completedLessons > 0
                        ? (entry.value / _completedLessons * 100).toStringAsFixed(1)
                        : '0.0';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('$percentage% (${entry.value} уроков)'),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }
  
  Widget _buildCoursesProgressTab() {
    return _courses.isEmpty
        ? const Center(
            child: Text(
              'У вас пока нет курсов',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          )
        : ListView.builder(
            itemCount: _courses.length,
            itemBuilder: (context, index) {
              final course = _courses[index];
              return CourseProgressCard(
                course: course,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailScreen(course: course),
                    ),
                  ).then((_) => loadUserProgress());
                },
              ).animate().fadeIn(
                delay: Duration(milliseconds: 100 + index * 50),
                duration: 300.ms,
              );
            },
          );
  }
}

class CourseProgressCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  
  const CourseProgressCard({
    super.key,
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  const SizedBox(width: 16),
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
                          '${course.completedLessons}/${course.lessons.length} уроков завершено',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(course.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: course.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: course.progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(course.color),
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    course.difficulty,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Последнее обновление: ${DateFormat('dd.MM.yyyy').format(course.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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