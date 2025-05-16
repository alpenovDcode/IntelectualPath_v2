import 'package:equatable/equatable.dart';

enum ExerciseType {
  quiz,           // Тест с выбором ответа
  game,           // Мини-игра
  exercise,       // Практическое задание
  matching,       // Сопоставление элементов
  fillInBlanks,   // Заполнение пропусков
  dragAndDrop,    // Перетаскивание элементов
  codeChallenge,  // Задание по программированию
  discussion,     // Обсуждение
  caseStudy,      // Разбор кейса
}

class InteractiveExercise extends Equatable {
  final String id;
  final String title;
  final String description;
  final ExerciseType type;
  final Map<String, dynamic> content;
  final bool isCompleted;
  final int points;
  final int timeLimit; // в секундах, 0 если без ограничения
  final List<String> tags;
  final Map<String, dynamic>? userAnswer;
  final DateTime? completedAt;

  const InteractiveExercise({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.content,
    this.isCompleted = false,
    this.points = 10,
    this.timeLimit = 0,
    this.tags = const [],
    this.userAnswer,
    this.completedAt,
  });

  InteractiveExercise copyWith({
    String? id,
    String? title,
    String? description,
    ExerciseType? type,
    Map<String, dynamic>? content,
    bool? isCompleted,
    int? points,
    int? timeLimit,
    List<String>? tags,
    Map<String, dynamic>? userAnswer,
    DateTime? completedAt,
  }) {
    return InteractiveExercise(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      content: content ?? this.content,
      isCompleted: isCompleted ?? this.isCompleted,
      points: points ?? this.points,
      timeLimit: timeLimit ?? this.timeLimit,
      tags: tags ?? this.tags,
      userAnswer: userAnswer ?? this.userAnswer,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        content,
        isCompleted,
        points,
        timeLimit,
        tags,
        userAnswer,
        completedAt,
      ];
} 