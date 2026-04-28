/// Statistics Data Models - Member 5
/// Contains all data structures for study statistics and analytics

class StudyStatistics {
  final int totalNotes;
  final int totalFlashcards;
  final int totalSummaries;
  final int totalStudyTime; // in minutes
  final DateTime lastStudyDate;

  StudyStatistics({
    required this.totalNotes,
    required this.totalFlashcards,
    required this.totalSummaries,
    required this.totalStudyTime,
    required this.lastStudyDate,
  });

  factory StudyStatistics.empty() {
    return StudyStatistics(
      totalNotes: 0,
      totalFlashcards: 0,
      totalSummaries: 0,
      totalStudyTime: 0,
      lastStudyDate: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalNotes': totalNotes,
      'totalFlashcards': totalFlashcards,
      'totalSummaries': totalSummaries,
      'totalStudyTime': totalStudyTime,
      'lastStudyDate': lastStudyDate.toIso8601String(),
    };
  }

  factory StudyStatistics.fromMap(Map<String, dynamic> map) {
    return StudyStatistics(
      totalNotes: map['totalNotes'] as int? ?? 0,
      totalFlashcards: map['totalFlashcards'] as int? ?? 0,
      totalSummaries: map['totalSummaries'] as int? ?? 0,
      totalStudyTime: map['totalStudyTime'] as int? ?? 0,
      lastStudyDate: map['lastStudyDate'] != null
          ? DateTime.parse(map['lastStudyDate'] as String)
          : DateTime.now(),
    );
  }
}

/// Daily Study Activity Data
class DailyStudyData {
  final String date; // Format: YYYY-MM-DD
  final int studyTimeMinutes;
  final int cardsReviewed;
  final int notesCreated;

  DailyStudyData({
    required this.date,
    required this.studyTimeMinutes,
    required this.cardsReviewed,
    required this.notesCreated,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'studyTimeMinutes': studyTimeMinutes,
      'cardsReviewed': cardsReviewed,
      'notesCreated': notesCreated,
    };
  }

  factory DailyStudyData.fromMap(Map<String, dynamic> map) {
    return DailyStudyData(
      date: map['date'] as String? ?? '',
      studyTimeMinutes: map['studyTimeMinutes'] as int? ?? 0,
      cardsReviewed: map['cardsReviewed'] as int? ?? 0,
      notesCreated: map['notesCreated'] as int? ?? 0,
    );
  }
}

/// Flashcard Performance Metrics
class FlashcardPerformance {
  final int totalReviews;
  final String averageReviews; // Formatted to 2 decimal places
  final int markedCards;
  final String averageDifficulty; // Formatted to 1 decimal place
  final Map<int, int> difficultyDistribution; // difficulty level -> count

  FlashcardPerformance({
    required this.totalReviews,
    required this.averageReviews,
    required this.markedCards,
    required this.averageDifficulty,
    required this.difficultyDistribution,
  });

  factory FlashcardPerformance.empty() {
    return FlashcardPerformance(
      totalReviews: 0,
      averageReviews: '0.00',
      markedCards: 0,
      averageDifficulty: '0.0',
      difficultyDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalReviews': totalReviews,
      'averageReviews': averageReviews,
      'markedCards': markedCards,
      'averageDifficulty': averageDifficulty,
      'difficultyDistribution': difficultyDistribution,
    };
  }

  factory FlashcardPerformance.fromMap(Map<String, dynamic> map) {
    final distribution = map['difficultyDistribution'] as Map?;
    return FlashcardPerformance(
      totalReviews: map['totalReviews'] as int? ?? 0,
      averageReviews: map['averageReviews'] as String? ?? '0.00',
      markedCards: map['markedCards'] as int? ?? 0,
      averageDifficulty: map['averageDifficulty'] as String? ?? '0.0',
      difficultyDistribution: distribution != null
          ? Map<int, int>.from(distribution)
          : {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
    );
  }
}

/// Weekly/Monthly Study Summary
class StudySummary {
  final String period; // week, month, all
  final int totalStudyTime; // minutes
  final int daysActive;
  final int averageDailyStudyTime; // minutes
  final String mostActiveDay;
  final int topDayStudyTime; // minutes

