import '../models/course.dart';
import '../../auth/models/user.dart';

class RecommendationService {
  /// Получить персональные рекомендации курсов для пользователя
  List<Course> getRecommendedCourses({
    required User user,
    required List<Course> allCourses,
    List<String> userInterests = const [],
    List<String> completedCourseIds = const [],
  }) {
    // 1. Курсы по интересам пользователя
    final interestCourses = allCourses.where((course) =>
      course.tags.any((tag) => userInterests.contains(tag))
    ).toList();

    // 2. Новые и популярные курсы (например, по рейтингу)
    final popularCourses = List<Course>.from(allCourses)
      ..sort((a, b) => b.ratingAverage.compareTo(a.ratingAverage));

    // 3. Курсы, которые пользователь ещё не проходил
    final notCompleted = allCourses.where((c) => !completedCourseIds.contains(c.id)).toList();

    // 4. Собираем рекомендации: сначала по интересам, затем популярные, затем новые
    final recommendations = <Course>[];
    recommendations.addAll(interestCourses);
    recommendations.addAll(popularCourses);
    recommendations.addAll(notCompleted);

    // Убираем дубликаты и возвращаем топ-5
    final unique = <String, Course>{};
    for (final course in recommendations) {
      unique[course.id] = course;
    }
    return unique.values.take(5).toList();
  }
} 