class DailyTask {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final int reward;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.reward,
  });

  DailyTask copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    int? reward,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      reward: reward ?? this.reward,
    );
  }
} 