  StudySummary({
    required this.period,
    required this.totalStudyTime,
    required this.daysActive,
    required this.averageDailyStudyTime,
    required this.mostActiveDay,
    required this.topDayStudyTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'period': period,
      'totalStudyTime': totalStudyTime,
      'daysActive': daysActive,
      'averageDailyStudyTime': averageDailyStudyTime,
      'mostActiveDay': mostActiveDay,
      'topDayStudyTime': topDayStudyTime,
    };
  }

  factory StudySummary.fromMap(Map<String, dynamic> map) {
    return StudySummary(
      period: map['period'] as String,
      totalStudyTime: map['totalStudyTime'] as int? ?? 0,
      daysActive: map['daysActive'] as int? ?? 0,
      averageDailyStudyTime: map['averageDailyStudyTime'] as int? ?? 0,
      mostActiveDay: map['mostActiveDay'] as String? ?? '',
      topDayStudyTime: map['topDayStudyTime'] as int? ?? 0,
    );
  }
}

/// Achievement/Milestone Data
class StudyAchievement {
  final String id;
  final String title;
  final String description;
  final int value; // e.g., 100 for 100 flashcards reviewed
  final String icon;
  final DateTime achievedAt;
  final bool isUnlocked;

  StudyAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.value,
    required this.icon,
    required this.achievedAt,
    required this.isUnlocked,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'value': value,
      'icon': icon,
      'achievedAt': achievedAt.toIso8601String(),
      'isUnlocked': isUnlocked,
    };
  }

  factory StudyAchievement.fromMap(Map<String, dynamic> map) {
    return StudyAchievement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      value: map['value'] as int? ?? 0,
      icon: map['icon'] as String? ?? '🏆',
      achievedAt: map['achievedAt'] != null
          ? DateTime.parse(map['achievedAt'] as String)
          : DateTime.now(),
      isUnlocked: map['isUnlocked'] as bool? ?? true,
    );
  }
}

/// Quiz Performance Data
class QuizPerformance {
  final String quizId;
  final String quizTitle;
  final int totalQuestions;
  final int correctAnswers;
  final String scorePercentage;
  final DateTime attemptedAt;
  final int timeSpentSeconds;

  QuizPerformance({
    required this.quizId,
    required this.quizTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
    required this.attemptedAt,
    required this.timeSpentSeconds,
  });

  factory QuizPerformance.fromMap(Map<String, dynamic> map) {
    return QuizPerformance(
      quizId: map['quizId'] as String? ?? '',
      quizTitle: map['quizTitle'] as String? ?? '',
      totalQuestions: map['totalQuestions'] as int? ?? 0,
      correctAnswers: map['correctAnswers'] as int? ?? 0,
      scorePercentage: map['scorePercentage'] as String? ?? '0%',
      attemptedAt: map['attemptedAt'] != null
          ? DateTime.parse(map['attemptedAt'] as String)
          : DateTime.now(),
      timeSpentSeconds: map['timeSpentSeconds'] as int? ?? 0,
    );
  }
}

/// Study Pattern Analysis
class StudyPattern {
  final String dayOfWeek; // Monday, Tuesday, etc.
  final int averageStudyTime; // minutes
  final int studySessions;
  final String preferredTime; // Morning, Afternoon, Evening

  StudyPattern({
    required this.dayOfWeek,
    required this.averageStudyTime,
    required this.studySessions,
    required this.preferredTime,
  });
}

/// Subject/Category Performance
class CategoryPerformance {
  final String category;
  final int totalNotes;
  final int totalFlashcards;
  final String averageFlashcardDifficulty;
  final int totalStudyTime; // minutes
  final String performanceScore; // percentage

  CategoryPerformance({
    required this.category,
    required this.totalNotes,
    required this.totalFlashcards,
    required this.averageFlashcardDifficulty,
    required this.totalStudyTime,
    required this.performanceScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'totalNotes': totalNotes,
      'totalFlashcards': totalFlashcards,
      'averageFlashcardDifficulty': averageFlashcardDifficulty,
      'totalStudyTime': totalStudyTime,
      'performanceScore': performanceScore,
    };
  }

