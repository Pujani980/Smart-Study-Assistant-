# Member 5: Statistics Implementation - Code Examples

## Table of Contents
1. [Basic Usage](#basic-usage)
2. [Service Integration](#service-integration)
3. [UI Integration](#ui-integration)
4. [Advanced Queries](#advanced-queries)
5. [Real-World Scenarios](#real-world-scenarios)

---

## Basic Usage

### Example 1: Getting Overall Statistics
```dart
// In your main code or state
final statisticsService = StatisticsService();

Future<void> loadStats() async {
  try {
    final stats = await statisticsService.getStudyStatistics(userId);
    
    print('📊 Study Statistics:');
    print('  • Notes: ${stats.totalNotes}');
    print('  • Flashcards: ${stats.totalFlashcards}');
    print('  • Summaries: ${stats.totalSummaries}');
    print('  • Study Time: ${stats.totalStudyTime} minutes');
    print('  • Last studied: ${stats.lastStudyDate}');
  } catch (e) {
    print('Error loading statistics: $e');
  }
}
```

### Example 2: Displaying Stats in UI
```dart
Widget _buildStatsDisplay(StudyStatistics stats) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Study Time: ${stats.totalStudyTime} minutes',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Notes created: ${stats.totalNotes}'),
          Text('Flashcards: ${stats.totalFlashcards}'),
          Text('AI Summaries: ${stats.totalSummaries}'),
        ],
      ),
    ),
  );
}
```

---

## Service Integration

### Example 3: Daily Activity Tracking
```dart
Future<void> getDailyActivity() async {
  final dailyData = await statisticsService.getDailyStudyData(userId, 'week');
  
  print('📅 Daily Activity (Past Week):');
  for (final day in dailyData) {
    print('${day.date}: ${day.studyTimeMinutes} min, '
          '${day.cardsReviewed} cards, ${day.notesCreated} notes');
  }
  
  // Calculate totals
  final totalMinutes = dailyData.fold<int>(0, (sum, day) => sum + day.studyTimeMinutes);
  final activeDays = dailyData.where((day) => day.studyTimeMinutes > 0).length;
  
  print('\n📈 Weekly Summary:');
  print('  • Total study time: $totalMinutes minutes');
  print('  • Days active: $activeDays/7');
  print('  • Average daily: ${totalMinutes ~/ 7} minutes');
}
```

### Example 4: Weekly Summary
```dart
Future<void> showWeeklySummary() async {
  final summary = await statisticsService.getWeeklyStudySummary(userId);
  
  return AlertDialog(
    title: const Text('Weekly Summary'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total Study Time: ${summary.totalStudyTime} minutes'),
        Text('Days Active: ${summary.daysActive}/7'),
        Text('Average Daily: ${summary.averageDailyStudyTime} minutes'),
        Text('Most Active Day: ${summary.mostActiveDay}'),
        Text('Top Day Study Time: ${summary.topDayStudyTime} minutes'),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
    ],
  );
}
```

### Example 5: Category Statistics
```dart
Future<void> analyzeCategoryBreakdown() async {
  final categories = await statisticsService.getCategoryStatistics(userId);
  
  print('📚 Notes by Category:');
  categories.forEach((category, count) {
    final percentage = ((count / categories.values.fold(0, (a, b) => a + b)) * 100)
        .toStringAsFixed(1);
    print('  • $category: $count notes ($percentage%)');
  });
  
  // Find most studied category
  if (categories.isNotEmpty) {
    final mostStudied = categories.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    print('\n🏆 Most studied category: $mostStudied');
  }
}
```

### Example 6: Flashcard Performance
```dart
Future<void> analyzeFlashcardMetrics() async {
  final performance = await statisticsService.getFlashcardPerformance(userId);
  
  print('🎴 Flashcard Performance:');
  print('  • Total reviews: ${performance.totalReviews}');
  print('  • Avg reviews per card: ${performance.averageReviews}');
  print('  • Marked cards: ${performance.markedCards}');
  print('  • Avg difficulty: ${performance.averageDifficulty}');
  
  // Show difficulty distribution
  print('\n📊 Difficulty Distribution:');
  performance.difficultyDistribution.forEach((difficulty, count) {
    final stars = '⭐' * difficulty;
    print('  $stars ($difficulty): $count cards');
  });
}
```

---

## UI Integration

### Example 7: Statistics Dashboard Widget
```dart
class StatisticsDashboard extends StatefulWidget {
  final String userId;
  
  const StatisticsDashboard({Key? key, required this.userId}) : super(key: key);

  @override
  State<StatisticsDashboard> createState() => _StatisticsDashboardState();
}

class _StatisticsDashboardState extends State<StatisticsDashboard> {
  final _statsService = StatisticsService();
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudyStatistics>(
      future: _statsService.getStudyStatistics(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final stats = snapshot.data!;
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Overview cards
            _buildStatCard('Notes', stats.totalNotes.toString(), Icons.note),
            const SizedBox(height: 12),
            _buildStatCard('Flashcards', stats.totalFlashcards.toString(), Icons.layers),
            const SizedBox(height: 12),
            _buildStatCard('Study Time', '${stats.totalStudyTime} min', Icons.schedule),
            const SizedBox(height: 12),
            _buildStatCard('Summaries', stats.totalSummaries.toString(), Icons.summarize),
          ],
        );
      },
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14)),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example 8: Study Streak Display
```dart
Future<void> displayStudyStreak() async {
  final streak = await statisticsService.getStudyStreak(userId);
  
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🔥',
            style: TextStyle(fontSize: 60),
          ),
          const SizedBox(height: 16),
          Text(
            '$streak Days',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Keep studying to maintain your streak!'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('AWESOME'),
        ),
      ],
    ),
  );
}
```

### Example 9: Category Performance Widget
```dart
class CategoryPerformanceWidget extends StatelessWidget {
  final String userId;
  final String category;
  final StatisticsService _service = StatisticsService();
  
  CategoryPerformanceWidget({
    Key? key,
    required this.userId,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CategoryPerformance>(
      future: _service.getCategoryPerformance(userId, category),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ShimmerLoader();
        }
        
        final perf = snapshot.data!;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perf.category,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildMetricRow('Notes', '${perf.totalNotes}'),
                _buildMetricRow('Flashcards', '${perf.totalFlashcards}'),
                _buildMetricRow('Avg Difficulty', perf.averageFlashcardDifficulty),
                _buildMetricRow('Performance', perf.performanceScore),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
```

---

## Advanced Queries

### Example 10: Multi-Metric Analysis
```dart
/// Comprehensive study analysis
Future<Map<String, dynamic>> getComprehensiveAnalysis(String userId) async {
  final stats = await statisticsService.getStudyStatistics(userId);
  final summary = await statisticsService.getWeeklyStudySummary(userId);
  final flashcards = await statisticsService.getFlashcardPerformance(userId);
  final categories = await statisticsService.getCategoryStatistics(userId);
  final streak = await statisticsService.getStudyStreak(userId);
  
  return {
    'overallStats': stats,
    'weeklySummary': summary,
    'flashcardMetrics': flashcards,
    'categoryBreakdown': categories,
    'currentStreak': streak,
    'generatedAt': DateTime.now(),
  };
}
```

### Example 11: Achievement System
```dart
Future<void> displayAchievements() async {
  final achievements = await statisticsService.getAchievements(userId);
  
  if (achievements.isEmpty) {
    showSnackBar('Keep studying to unlock achievements!');
    return;
  }
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('🏆 Achievements Unlocked'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: achievements
              .map((achievement) => ListTile(
                    leading: Text(achievement.icon, style: const TextStyle(fontSize: 24)),
                    title: Text(achievement.title),
                    subtitle: Text(achievement.description),
              ))
              .toList(),
        ),
      ),
    ),
  );
}
```

### Example 12: Productivity Analysis
```dart
Future<String> getMostProductiveCategory() async {
  final category = await statisticsService.getMostProductiveCategory(userId);
  
  if (category == 'None') {
    return 'No data yet. Start studying!';
  }
  
  return 'Your most productive category is: $category 🎯';
}
```

---

## Real-World Scenarios

### Scenario 1: Home Dashboard
```dart
class HomeDashboard extends StatefulWidget {
  final String userId;
  
  const HomeDashboard({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final _statsService = StatisticsService();
  late Future<StudyStatistics> _statsFuture;
  late Future<int> _streakFuture;
  late Future<StudySummary> _summaryFuture;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _loadData() {
    _statsFuture = _statsService.getStudyStatistics(widget.userId);
    _streakFuture = _statsService.getStudyStreak(widget.userId);
    _summaryFuture = _statsService.getWeeklyStudySummary(widget.userId);
  }
  
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(_loadData),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Streak section
          FutureBuilder<int>(
            future: _streakFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return _buildStreakCard(snapshot.data!);
            },
          ),
          const SizedBox(height: 16),
          
          // Stats section
          FutureBuilder<StudyStatistics>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              return _buildStatsGrid(snapshot.data!);
            },
          ),
          const SizedBox(height: 16),
          
          // Weekly summary
          FutureBuilder<StudySummary>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return _buildSummaryCard(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildStreakCard(int streak) => Card(
    color: Colors.amber[50],
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Study Streak'),
              Text('$streak Days', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    ),
  );
  
  Widget _buildStatsGrid(StudyStatistics stats) => GridView.count(
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      _buildStatTile('Notes', stats.totalNotes, Icons.note, Colors.blue),
      _buildStatTile('Flashcards', stats.totalFlashcards, Icons.layers, Colors.orange),
      _buildStatTile('Study Time', stats.totalStudyTime, Icons.schedule, Colors.green),
      _buildStatTile('Summaries', stats.totalSummaries, Icons.summarize, Colors.purple),
    ],
  );
  
  Widget _buildStatTile(String title, int value, IconData icon, Color color) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600])),
              Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    ),
  );
  
  Widget _buildSummaryCard(StudySummary summary) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This Week', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _summaryRow('Total Time', '${summary.totalStudyTime} min'),
          _summaryRow('Days Active', '${summary.daysActive}/7'),
          _summaryRow('Avg Daily', '${summary.averageDailyStudyTime} min'),
        ],
      ),
    ),
  );
  
  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
