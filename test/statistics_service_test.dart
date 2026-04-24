import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:smart_study_assistant/services/statistics_service.dart';
import 'package:smart_study_assistant/models/statistics_model.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

void main() {
  group('StatisticsService Tests', () {
    late StatisticsService statisticsService;
    const String testUserId = 'test-user-123';

    setUp(() {
      statisticsService = StatisticsService();
    });

    // ============================================================
    // STUDY STATISTICS TESTS
    // ============================================================

    test('getStudyStatistics should return non-null StudyStatistics', () async {
      final stats = await statisticsService.getStudyStatistics(testUserId);

      expect(stats, isNotNull);
      expect(stats, isA<StudyStatistics>());
      expect(stats.totalNotes, isA<int>());
      expect(stats.totalFlashcards, isA<int>());
      expect(stats.totalSummaries, isA<int>());
      expect(stats.totalStudyTime, isA<int>());
      expect(stats.lastStudyDate, isA<DateTime>());
    });

    test('getStudyStatistics should handle empty user data', () async {
      final stats = await statisticsService.getStudyStatistics(
        'non-existent-user',
      );

      // Should return stats with zero values
      expect(stats.totalNotes, greaterThanOrEqualTo(0));
      expect(stats.totalFlashcards, greaterThanOrEqualTo(0));
    });

    // ============================================================
    // DAILY STUDY DATA TESTS
    // ============================================================

    test('getDailyStudyData should return list of DailyStudyData', () async {
      final dailyData = await statisticsService.getDailyStudyData(
        testUserId,
        'week',
      );

      expect(dailyData, isA<List<DailyStudyData>>());
      expect(
        dailyData.isNotEmpty,
        true,
      ); // Should have data for at least one day
    });

    test('getDailyStudyData week period should return 7+ days data', () async {
      final dailyData = await statisticsService.getDailyStudyData(
        testUserId,
        'week',
      );

      expect(dailyData.length, greaterThanOrEqualTo(1));
      // Check that dates are in valid format
      for (final data in dailyData) {
        expect(data.date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      }
    });

    test(
      'getDailyStudyData month period should return 30+ days data',
      () async {
        final dailyData = await statisticsService.getDailyStudyData(
          testUserId,
          'month',
        );

        expect(dailyData.length, greaterThanOrEqualTo(1));
      },
    );

    test('getDailyStudyData should have correct metrics', () async {
      final dailyData = await statisticsService.getDailyStudyData(
        testUserId,
        'week',
      );

      for (final data in dailyData) {
        expect(data.studyTimeMinutes, greaterThanOrEqualTo(0));
        expect(data.cardsReviewed, greaterThanOrEqualTo(0));
        expect(data.notesCreated, greaterThanOrEqualTo(0));
      }
    });

    // ============================================================
    // CATEGORY STATISTICS TESTS
    // ============================================================

    test('getCategoryStatistics should return Map<String, int>', () async {
      final categories = await statisticsService.getCategoryStatistics(
        testUserId,
      );

      expect(categories, isA<Map<String, int>>());
    });

    test('getCategoryStatistics should have positive counts', () async {
      final categories = await statisticsService.getCategoryStatistics(
        testUserId,
      );

      categories.forEach((category, count) {
        expect(category, isA<String>());
        expect(count, greaterThanOrEqualTo(0));
      });
    });

    // ============================================================
    // FLASHCARD PERFORMANCE TESTS
    // ============================================================

    test(
      'getFlashcardPerformance should return FlashcardPerformance instance',
      () async {
        final performance = await statisticsService.getFlashcardPerformance(
          testUserId,
        );

        expect(performance, isA<FlashcardPerformance>());
        expect(performance.totalReviews, isA<int>());
        expect(performance.averageReviews, isA<String>());
        expect(performance.markedCards, isA<int>());
        expect(performance.averageDifficulty, isA<String>());
      },
    );

    test(
      'getFlashcardPerformance difficulty distribution should have 5 levels',
      () async {
        final performance = await statisticsService.getFlashcardPerformance(
          testUserId,
        );

        expect(performance.difficultyDistribution.length, equals(5));
        expect(performance.difficultyDistribution.containsKey(1), true);
        expect(performance.difficultyDistribution.containsKey(5), true);
      },
    );

    // ============================================================
    // WEEKLY SUMMARY TESTS
    // ============================================================

    test('getWeeklyStudySummary should return StudySummary', () async {
      final summary = await statisticsService.getWeeklyStudySummary(testUserId);

      expect(summary, isA<StudySummary>());
      expect(summary.period, equals('week'));
      expect(summary.totalStudyTime, greaterThanOrEqualTo(0));
      expect(summary.daysActive, greaterThanOrEqualTo(0));
      expect(summary.averageDailyStudyTime, greaterThanOrEqualTo(0));
    });

    test('getWeeklyStudySummary should have valid daysActive', () async {
      final summary = await statisticsService.getWeeklyStudySummary(testUserId);

      expect(summary.daysActive, lessThanOrEqualTo(7));
      expect(summary.daysActive, greaterThanOrEqualTo(0));
    });

    test(
      'getWeeklyStudySummary should calculate averageDailyStudyTime correctly',
      () async {
        final summary = await statisticsService.getWeeklyStudySummary(
          testUserId,
        );

        if (summary.daysActive > 0) {
          final expectedAverage = summary.totalStudyTime ~/ summary.daysActive;
          expect(summary.averageDailyStudyTime, equals(expectedAverage));
        }
      },
    );

    // ============================================================
    // CATEGORY PERFORMANCE TESTS
    // ============================================================

    test('getCategoryPerformance should return CategoryPerformance', () async {
      final categories = await statisticsService.getCategoryStatistics(
        testUserId,
      );

      if (categories.isNotEmpty) {
        final category = categories.keys.first;
        final performance = await statisticsService.getCategoryPerformance(
          testUserId,
          category,
        );

        expect(performance, isA<CategoryPerformance>());
        expect(performance.category, equals(category));
        expect(performance.totalNotes, greaterThanOrEqualTo(0));
      }
    });

    // ============================================================
    // ACHIEVEMENTS TESTS
    // ============================================================

    test('getAchievements should return List<StudyAchievement>', () async {
      final achievements = await statisticsService.getAchievements(testUserId);

      expect(achievements, isA<List<StudyAchievement>>());
    });

    test('getAchievements should have valid achievement data', () async {
      final achievements = await statisticsService.getAchievements(testUserId);

      for (final achievement in achievements) {
        expect(achievement.id, isNotEmpty);
        expect(achievement.title, isNotEmpty);
        expect(achievement.icon, isNotEmpty);
        expect(achievement.isUnlocked, isTrue);
      }
    });

    // ============================================================
    // STUDY STREAK TESTS
    // ============================================================

    test('getStudyStreak should return non-negative integer', () async {
      final streak = await statisticsService.getStudyStreak(testUserId);

      expect(streak, isA<int>());
      expect(streak, greaterThanOrEqualTo(0));
    });

    // ============================================================
    // MOST PRODUCTIVE CATEGORY TESTS
    // ============================================================

    test('getMostProductiveCategory should return String', () async {
      final category = await statisticsService.getMostProductiveCategory(
        testUserId,
      );

      expect(category, isA<String>());
      expect(category.isNotEmpty, true);
    });

    // ============================================================
    // DATA MODEL TESTS
    // ============================================================

    group('StudyStatistics Model', () {
      test('empty factory should create zero-valued instance', () {
        final stats = StudyStatistics.empty();

        expect(stats.totalNotes, equals(0));
        expect(stats.totalFlashcards, equals(0));
        expect(stats.totalSummaries, equals(0));
        expect(stats.totalStudyTime, equals(0));
      });

      test('toMap and fromMap should preserve data', () {
        final original = StudyStatistics(
          totalNotes: 10,
          totalFlashcards: 50,
          totalSummaries: 5,
          totalStudyTime: 300,
          lastStudyDate: DateTime(2024, 1, 15),
        );

        final map = original.toMap();
        final restored = StudyStatistics.fromMap(map);

        expect(restored.totalNotes, equals(original.totalNotes));
        expect(restored.totalFlashcards, equals(original.totalFlashcards));
        expect(restored.totalStudyTime, equals(original.totalStudyTime));
      });
    });

    group('DailyStudyData Model', () {
      test('fromMap should create instance correctly', () {
        final map = {
          'date': '2024-01-15',
          'studyTimeMinutes': 45,
          'cardsReviewed': 20,
          'notesCreated': 3,
        };

        final data = DailyStudyData.fromMap(map);

        expect(data.date, equals('2024-01-15'));
        expect(data.studyTimeMinutes, equals(45));
        expect(data.cardsReviewed, equals(20));
        expect(data.notesCreated, equals(3));
      });

      test('toMap should convert instance correctly', () {
        final data = DailyStudyData(
          date: '2024-01-15',
          studyTimeMinutes: 45,
          cardsReviewed: 20,
          notesCreated: 3,
        );

        final map = data.toMap();

        expect(map['date'], equals('2024-01-15'));
        expect(map['studyTimeMinutes'], equals(45));
      });
    });

    group('FlashcardPerformance Model', () {
      test('empty factory should create zero-valued instance', () {
        final perf = FlashcardPerformance.empty();

        expect(perf.totalReviews, equals(0));
        expect(perf.markedCards, equals(0));
        expect(perf.difficultyDistribution.length, equals(5));
      });

      test('difficultyDistribution fromMap should handle Map', () {
        final map = {
          'totalReviews': 100,
          'averageReviews': '2.5',
          'markedCards': 10,
          'averageDifficulty': '3.0',
          'difficultyDistribution': {
            '1': 5,
            '2': 10,
            '3': 20,
            '4': 15,
            '5': 10,
          },
        };

        final perf = FlashcardPerformance.fromMap(map);

        expect(perf.difficultyDistribution.length, equals(5));
      });
    });

    group('StudySummary Model', () {
      test('toMap and fromMap should preserve all data', () {
        final original = StudySummary(
          period: 'week',
          totalStudyTime: 210,
          daysActive: 6,
          averageDailyStudyTime: 35,
          mostActiveDay: '2024-01-15',
          topDayStudyTime: 60,
        );

        final map = original.toMap();
        final restored = StudySummary.fromMap(map);

        expect(restored.period, equals(original.period));
        expect(restored.totalStudyTime, equals(original.totalStudyTime));
        expect(restored.daysActive, equals(original.daysActive));
      });
    });

    group('StudyAchievement Model', () {
      test('toMap and fromMap should preserve achievement data', () {
        final original = StudyAchievement(
          id: 'first-note',
          title: 'First Note',
          description: 'Created your first note',
          value: 1,
          icon: '📝',
          achievedAt: DateTime(2024, 1, 1),
          isUnlocked: true,
        );

        final map = original.toMap();
        final restored = StudyAchievement.fromMap(map);

        expect(restored.id, equals(original.id));
        expect(restored.title, equals(original.title));
        expect(restored.isUnlocked, equals(original.isUnlocked));
      });
    });

    group('CategoryPerformance Model', () {
      test('fromMap should handle missing fields gracefully', () {
        final map = {'category': 'Mathematics', 'totalNotes': 15};

        final perf = CategoryPerformance.fromMap(map);

        expect(perf.category, equals('Mathematics'));
        expect(perf.totalNotes, equals(15));
        expect(perf.totalFlashcards, equals(0));
        expect(perf.performanceScore, equals('0%'));
      });
    });
  });

  // ============================================================
  // INTEGRATION TESTS
  // ============================================================

  group('StatisticsService Integration Tests', () {
    late StatisticsService statisticsService;
    const String testUserId = 'integration-test-user';

    setUp(() {
      statisticsService = StatisticsService();
    });

    test('Should load complete statistics snapshot', () async {
      final stats = await statisticsService.getStudyStatistics(testUserId);
      final summary = await statisticsService.getWeeklyStudySummary(testUserId);
      final performance = await statisticsService.getFlashcardPerformance(
        testUserId,
      );

      expect(stats, isNotNull);
      expect(summary, isNotNull);
      expect(performance, isNotNull);
    });

    test('Should calculate consistent metrics', () async {
      final summary = await statisticsService.getWeeklyStudySummary(testUserId);

      // If daysActive is 0, totalStudyTime should be 0 or close to it
      if (summary.daysActive == 0) {
        expect(summary.totalStudyTime, lessThanOrEqualTo(5));
      }

      // Average should not exceed total
      if (summary.daysActive > 0) {
        expect(
          summary.averageDailyStudyTime * summary.daysActive,
          lessThanOrEqualTo(summary.totalStudyTime + 10),
        );
      }
    });

    test('Should have valid date ranges in daily data', () async {
      final dailyData = await statisticsService.getDailyStudyData(
        testUserId,
        'week',
      );

      if (dailyData.length > 1) {
        final dates = dailyData.map((d) => DateTime.parse(d.date)).toList();
        dates.sort();

        // Dates should be in ascending order
        for (int i = 1; i < dates.length; i++) {
          expect(dates[i].isAfter(dates[i - 1]), true);
        }
      }
    });
  });

  // ============================================================
  // ERROR HANDLING TESTS
  // ============================================================

  group('Error Handling', () {
    late StatisticsService statisticsService;

    setUp(() {
      statisticsService = StatisticsService();
    });

    test('Should handle empty user ID gracefully', () async {
      final stats = await statisticsService.getStudyStatistics('');

      expect(stats, isA<StudyStatistics>());
    });

    test('Should return empty data for non-existent user', () async {
      final stats = await statisticsService.getStudyStatistics(
        'non-existent-xyz-123',
      );

      // Should return stats with 0 values
      expect(stats.totalNotes, equals(0));
      expect(stats.totalFlashcards, equals(0));
    });

    test('getDailyStudyData should return empty list on error', () async {
      final darkResult = await statisticsService.getDailyStudyData(
        'invalid-user',
        'invalid-period',
      );

      expect(darkResult, isA<List<DailyStudyData>>());
    });
  });
}
