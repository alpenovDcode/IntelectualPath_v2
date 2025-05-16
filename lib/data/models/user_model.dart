import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String username;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final int experiencePoints;
  final int level;
  final List<String> completedLessons;
  final List<String> achievements;
  final Map<String, int> courseProgress;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.experiencePoints = 0,
    this.level = 1,
    this.completedLessons = const [],
    this.achievements = const [],
    this.courseProgress = const {},
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? experiencePoints,
    int? level,
    List<String>? completedLessons,
    List<String>? achievements,
    Map<String, int>? courseProgress,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      level: level ?? this.level,
      completedLessons: completedLessons ?? this.completedLessons,
      achievements: achievements ?? this.achievements,
      courseProgress: courseProgress ?? this.courseProgress,
    );
  }

  // Бизнес-логика для работы с пользователем

  /// Вычисляет необходимый опыт для следующего уровня
  int getNextLevelExperience() {
    return 100 * level; // Простая формула, можно усложнить
  }

  /// Проверка, может ли пользователь повысить уровень
  bool canLevelUp() {
    return experiencePoints >= getNextLevelExperience();
  }

  /// Добавление опыта пользователю
  UserModel addExperience(int amount) {
    final newExperience = experiencePoints + amount;
    var newLevel = level;
    
    // Проверка на повышение уровня
    while (newExperience >= getNextLevelExperience()) {
      newLevel++;
    }
    
    return copyWith(
      experiencePoints: newExperience,
      level: newLevel,
    );
  }

  /// Добавление завершенного урока
  UserModel completeLesson(String lessonId) {
    if (completedLessons.contains(lessonId)) {
      return this;
    }
    
    final updatedLessons = List<String>.from(completedLessons)..add(lessonId);
    return copyWith(completedLessons: updatedLessons);
  }

  /// Обновление прогресса курса
  UserModel updateCourseProgress(String courseId, int progress) {
    final updatedProgress = Map<String, int>.from(courseProgress);
    updatedProgress[courseId] = progress;
    
    return copyWith(courseProgress: updatedProgress);
  }
} 