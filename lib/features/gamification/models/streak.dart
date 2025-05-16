import 'package:flutter/material.dart';

class Streak {
  final int currentStreak;
  final int longestStreak;
  final DateTime lastLoginDate;

  Streak({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastLoginDate,
  });

  Streak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLoginDate,
  }) {
    return Streak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
    );
  }
} 