```

### Scenario 2: Statistics Export
```dart
Future<String> exportStatisticsAsJSON(String userId) async {
  final stats = await statisticsService.getStudyStatistics(userId);
  final summary = await statisticsService.getWeeklyStudySummary(userId);
  final performance = await statisticsService.getFlashcardPerformance(userId);
  
  final jsonData = {
    'exportedAt': DateTime.now().toIso8601String(),
    'userId': userId,
    'overallStatistics': stats.toMap(),
    'weeklySummary': summary.toMap(),
    'flashcardPerformance': performance.toMap(),
  };
  
  // Save to file or share
  return jsonEncode(jsonData);
}
```

### Scenario 3: Goal Tracking
```dart
class StudyGoalTracker {
  final String userId;
  final int dailyGoalMinutes = 30;
  final int weeklyGoalMinutes = 210;
  
  final StatisticsService _service = StatisticsService();
  
  Future<GoalProgress> trackProgress() async {
    final summary = await _service.getWeeklyStudySummary(userId);
    
    return GoalProgress(
      dailyGoal: dailyGoalMinutes,
      weeklyGoal: weeklyGoalMinutes,
      weeklyProgress: summary.totalStudyTime,
      weeklyPercentage: (summary.totalStudyTime / weeklyGoalMinutes * 100).toStringAsFixed(1),
      daysActiveGoal: 5,
      daysActiveProgress: summary.daysActive,
      isOnTrack: summary.totalStudyTime >= (weeklyGoalMinutes * 0.8),
    );
  }
}

