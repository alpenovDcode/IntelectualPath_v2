// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseModel _$CourseModelFromJson(Map<String, dynamic> json) => CourseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      difficulty: (json['difficulty'] as num).toInt(),
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalExperience: (json['totalExperience'] as num).toInt(),
      requirements: json['requirements'] as Map<String, dynamic>? ?? const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CourseModelToJson(CourseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'category': instance.category,
      'difficulty': instance.difficulty,
      'lessons': instance.lessons,
      'totalExperience': instance.totalExperience,
      'requirements': instance.requirements,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

LessonModel _$LessonModelFromJson(Map<String, dynamic> json) => LessonModel(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      order: (json['order'] as num).toInt(),
      experienceReward: (json['experienceReward'] as num).toInt(),
      content: json['content'] as Map<String, dynamic>,
      estimatedDuration:
          Duration(microseconds: (json['estimatedDuration'] as num).toInt()),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$LessonModelToJson(LessonModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'courseId': instance.courseId,
      'title': instance.title,
      'description': instance.description,
      'type': instance.type,
      'order': instance.order,
      'experienceReward': instance.experienceReward,
      'content': instance.content,
      'estimatedDuration': instance.estimatedDuration.inMicroseconds,
      'tags': instance.tags,
      'metadata': instance.metadata,
    };
