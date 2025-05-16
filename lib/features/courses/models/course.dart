import 'dart:convert';
import 'package:flutter/material.dart';

class Lesson {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final bool isCompleted;
  final String content;
  final String? videoUrl;
  final String? audioUrl;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    this.isCompleted = false,
    this.content = '',
    this.videoUrl,
    this.audioUrl,
  });

  Lesson copyWith({
    String? id,
    String? title,
    String? description,
    int? durationMinutes,
    bool? isCompleted,
    String? content,
    String? videoUrl,
    String? audioUrl,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      content: content ?? this.content,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'isCompleted': isCompleted,
      'content': content,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
    };
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      durationMinutes: json['durationMinutes'],
      isCompleted: json['isCompleted'] ?? false,
      content: json['content'] ?? '',
      videoUrl: json['videoUrl'],
      audioUrl: json['audioUrl'],
    );
  }
}

class Module {
  final String id;
  final String title;
  final List<Lesson> lessons;
  final List<Task> tasks;
  final List<Quiz> quizzes;

  Module({
    required this.id,
    required this.title,
    required this.lessons,
    this.tasks = const [],
    this.quizzes = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'lessons': lessons.map((l) => l.toJson()).toList(),
    'tasks': tasks.map((t) => t.toJson()).toList(),
    'quizzes': quizzes.map((q) => q.toJson()).toList(),
  };

  factory Module.fromJson(Map<String, dynamic> json) => Module(
    id: json['id'],
    title: json['title'],
    lessons: (json['lessons'] as List?)?.map((l) => Lesson.fromJson(l)).toList() ?? [],
    tasks: (json['tasks'] as List?)?.map((t) => Task.fromJson(t)).toList() ?? [],
    quizzes: (json['quizzes'] as List?)?.map((q) => Quiz.fromJson(q)).toList() ?? [],
  );
}

class Task {
  final String id;
  final String question;
  final String type; // e.g. 'text', 'choice', 'dragdrop', etc.
  final List<String>? options;
  final String? correctAnswer;

  Task({
    required this.id,
    required this.question,
    required this.type,
    this.options,
    this.correctAnswer,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'type': type,
    'options': options,
    'correctAnswer': correctAnswer,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    question: json['question'],
    type: json['type'],
    options: (json['options'] as List?)?.map((e) => e.toString()).toList(),
    correctAnswer: json['correctAnswer'],
  );
}

class Quiz {
  final String id;
  final String title;
  final List<Task> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.questions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'questions': questions.map((q) => q.toJson()).toList(),
  };

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
    id: json['id'],
    title: json['title'],
    questions: (json['questions'] as List?)?.map((q) => Task.fromJson(q)).toList() ?? [],
  );
}

class Course {
  final String id;
  final String title;
  final String description;
  final List<Module> modules;
  final String? videoUrl;
  final String? audioUrl;
  final List<String> tags;
  final int durationMinutes;
  final int points;
  final List<String> achievements;
  final String? imageUrl;
  final IconData icon;
  final Color color;
  final int totalLessons;
  final int completedLessons;
  final double progress;
  final int lessonsCount;
  final double ratingAverage;
  final int ratingCount;
  final String difficulty;
  final bool isSubscribed;
  final DateTime createdAt;
  final String category;
  final int price;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.modules,
    this.videoUrl,
    this.audioUrl,
    this.tags = const [],
    this.durationMinutes = 0,
    this.points = 0,
    this.achievements = const [],
    this.imageUrl,
    required this.icon,
    required this.color,
    this.totalLessons = 0,
    this.completedLessons = 0,
    this.progress = 0.0,
    required this.lessonsCount,
    required this.ratingAverage,
    required this.ratingCount,
    this.difficulty = 'Средний уровень',
    this.isSubscribed = false,
    DateTime? createdAt,
    this.category = 'Общее',
    this.price = 0,
  }) : this.createdAt = createdAt ?? DateTime.now();

  Course copyWith({
    String? id,
    String? title,
    String? description,
    List<Module>? modules,
    String? videoUrl,
    String? audioUrl,
    List<String>? tags,
    int? durationMinutes,
    int? points,
    List<String>? achievements,
    String? imageUrl,
    IconData? icon,
    Color? color,
    int? totalLessons,
    int? completedLessons,
    double? progress,
    int? lessonsCount,
    double? ratingAverage,
    int? ratingCount,
    String? difficulty,
    bool? isSubscribed,
    DateTime? createdAt,
    String? category,
    int? price,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      modules: modules ?? this.modules,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      tags: tags ?? this.tags,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      points: points ?? this.points,
      achievements: achievements ?? this.achievements,
      imageUrl: imageUrl ?? this.imageUrl,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      totalLessons: totalLessons ?? this.totalLessons,
      completedLessons: completedLessons ?? this.completedLessons,
      progress: progress ?? this.progress,
      lessonsCount: lessonsCount ?? this.lessonsCount,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
      difficulty: difficulty ?? this.difficulty,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      price: price ?? this.price,
    );
  }

  // Для сериализации иконок и цветов используем их строковые представления
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'modules': modules.map((module) => module.toJson()).toList(),
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'tags': tags,
      'durationMinutes': durationMinutes,
      'points': points,
      'achievements': achievements,
      'imageUrl': imageUrl,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'color': color.value,
      'lessonsCount': lessonsCount,
      'ratingAverage': ratingAverage,
      'ratingCount': ratingCount,
      'difficulty': difficulty,
      'isSubscribed': isSubscribed,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'price': price,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    final modulesList = (json['modules'] as List?)?.map((module) => Module.fromJson(module)).toList() ?? [];

    return Course(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      modules: modulesList,
      videoUrl: json['videoUrl'],
      audioUrl: json['audioUrl'],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      achievements: (json['achievements'] as List?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: json['imageUrl'],
      icon: IconData(
        json['iconCodePoint'],
        fontFamily: json['iconFontFamily'],
      ),
      color: Color(json['color']),
      totalLessons: modulesList.fold<int>(0, (sum, module) => sum + (module.lessons?.length ?? 0)),
      completedLessons: modulesList.fold<int>(0, (sum, module) => sum + (module.lessons?.where((lesson) => lesson.isCompleted).length ?? 0)),
      progress: modulesList.isEmpty
          ? 0.0
          : modulesList.fold<int>(0, (sum, module) => sum + (module.lessons?.where((lesson) => lesson.isCompleted).length ?? 0)) /
            modulesList.fold<int>(0, (sum, module) => sum + (module.lessons?.length ?? 0)),
      lessonsCount: json['lessonsCount'] as int,
      ratingAverage: (json['ratingAverage'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      difficulty: json['difficulty'] as String? ?? 'Средний уровень',
      isSubscribed: json['isSubscribed'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      category: json['category'] as String? ?? 'Общее',
      price: json['price'] as int? ?? 0,
    );
  }
  
  // Вспомогательные методы
  bool get isFree => price == 0;
  String get formattedPrice => isFree ? 'Бесплатно' : '$price ₽';
  bool get isNew => DateTime.now().difference(createdAt).inDays < 30;
  
  /// Возвращает числовое значение сложности от 1 до 3
  int get difficultyLevel {
    switch (difficulty.toLowerCase()) {
      case 'легкий уровень':
        return 1;
      case 'средний уровень':
        return 2;
      case 'продвинутый уровень':
        return 3;
      default:
        return 2; // По умолчанию средний уровень
    }
  }

  /// Геттер для получения всех уроков курса (из всех модулей)
  List<Lesson> get lessons => modules.expand((m) => m.lessons).toList();
} 