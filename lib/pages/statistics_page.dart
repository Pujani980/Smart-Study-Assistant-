import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_study_assistant/services/statistics_service.dart';
import 'package:smart_study_assistant/models/statistics_model.dart';
import 'package:intl/intl.dart';

/// Study Statistics Page - Member 5 Implementation
/// Displays comprehensive study progress, analytics, and visualizations
/// Features: Charts, progress tracking, study time, and performance metrics
class StatisticsPage extends StatefulWidget {
  final String userId;

  const StatisticsPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final StatisticsService _statisticsService = StatisticsService();

  late Future<StudyStatistics> _statisticsFuture;
  late Future<List<DailyStudyData>> _dailyDataFuture;
  late Future<Map<String, int>> _categoryStatsFuture;
  late Future<FlashcardPerformance> _flashcardPerformanceFuture;

  bool _isLoading = true;
  String _selectedPeriod = 'week'; // week, month, all

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() {
    setState(() => _isLoading = true);

    _statisticsFuture = _statisticsService.getStudyStatistics(widget.userId);
    _dailyDataFuture = _statisticsService.getDailyStudyData(
      widget.userId,
      _selectedPeriod,
    );
    _categoryStatsFuture = _statisticsService.getCategoryStatistics(
      widget.userId,
    );
    _flashcardPerformanceFuture = _statisticsService.getFlashcardPerformance(
      widget.userId,
    );

    setState(() => _isLoading = false);
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      _dailyDataFuture = _statisticsService.getDailyStudyData(
        widget.userId,
        period,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Study Statistics'),
          elevation: 0,
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.trending_up), text: 'Overview'),
              Tab(icon: Icon(Icons.pie_chart), text: 'Analytics'),
              Tab(icon: Icon(Icons.grade), text: 'Performance'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Overview
            _buildOverviewTab(),
            // Tab 2: Analytics
            _buildAnalyticsTab(),
            // Tab 3: Performance
            _buildPerformanceTab(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TAB 1: OVERVIEW
  // ============================================================

  Widget _buildOverviewTab() {
    return FutureBuilder<StudyStatistics>(
      future: _statisticsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                const Text('Error loading statistics'),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data!;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Notes',
                        value: '${stats.totalNotes}',
                        icon: Icons.note_outlined,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Flashcards',
                        value: '${stats.totalFlashcards}',
                        icon: Icons.style_outlined,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Study Time',
                        value: _formatStudyTime(stats.totalStudyTime),
                        icon: Icons.schedule_outlined,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Summaries',
                        value: '${stats.totalSummaries}',
                        icon: Icons.summarize_outlined,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Daily Study Trend Chart
                Text(
                  'Daily Study Activity (${_selectedPeriod.toUpperCase()})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildDailyTrendChart(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTrendChart() {
    return FutureBuilder<List<DailyStudyData>>(
      future: _dailyDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('No study data available')),
          );
        }

        final data = snapshot.data!;
        final maxStudyTime = data
            .map((d) => d.studyTimeMinutes)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();

        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxStudyTime / 5).ceil().toDouble(),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}m',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        return Text(
                          data[index].date.substring(5),
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    data.length,
                    (i) => FlSpot(
                      i.toDouble(),
                      data[i].studyTimeMinutes.toDouble(),
                    ),
                  ),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TAB 2: ANALYTICS
  // ============================================================

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPeriodButton('week', 'This Week'),
                _buildPeriodButton('month', 'This Month'),
                _buildPeriodButton('all', 'All Time'),
              ],
            ),
            const SizedBox(height: 32),

            // Category Distribution Chart
            Text(
              'Notes by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildCategoryChart(),
            const SizedBox(height: 32),

            // Detailed Statistics
            Text(
              'Study Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildCategoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return ElevatedButton(
      onPressed: () => _changePeriod(period),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildCategoryChart() {
    return FutureBuilder<Map<String, int>>(
      future: _categoryStatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('No category data')),
          );
        }

        final categoryData = snapshot.data!;
        final colors = [
          Colors.blue,
          Colors.orange,
          Colors.green,
          Colors.red,
          Colors.purple,
        ];

        final pieChartSections = categoryData.entries
            .toList()
            .asMap()
            .entries
            .map((e) {
              final index = e.key;
              final entry = e.value;
              return PieChartSectionData(
                color: colors[index % colors.length],
                value: entry.value.toDouble(),
                title: '${entry.value}',
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            })
            .toList();

        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: PieChart(
            PieChartData(sections: pieChartSections, centerSpaceRadius: 60),
          ),
        );
      },
    );
  }

  Widget _buildCategoryList() {
    return FutureBuilder<Map<String, int>>(
      future: _categoryStatsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No data');
        }

        final categories = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final entry = categories.entries.toList()[index];
            final percentage =
                (entry.value /
                        categories.values.fold<int>(0, (a, b) => a + b) *
                        100)
                    .toStringAsFixed(1);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.7 - (index * 0.1)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value:
                                  entry.value /
                                  categories.values.fold<int>(
                                    0,
                                    (a, b) => a + b,
                                  ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${entry.value}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // TAB 3: PERFORMANCE
  // ============================================================

  Widget _buildPerformanceTab() {
    return FutureBuilder<FlashcardPerformance>(
      future: _flashcardPerformanceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No performance data available'),
                const SizedBox(height: 8),
                const Text(
                  'Practice flashcards to see your performance',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final performance = snapshot.data!;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Performance Summary
                Text(
                  'Flashcard Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Reviews',
                        value: '${performance.totalReviews}',
                        icon: Icons.repeat_outlined,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Avg Reviews',
                        value: performance.averageReviews,
                        icon: Icons.trending_up_outlined,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Marked Cards',
                        value: '${performance.markedCards}',
                        icon: Icons.star_outline,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Difficulty Avg',
                        value: performance.averageDifficulty,
                        icon: Icons.info_outlined,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Difficulty Distribution
                Text(
                  'Card Difficulty Distribution',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildDifficultyDistribution(
                  performance.difficultyDistribution,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDifficultyDistribution(Map<int, int> distribution) {
    return Column(
      children: List.generate(5, (index) {
        final difficulty = index + 1;
        final count = distribution[difficulty] ?? 0;
        final maxCount = distribution.values.fold<int>(
          0,
          (a, b) => a > b ? a : b,
        );
        final percentage = maxCount > 0 ? count / maxCount : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level $difficulty',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getDifficultyColor(difficulty),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  String _formatStudyTime(int totalMinutes) {
    if (totalMinutes < 60) {
      return '${totalMinutes}m';
    } else if (totalMinutes < 1440) {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return '${hours}h ${minutes}m';
    } else {
      final days = totalMinutes ~/ 1440;
      final hours = (totalMinutes % 1440) ~/ 60;
      return '${days}d ${hours}h';
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