  factory CategoryPerformance.fromMap(Map<String, dynamic> map) {
    return CategoryPerformance(
      category: map['category'] as String,
      totalNotes: map['totalNotes'] as int? ?? 0,
      totalFlashcards: map['totalFlashcards'] as int? ?? 0,
      averageFlashcardDifficulty:
          map['averageFlashcardDifficulty'] as String? ?? '0.0',
      totalStudyTime: map['totalStudyTime'] as int? ?? 0,
      performanceScore: map['performanceScore'] as String? ?? '0%',
    );
  }
}

/// Extended study metrics
class ExtendedStudyMetrics {
  final int longestStudyStreak;
  final int currentStudyStreak;
  final String mostProductiveTimeOfDay; // 'morning', 'afternoon', 'evening'
  final String mostProductiveCategory;
  final double averageNotesPerDay;
  final double averageFlashcardsPerDay;

  ExtendedStudyMetrics({
    required this.longestStudyStreak,
    required this.currentStudyStreak,
    required this.mostProductiveTimeOfDay,
    required this.mostProductiveCategory,
    required this.averageNotesPerDay,
    required this.averageFlashcardsPerDay,
  });

  Map<String, dynamic> toMap() {
    return {
      'longestStudyStreak': longestStudyStreak,
      'currentStudyStreak': currentStudyStreak,
      'mostProductiveTimeOfDay': mostProductiveTimeOfDay,
      'mostProductiveCategory': mostProductiveCategory,
      'averageNotesPerDay': averageNotesPerDay,
      'averageFlashcardsPerDay': averageFlashcardsPerDay,
    };
  }

  factory ExtendedStudyMetrics.fromMap(Map<String, dynamic> map) {
    return ExtendedStudyMetrics(
      longestStudyStreak: map['longestStudyStreak'] as int? ?? 0,
      currentStudyStreak: map['currentStudyStreak'] as int? ?? 0,
      mostProductiveTimeOfDay:
          map['mostProductiveTimeOfDay'] as String? ?? 'afternoon',
      mostProductiveCategory:
          map['mostProductiveCategory'] as String? ?? 'General',
      averageNotesPerDay: map['averageNotesPerDay'] as double? ?? 0.0,
      averageFlashcardsPerDay: map['averageFlashcardsPerDay'] as double? ?? 0.0,
    );
  }
}

/// Quick statistics snapshot for dashboard
class StatisticsSnapshot {
  final StudyStatistics overallStats;
  final StudySummary weeklySummary;
  final FlashcardPerformance flashcardPerformance;
  final Map<String, int> categoryBreakdown;
  final List<StudyAchievement> recentAchievements;
  final DateTime generatedAt;

  StatisticsSnapshot({
    required this.overallStats,
    required this.weeklySummary,
    required this.flashcardPerformance,
    required this.categoryBreakdown,
    required this.recentAchievements,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'overallStats': overallStats.toMap(),
      'weeklySummary': weeklySummary.toMap(),
      'flashcardPerformance': flashcardPerformance.toMap(),
      'categoryBreakdown': categoryBreakdown,
      'recentAchievements': recentAchievements.map((a) => a.toMap()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory StatisticsSnapshot.fromMap(Map<String, dynamic> map) {
    return StatisticsSnapshot(
      overallStats: StudyStatistics.fromMap(
        map['overallStats'] as Map<String, dynamic>,
      ),
      weeklySummary: StudySummary.fromMap(
        map['weeklySummary'] as Map<String, dynamic>,
      ),
      flashcardPerformance: FlashcardPerformance.fromMap(
        map['flashcardPerformance'] as Map<String, dynamic>,
      ),
      categoryBreakdown: Map<String, int>.from(map['categoryBreakdown'] as Map),
      recentAchievements: (map['recentAchievements'] as List)
          .map((a) => StudyAchievement.fromMap(a as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(map['generatedAt'] as String),
    );
  }
}
