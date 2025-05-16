import 'package:json_annotation/json_annotation.dart';

part 'course_model.g.dart';

@JsonSerializable()
class CourseModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final int difficulty; // 1-5, где 1 - самый простой, 5 - самый сложный
  final List<LessonModel> lessons;
  final int totalExperience; // Сколько опыта можно получить за весь курс
  final Map<String, dynamic> requirements; // Предварительные требования для курса
  final DateTime createdAt;
  final DateTime updatedAt;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.difficulty,
    this.lessons = const [],
    required this.totalExperience,
    this.requirements = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => _$CourseModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$CourseModelToJson(this);

  // Бизнес-логика для работы с курсами

  /// Вычисляет общее количество уроков в курсе
  int get lessonCount => lessons.length;

  /// Вычисляет средний опыт за урок
  double get averageExperiencePerLesson => 
      lessonCount > 0 ? totalExperience / lessonCount : 0;

  /// Проверяет, может ли пользователь с указанным уровнем начать курс
  bool isAvailableForLevel(int userLevel) {
    final requiredLevel = requirements['level'] as int? ?? 1;
    return userLevel >= requiredLevel;
  }

  /// Получает следующий неоконченный урок для пользователя
  LessonModel? getNextLessonFor(List<String> completedLessonIds) {
    for (final lesson in lessons) {
      if (!completedLessonIds.contains(lesson.id)) {
        return lesson;
      }
    }
    return null;
  }

  /// Вычисляет процент прохождения курса
  double getCompletionPercentage(List<String> completedLessonIds) {
    if (lessonCount == 0) return 0.0;
    
    int completedCount = 0;
    for (final lesson in lessons) {
      if (completedLessonIds.contains(lesson.id)) {
        completedCount++;
      }
    }
    
    return (completedCount / lessonCount) * 100;
  }
}

@JsonSerializable()
class LessonModel {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String type; // 'theory', 'exercise', 'quiz', 'interactive'
  final int order; // Порядок урока в курсе
  final int experienceReward;
  final Map<String, dynamic> content; // Контент урока в зависимости от типа
  final Duration estimatedDuration;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.type,
    required this.order,
    required this.experienceReward,
    required this.content,
    required this.estimatedDuration,
    this.tags = const [],
    this.metadata = const {},
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) => _$LessonModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$LessonModelToJson(this);

  // Бизнес-логика для уроков

  /// Проверяет, является ли урок интерактивным
  bool get isInteractive => type == 'interactive';

  /// Проверяет, является ли урок тестом/квизом
  bool get isQuiz => type == 'quiz';

  /// Получает список вопросов, если урок является тестом
  List<Map<String, dynamic>> getQuizQuestions() {
    if (!isQuiz) return [];
    return (content['questions'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  /// Проверяет, является ли урок теоретическим
  bool get isTheory => type == 'theory';

  /// Получает содержимое теоретического урока
  String getTheoryContent() {
    if (!isTheory) return '';
    return content['text'] as String? ?? '';
  }
} 