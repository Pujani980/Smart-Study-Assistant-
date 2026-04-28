import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_study_assistant/models/statistics_model.dart';

/// Statistics Service - Firebase Operations
/// Member 5 Implementation
/// Aggregates data from Notes, Flashcards, and Study sessions

class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StatisticsService._internal();

  factory StatisticsService() {
    return _instance;
  }

  // ==================================================
  // CORE STATISTICS METHODS
  // ==================================================

  /// Get overall study statistics
  /// Aggregates: notes count, flashcards count, study time, summaries
  Future<StudyStatistics> getStudyStatistics(String userId) async {
    try {
      // Get total notes
      final notesQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .count()
          .get();
      final totalNotes = notesQuery.count ?? 0;

      // Get total flashcards
      final flashcardsQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .count()
          .get();
      final totalFlashcards = flashcardsQuery.count ?? 0;

      // Get study stats document
      final statsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('overview')
          .get();

      final totalSummaries = statsDoc.exists
          ? (statsDoc.data()?['totalSummaries'] as int?) ?? 0
          : 0;
      final totalStudyTime = statsDoc.exists
          ? (statsDoc.data()?['totalStudyTime'] as int?) ?? 0
          : 0;

      // Get last study date from notes
      DateTime lastStudyDate = DateTime.now();
      try {
        final lastNoteQuery = await _firestore
            .collection('users')
            .doc(userId)
            .collection('notes')
            .orderBy('updatedAt', descending: true)
            .limit(1)
            .get();

        if (lastNoteQuery.docs.isNotEmpty) {
          final updatedAt = lastNoteQuery.docs.first.data()['updatedAt'];
          if (updatedAt != null) {
            lastStudyDate = (updatedAt as Timestamp).toDate();
          }
        }
      } catch (e) {
        print('Error getting last study date: $e');
      }

      return StudyStatistics(
        totalNotes: totalNotes,
        totalFlashcards: totalFlashcards,
        totalSummaries: totalSummaries,
        totalStudyTime: totalStudyTime,
        lastStudyDate: lastStudyDate,
      );
    } catch (e) {
      print('Error fetching study statistics: $e');
      return StudyStatistics.empty();
    }
  }

  /// Get daily study activity data for specified period
  /// Period: week, month, all
  Future<List<DailyStudyData>> getDailyStudyData(
    String userId,
    String period,
  ) async {
    try {
      final dailyData = <String, DailyStudyData>{};
      DateTime startDate;

      if (period == 'week') {
        startDate = DateTime.now().subtract(const Duration(days: 7));
      } else if (period == 'month') {
        startDate = DateTime.now().subtract(const Duration(days: 30));
      } else {
        // all time - use 3 months as reasonable limit
        startDate = DateTime.now().subtract(const Duration(days: 90));
      }

      // Initialize all days with zero data
      for (
        int i = 0;
        i < (DateTime.now().difference(startDate).inDays + 1);
        i++
      ) {
        final date = startDate.add(Duration(days: i));
        final dateString = _formatDate(date);
        dailyData[dateString] = DailyStudyData(
          date: dateString,
          studyTimeMinutes: 0,
          cardsReviewed: 0,
          notesCreated: 0,
        );
      }

      // Get notes created in period
      final notesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .get();

      for (final noteDoc in notesSnapshot.docs) {
        final data = noteDoc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final dateString = _formatDate(createdAt.toDate());
          if (dailyData.containsKey(dateString)) {
            dailyData[dateString] = DailyStudyData(
              date: dateString,
              studyTimeMinutes: dailyData[dateString]!.studyTimeMinutes,
              cardsReviewed: dailyData[dateString]!.cardsReviewed,
              notesCreated: dailyData[dateString]!.notesCreated + 1,
            );
          }
        }
      }

      // Get flashcard reviews
      final flashcardsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .where('updatedAt', isGreaterThanOrEqualTo: startDate)
          .get();

      for (final cardDoc in flashcardsSnapshot.docs) {
        final data = cardDoc.data();
        final updatedAt = data['updatedAt'] as Timestamp?;
        final timesReviewed = data['timesReviewed'] as int? ?? 0;

        if (updatedAt != null && timesReviewed > 0) {
          final dateString = _formatDate(updatedAt.toDate());
          if (dailyData.containsKey(dateString)) {
            dailyData[dateString] = DailyStudyData(
              date: dateString,
              studyTimeMinutes: dailyData[dateString]!.studyTimeMinutes,
              cardsReviewed:
                  dailyData[dateString]!.cardsReviewed + timesReviewed,
              notesCreated: dailyData[dateString]!.notesCreated,
            );
          }
        }
      }

      // Estimate study time (1 minute per card review, 5 minutes per note)
      for (final key in dailyData.keys) {
        final data = dailyData[key]!;
        final estimatedMinutes = (data.cardsReviewed) + (data.notesCreated * 5);
        dailyData[key] = DailyStudyData(
          date: key,
          studyTimeMinutes: estimatedMinutes,
          cardsReviewed: data.cardsReviewed,
          notesCreated: data.notesCreated,
        );
      }

      return dailyData.values.toList();
    } catch (e) {
      print('Error fetching daily study data: $e');
      return [];
    }
  }

  /// Get note statistics by category
  /// Returns count of notes in each category
  Future<Map<String, int>> getCategoryStatistics(String userId) async {
    try {
      final notesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .get();

      final categoryCount = <String, int>{};

      for (final doc in notesSnapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String? ?? 'Other';
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      return categoryCount;
    } catch (e) {
      print('Error fetching category statistics: $e');
      return {};
    }
  }

  /// Get flashcard performance metrics
  /// Includes total reviews, average difficulty, marked cards
  Future<FlashcardPerformance> getFlashcardPerformance(String userId) async {
    try {
      final flashcardsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .get();

      if (flashcardsSnapshot.docs.isEmpty) {
        return FlashcardPerformance.empty();
      }

      int totalReviews = 0;
      int markedCards = 0;
      double totalDifficulty = 0;
      final difficultyDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final doc in flashcardsSnapshot.docs) {
        final data = doc.data();
        final timesReviewed = data['timesReviewed'] as int? ?? 0;
        final isMarked = data['isMarked'] as bool? ?? false;
        final difficulty = data['difficulty'] as int? ?? 3;

        totalReviews += timesReviewed;
        if (isMarked) markedCards++;
        totalDifficulty += difficulty;
        difficultyDistribution[difficulty] =
            (difficultyDistribution[difficulty] ?? 0) + 1;
      }

      final averageReviews = (totalReviews / flashcardsSnapshot.docs.length)
          .toStringAsFixed(2);
      final averageDifficulty =
          (totalDifficulty / flashcardsSnapshot.docs.length).toStringAsFixed(1);

      return FlashcardPerformance(
        totalReviews: totalReviews,
        averageReviews: averageReviews,
        markedCards: markedCards,
        averageDifficulty: averageDifficulty,
        difficultyDistribution: difficultyDistribution,
      );
    } catch (e) {
      print('Error fetching flashcard performance: $e');
      return FlashcardPerformance.empty();
    }
  }

  // ==================================================
  // ADVANCED STATISTICS METHODS
  // ==================================================

  /// Get weekly study summary
  Future<StudySummary> getWeeklyStudySummary(String userId) async {
    try {
      final startDate = DateTime.now().subtract(const Duration(days: 7));
      final dailyData = await getDailyStudyData(userId, 'week');

      final totalStudyTime = dailyData.fold<int>(
        0,
        (sum, day) => sum + day.studyTimeMinutes,
      );
      final daysActive = dailyData
          .where((day) => day.studyTimeMinutes > 0)
          .length;
      final averageDailyTime = daysActive > 0
          ? totalStudyTime ~/ daysActive
          : 0;

      int maxTime = 0;
      String mostActiveDay = '';
      for (final day in dailyData) {
        if (day.studyTimeMinutes > maxTime) {
          maxTime = day.studyTimeMinutes;
          mostActiveDay = day.date;
        }
      }

      return StudySummary(
        period: 'week',
        totalStudyTime: totalStudyTime,
        daysActive: daysActive,
        averageDailyStudyTime: averageDailyTime,
        mostActiveDay: mostActiveDay,
        topDayStudyTime: maxTime,
      );
    } catch (e) {
      print('Error fetching weekly summary: $e');
      return StudySummary(
        period: 'week',
        totalStudyTime: 0,
        daysActive: 0,
        averageDailyStudyTime: 0,
        mostActiveDay: '',
        topDayStudyTime: 0,
      );
    }
  }

  /// Get category-specific performance
  Future<CategoryPerformance> getCategoryPerformance(
    String userId,
    String category,
  ) async {
    try {
      // Get notes in category
      final notesQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .where('category', isEqualTo: category)
          .get();
      final totalNotes = notesQuery.docs.length;

      // Calculate average study time for category
      int totalStudyTime = 0;
      for (final doc in notesQuery.docs) {
        // Estimate 5 minutes per note
        totalStudyTime += 5;
      }

      // Get flashcards from notes in this category (optional - if category info stored)
      // For now, assume distribution is proportional
      final allFlashcards = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .get();

      // Simple approach: count flashcards from notes in this category
      // This would need noteId relationship to be more accurate
      int categoryFlashcards = 0;
      double totalDifficulty = 0;

      for (final card in allFlashcards.docs) {
        final data = card.data();
        final difficulty = data['difficulty'] as int? ?? 3;
        totalDifficulty += difficulty;
        categoryFlashcards++;
      }

      final avgDifficulty = categoryFlashcards > 0
          ? (totalDifficulty / categoryFlashcards).toStringAsFixed(1)
          : '0.0';

      return CategoryPerformance(
        category: category,
        totalNotes: totalNotes,
        totalFlashcards: categoryFlashcards,
        averageFlashcardDifficulty: avgDifficulty,
        totalStudyTime: totalStudyTime,
        performanceScore: totalNotes > 0 ? '70%' : '0%', // Placeholder
      );
    } catch (e) {
      print('Error fetching category performance: $e');
      return CategoryPerformance(
        category: category,
        totalNotes: 0,
        totalFlashcards: 0,
        averageFlashcardDifficulty: '0.0',
        totalStudyTime: 0,
        performanceScore: '0%',
      );
    }
  }

  /// Get achievements/milestones unlocked
  Future<List<StudyAchievement>> getAchievements(String userId) async {
    try {
      final achievements = <StudyAchievement>[];
      final stats = await getStudyStatistics(userId);

      // Define achievement thresholds
      if (stats.totalNotes >= 1) {
        achievements.add(
          StudyAchievement(
            id: 'first_note',
            title: 'First Note',
            description: 'Created your first note',
            value: stats.totalNotes,
            icon: '📝',
            achievedAt: DateTime.now(),
            isUnlocked: true,
          ),
        );
      }

      if (stats.totalFlashcards >= 10) {
        achievements.add(
          StudyAchievement(
            id: 'flashcard_starter',
            title: 'Flashcard Starter',
            description: 'Created 10 flashcards',
            value: stats.totalFlashcards,
            icon: '🎴',
            achievedAt: DateTime.now(),
            isUnlocked: true,
          ),
        );
      }

      if (stats.totalStudyTime >= 60) {
        achievements.add(
          StudyAchievement(
            id: 'one_hour',
            title: 'One Hour Club',
            description: 'Studied for 1 hour',
            value: stats.totalStudyTime,
            icon: '⏱️',
            achievedAt: DateTime.now(),
            isUnlocked: true,
          ),
        );
      }

      return achievements;
    } catch (e) {
      print('Error fetching achievements: $e');
      return [];
    }
  }

  // ==================================================
  // UTILITY METHODS
  // ==================================================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Calculate study streak (consecutive days of study)
  Future<int> getStudyStreak(String userId) async {
    try {
      final dailyData = await getDailyStudyData(userId, 'month');
      dailyData.sort((a, b) => b.date.compareTo(a.date)); // Sort descending

      int streak = 0;
      for (final day in dailyData) {
        if (day.studyTimeMinutes > 0) {
          streak++;
        } else {
          break; // Streak broken
        }
      }

      return streak;
    } catch (e) {
      print('Error calculating study streak: $e');
      return 0;
    }
  }

  /// Get most productive category
  Future<String> getMostProductiveCategory(String userId) async {
    try {
      final categories = await getCategoryStatistics(userId);
      if (categories.isEmpty) return 'None';

      return categories.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    } catch (e) {
      print('Error getting most productive category: $e');
      return 'None';
    }
  }
}