class GoalProgress {
  final int dailyGoal;
  final int weeklyGoal;
  final int weeklyProgress;
  final String weeklyPercentage;
  final int daysActiveGoal;
  final int daysActiveProgress;
  final bool isOnTrack;
}
```

---

## Error Handling Best Practices

### Example 13: Robust Statistics Loading
```dart
Future<StudyStatistics> safeGetStatistics(String userId) async {
  try {
    return await statisticsService.getStudyStatistics(userId);
  } on FirebaseException catch (e) {
    print('Firebase error: ${e.message}');
    // Return empty/cached statistics
    return StudyStatistics.empty();
  } on TimeoutException {
    print('Request timeout');
    // Return cached data if available
    return await _getCachedStatistics(userId);
  } catch (e) {
    print('Unexpected error: $e');
    return StudyStatistics.empty();
  }
}
```

---

## Testing Examples

### Example 14: Unit Tests
```dart
void main() {
  group('StatisticsService', () {
    test('Should aggregate study statistics correctly', () async {
      final service = StatisticsService();
      final stats = await service.getStudyStatistics(testUserId);
      
      expect(stats.totalNotes, isNotNull);
      expect(stats.totalFlashcards, isNotNull);
      expect(stats.totalStudyTime, greaterThanOrEqualTo(0));
    });
    
    test('Should calculate study streak', () async {
      final service = StatisticsService();
      final streak = await service.getStudyStreak(testUserId);
      
      expect(streak, isA<int>());
      expect(streak, greaterThanOrEqualTo(0));
    });
  });
}
```

---

This comprehensive guide covers basic usage, integration patterns, advanced queries, and real-world scenarios for implementing the statistics system in the Smart Study Assistant.
