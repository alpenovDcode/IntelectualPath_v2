import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../config/theme.dart';
import '../../../widgets/buttons.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../interactive/models/interactive_exercise.dart';
import '../../interactive/services/interactive_service.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final Course course;
  
  const LessonScreen({
    super.key,
    required this.lesson,
    required this.course,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool _isCompleted = false;
  final CourseService _courseService = CourseService();
  final InteractiveService _interactiveService = InteractiveService();
  bool _isLoading = true;
  List<InteractiveExercise> _exercises = [];
  
  @override
  void initState() {
    super.initState();
    _isCompleted = widget.lesson.isCompleted;
    loadExercises();
  }
  
  Future<void> _markAsCompleted() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticatedState) {
        final userId = authState.user.id;
        await _courseService.updateLessonProgress(
          userId,
          widget.course.id,
          widget.lesson.id,
          true,
        );
        
        setState(() {
          _isCompleted = true;
        });
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
  
  Future<void> loadExercises() async {
    final exercises = await _interactiveService.getExercisesForLesson(widget.lesson.id);
    setState(() {
      _exercises = exercises;
      _isLoading = false;
    });
  }

  Future<void> _completeExercise(String exerciseId) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticatedState) {
      await _interactiveService.completeExercise(authState.user.id, exerciseId);
      setState(() {
        _exercises = _exercises.map((exercise) {
          if (exercise.id == exerciseId) {
            return exercise.copyWith(isCompleted: true);
          }
          return exercise;
        }).toList();
      });
    }
  }

  Widget _buildExerciseCard(InteractiveExercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getExerciseIcon(exercise.type),
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exercise.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (exercise.isCompleted)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              exercise.description,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (!exercise.isCompleted)
              AppButton(
                onPressed: () => _showExerciseDialog(exercise),
                text: 'Начать упражнение',
                type: AppButtonType.primary,
              ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  IconData _getExerciseIcon(ExerciseType type) {
    switch (type) {
      case ExerciseType.quiz:
        return Icons.quiz;
      case ExerciseType.matching:
        return Icons.compare_arrows;
      case ExerciseType.fillInBlanks:
        return Icons.edit;
      case ExerciseType.dragAndDrop:
        return Icons.drag_indicator;
      case ExerciseType.codeChallenge:
        return Icons.code;
      case ExerciseType.discussion:
        return Icons.forum;
      case ExerciseType.caseStudy:
        return Icons.analytics;
      default:
        return Icons.assignment;
    }
  }

  void _showExerciseDialog(InteractiveExercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exercise.title),
        content: _buildExerciseContent(exercise),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          if (!exercise.isCompleted)
            TextButton(
              onPressed: () {
                _completeExercise(exercise.id);
                Navigator.pop(context);
              },
              child: const Text('Завершить'),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseContent(InteractiveExercise exercise) {
    switch (exercise.type) {
      case ExerciseType.quiz:
        return _buildQuizContent(exercise);
      case ExerciseType.matching:
        return _buildMatchingContent(exercise);
      case ExerciseType.fillInBlanks:
        return _buildFillInBlanksContent(exercise);
      case ExerciseType.dragAndDrop:
        return _buildDragAndDropContent(exercise);
      case ExerciseType.codeChallenge:
        return _buildCodeChallengeContent(exercise);
      case ExerciseType.discussion:
        return _buildDiscussionContent(exercise);
      case ExerciseType.caseStudy:
        return _buildCaseStudyContent(exercise);
      default:
        return const Text('Неизвестный тип упражнения');
    }
  }

  Widget _buildQuizContent(InteractiveExercise exercise) {
    final questions = exercise.content['questions'] as List;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: questions.map<Widget>((question) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question['question'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                (question['options'] as List).length,
                (index) => RadioListTile(
                  title: Text(question['options'][index]),
                  value: index,
                  groupValue: null, // TODO: Добавить состояние для выбранного ответа
                  onChanged: (value) {
                    // TODO: Обработка выбора ответа
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMatchingContent(InteractiveExercise exercise) {
    final pairs = exercise.content['pairs'] as List;
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            'Сопоставьте термины с их определениями',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            pairs.length,
            (index) => Card(
              child: ListTile(
                title: Text(pairs[index]['term']),
                subtitle: Text(pairs[index]['definition']),
                trailing: IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: () {
                    // TODO: Реализовать логику перетаскивания
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFillInBlanksContent(InteractiveExercise exercise) {
    final text = exercise.content['text'] as String;
    final answers = exercise.content['answers'] as List;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Заполните пропуски в тексте',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(
            text.replaceAll('[', '').replaceAll(']', '_____'),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            answers.length,
            (index) => TextField(
              decoration: InputDecoration(
                labelText: 'Ответ ${index + 1}',
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                // TODO: Сохранить ответ
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragAndDropContent(InteractiveExercise exercise) {
    final items = exercise.content['items'] as List;
    
    return Column(
      children: [
        const Text(
          'Расположите элементы в правильном порядке',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        ReorderableListView(
          shrinkWrap: true,
          children: items.map<Widget>((item) {
            return Card(
              key: ValueKey(item),
              child: ListTile(
                title: Text(item),
                leading: const Icon(Icons.drag_handle),
              ),
            );
          }).toList(),
          onReorder: (oldIndex, newIndex) {
            // TODO: Обновить порядок элементов
          },
        ),
      ],
    );
  }

  Widget _buildCodeChallengeContent(InteractiveExercise exercise) {
    final description = exercise.content['description'] as String;
    final template = exercise.content['template'] as String;
    final testCases = exercise.content['testCases'] as List;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              maxLines: 10,
              controller: TextEditingController(text: template),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Тестовые случаи:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...testCases.map<Widget>((testCase) {
            return Card(
              child: ListTile(
                title: Text('Вход: ${testCase['input']}'),
                subtitle: Text('Ожидаемый выход: ${testCase['output']}'),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          AppButton(
            text: 'Запустить тесты',
            onPressed: () {
              // TODO: Реализовать запуск тестов
            },
            type: AppButtonType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionContent(InteractiveExercise exercise) {
    final topic = exercise.content['topic'] as String;
    final questions = exercise.content['questions'] as List;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            topic,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...questions.map<Widget>((question) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Введите ваш ответ...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // TODO: Сохранить ответ
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCaseStudyContent(InteractiveExercise exercise) {
    final scenario = exercise.content['scenario'] as String;
    final data = exercise.content['data'] as Map<String, dynamic>;
    final questions = exercise.content['questions'] as List;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scenario,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Данные:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...data.entries.map<Widget>((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${entry.key}: ${entry.value}'),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...questions.map<Widget>((question) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Введите ваш ответ...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // TODO: Сохранить ответ
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final String lessonContent = widget.lesson.content.isNotEmpty 
        ? widget.lesson.content 
        : """
# ${widget.lesson.title}

## Описание
${widget.lesson.description}

### Содержание материала
Это демонстрационный урок. Настоящий образовательный контент будет добавлен позже.

- Пункт 1
- Пункт 2
- Пункт 3

**Важно**: Не забудьте отметить урок как завершенный после изучения.
""";
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: widget.course.color,
        foregroundColor: Colors.white,
        actions: [
          if (_isCompleted)
            Icon(
              Icons.check_circle,
              color: Colors.white,
            ).animate().fadeIn(),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Содержимое урока
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Информация о уроке
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: widget.course.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: widget.course.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Продолжительность: ${widget.lesson.durationMinutes} минут',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.course.color,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  
                  const SizedBox(height: 24),
                  
                  // Содержимое урока в формате Markdown
                  MarkdownBody(
                    data: lessonContent,
                    styleSheet: MarkdownStyleSheet(
                      h1: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.course.color,
                      ),
                      h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.course.color,
                      ),
                      h3: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      p: Theme.of(context).textTheme.bodyLarge,
                      blockquote: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                      code: const TextStyle(
                        fontFamily: 'monospace',
                        backgroundColor: Color(0xFFEEEEEE),
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
          
          // Кнопка "Завершить урок"
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: AppButton(
              text: _isCompleted ? 'Урок завершен' : 'Завершить урок',
              onPressed: _isCompleted ? null : _markAsCompleted,
              isLoading: _isLoading,
              type: AppButtonType.primary,
              icon: _isCompleted ? Icons.check : Icons.flag,
              backgroundColor: widget.course.color,
            ),
          ),
        ],
      ),
    );
  }
} 