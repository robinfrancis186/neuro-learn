import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/models/emotional_state.dart';
import '../../../core/services/emotion_history_service.dart';
import '../../../shared/widgets/neuro_card.dart';

class EmotionAnalyticsDashboard extends StatefulWidget {
  final String studentId;

  const EmotionAnalyticsDashboard({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  State<EmotionAnalyticsDashboard> createState() => _EmotionAnalyticsDashboardState();
}

class _EmotionAnalyticsDashboardState extends State<EmotionAnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EmotionHistoryService _historyService = EmotionHistoryService();
  
  List<EmotionalState> _emotionHistory = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  String _selectedPeriod = '7_days';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadEmotionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEmotionData() async {
    setState(() => _isLoading = true);

    try {
      Duration period;
      switch (_selectedPeriod) {
        case '1_day':
          period = Duration(days: 1);
          break;
        case '7_days':
          period = Duration(days: 7);
          break;
        case '30_days':
          period = Duration(days: 30);
          break;
        case '90_days':
          period = Duration(days: 90);
          break;
        default:
          period = Duration(days: 7);
      }

      final history = await _historyService.getHistory(
        studentId: widget.studentId,
        startDate: DateTime.now().subtract(period),
      );

      setState(() {
        _emotionHistory = history;
        _analytics = _generateAnalytics(history);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading emotion data: $e');
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _generateAnalytics(List<EmotionalState> emotions) {
    if (emotions.isEmpty) return {};

    final emotionCounts = <String, int>{};
    final moodCounts = <StoryMood, int>{};
    final hourlyData = <int, List<EmotionalState>>{};
    final dailyData = <String, List<EmotionalState>>{};

    double totalArousal = 0.0;
    double totalConfidence = 0.0;
    int positiveCount = 0;
    int negativeCount = 0;

    for (final emotion in emotions) {
      // Count emotions
      for (final detected in emotion.detectedEmotions) {
        emotionCounts[detected.label] = (emotionCounts[detected.label] ?? 0) + 1;
      }

      // Count moods
      moodCounts[emotion.recommendedMood] = (moodCounts[emotion.recommendedMood] ?? 0) + 1;

      // Hourly distribution
      final hour = emotion.timestamp.hour;
      hourlyData.putIfAbsent(hour, () => []).add(emotion);

      // Daily distribution
      final day = _formatDate(emotion.timestamp);
      dailyData.putIfAbsent(day, () => []).add(emotion);

      // Metrics
      totalArousal += emotion.arousal;
      totalConfidence += emotion.confidence;

      if (emotion.valence == EmotionalValence.positive) positiveCount++;
      if (emotion.valence == EmotionalValence.negative) negativeCount++;
    }

    final length = emotions.length;

    return {
      'emotionCounts': emotionCounts,
      'moodCounts': moodCounts,
      'hourlyData': hourlyData,
      'dailyData': dailyData,
      'averageArousal': totalArousal / length,
      'averageConfidence': totalConfidence / length,
      'positiveRatio': positiveCount / length,
      'negativeRatio': negativeCount / length,
      'totalEmotions': length,
      'dominantEmotion': _findDominantEmotion(emotionCounts),
      'dominantMood': _findDominantMood(moodCounts),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emotion Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.timeline), text: 'Trends'),
            Tab(icon: Icon(Icons.schedule), text: 'Patterns'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
        actions: [
          _buildPeriodSelector(),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTrendsTab(),
                _buildPatternsTab(),
                _buildInsightsTab(),
              ],
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return PopupMenuButton<String>(
      value: _selectedPeriod,
      onSelected: (period) {
        setState(() => _selectedPeriod = period);
        _loadEmotionData();
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: '1_day', child: Text('Last 24 Hours')),
        PopupMenuItem(value: '7_days', child: Text('Last 7 Days')),
        PopupMenuItem(value: '30_days', child: Text('Last 30 Days')),
        PopupMenuItem(value: '90_days', child: Text('Last 90 Days')),
      ],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_analytics.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetricsGrid(),
          SizedBox(height: 16),
          _buildEmotionDistributionChart(),
          SizedBox(height: 16),
          _buildMoodChart(),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final positiveRatio = _analytics['positiveRatio'] as double;
    final averageArousal = _analytics['averageArousal'] as double;
    final totalEmotions = _analytics['totalEmotions'] as int;
    final averageConfidence = _analytics['averageConfidence'] as double;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildMetricCard(
          title: 'Positive Emotions',
          value: '${(positiveRatio * 100).toInt()}%',
          icon: Icons.sentiment_satisfied,
          color: Colors.green,
        ),
        _buildMetricCard(
          title: 'Energy Level',
          value: '${(averageArousal * 100).toInt()}%',
          icon: Icons.flash_on,
          color: Colors.orange,
        ),
        _buildMetricCard(
          title: 'Total Sessions',
          value: totalEmotions.toString(),
          icon: Icons.timeline,
          color: Colors.blue,
        ),
        _buildMetricCard(
          title: 'Detection Quality',
          value: '${(averageConfidence * 100).toInt()}%',
          icon: Icons.psychology,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return NeuroCard(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionDistributionChart() {
    final emotionCounts = _analytics['emotionCounts'] as Map<String, int>;
    if (emotionCounts.isEmpty) return SizedBox.shrink();

    final sections = emotionCounts.entries.map((entry) {
      final color = _getEmotionColor(entry.key);
      final percentage = (entry.value / _analytics['totalEmotions'] * 100);
      
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${percentage.toInt()}%',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return NeuroCard(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Emotion Distribution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildEmotionLegend(emotionCounts),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionLegend(Map<String, int> emotionCounts) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: emotionCounts.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getEmotionColor(entry.key),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text('${entry.key} (${entry.value})'),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMoodChart() {
    final moodCounts = _analytics['moodCounts'] as Map<StoryMood, int>;
    if (moodCounts.isEmpty) return SizedBox.shrink();

    final barGroups = moodCounts.entries.map((entry) {
      final index = StoryMood.values.indexOf(entry.key);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: _getMoodColor(entry.key),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return NeuroCard(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Recommended Story Moods',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final mood = StoryMood.values[value.toInt()];
                          return Text(
                            mood.toString().split('.').last,
                            style: TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDailyTrendChart(),
          SizedBox(height: 16),
          _buildHourlyHeatmap(),
        ],
      ),
    );
  }

  Widget _buildDailyTrendChart() {
    final dailyData = _analytics['dailyData'] as Map<String, List<EmotionalState>>;
    if (dailyData.isEmpty) return SizedBox.shrink();

    final spots = <FlSpot>[];
    final sortedDays = dailyData.keys.toList()..sort();
    
    for (int i = 0; i < sortedDays.length; i++) {
      final dayEmotions = dailyData[sortedDays[i]]!;
      final avgArousal = dayEmotions.map((e) => e.arousal).reduce((a, b) => a + b) / dayEmotions.length;
      spots.add(FlSpot(i.toDouble(), avgArousal));
    }

    return NeuroCard(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Energy Levels Over Time',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedDays.length) {
                            final date = DateTime.parse(sortedDays[index]);
                            return Text('${date.month}/${date.day}');
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyHeatmap() {
    final hourlyData = _analytics['hourlyData'] as Map<int, List<EmotionalState>>;
    if (hourlyData.isEmpty) return SizedBox.shrink();

    return NeuroCard(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Activity by Hour of Day',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(24, (hour) {
                    final count = hourlyData[hour]?.length ?? 0;
                    final maxCount = hourlyData.values.map((e) => e.length).reduce((a, b) => a > b ? a : b);
                    final intensity = count / maxCount;
                    
                    return Container(
                      width: 30,
                      height: 80,
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(intensity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            count.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: intensity > 0.5 ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            hour.toString(),
                            style: TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWeeklyPatterns(),
          SizedBox(height: 16),
          _buildEmotionSequences(),
        ],
      ),
    );
  }

  Widget _buildWeeklyPatterns() {
    final weeklyData = <int, List<EmotionalState>>{};
    
    for (final emotion in _emotionHistory) {
      final weekday = emotion.timestamp.weekday;
      weeklyData.putIfAbsent(weekday, () => []).add(emotion);
    }

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return NeuroCard(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Weekly Patterns',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final count = weeklyData[index + 1]?.length ?? 0;
                final maxCount = weeklyData.values.map((e) => e.length).reduce((a, b) => a > b ? a : b);
                final height = count > 0 ? (count / maxCount) * 100 : 10;
                
                return Column(
                  children: [
                    Container(
                      width: 30,
                      height: height,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(weekdays[index], style: TextStyle(fontSize: 12)),
                    Text(count.toString(), style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionSequences() {
    if (_emotionHistory.length < 5) return SizedBox.shrink();

    final recentEmotions = _emotionHistory.take(10).toList().reversed.toList();

    return NeuroCard(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Recent Emotion Sequence',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentEmotions.length,
                itemBuilder: (context, index) {
                  final emotion = recentEmotions[index];
                  final primaryEmotion = emotion.detectedEmotions.isNotEmpty
                      ? emotion.detectedEmotions.first.label
                      : 'neutral';

                  return Container(
                    width: 60,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _getEmotionColor(primaryEmotion),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getEmotionIcon(primaryEmotion),
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(height: 4),
                        Text(
                          primaryEmotion,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInsightCards(),
          SizedBox(height: 16),
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildInsightCards() {
    final insights = _generateInsights();

    return Column(
      children: insights.map((insight) {
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          child: NeuroCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    insight['icon'],
                    color: insight['color'],
                    size: 32,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight['title'],
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 4),
                        Text(
                          insight['description'],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _generateRecommendations();

    return NeuroCard(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalized Recommendations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ...recommendations.map((rec) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                  SizedBox(width: 12),
                  Expanded(child: Text(rec)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No emotion data available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          Text(
            'Start using the emotion engine to see analytics',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _findDominantEmotion(Map<String, int> emotionCounts) {
    if (emotionCounts.isEmpty) return 'neutral';
    return emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  StoryMood _findDominantMood(Map<StoryMood, int> moodCounts) {
    if (moodCounts.isEmpty) return StoryMood.neutral;
    return moodCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Colors.yellow[700]!;
      case 'sad':
        return Colors.blue[700]!;
      case 'angry':
        return Colors.red[700]!;
      case 'fear':
        return Colors.purple[700]!;
      case 'surprise':
        return Colors.orange[700]!;
      case 'neutral':
      default:
        return Colors.grey[700]!;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_very_dissatisfied;
      case 'angry':
        return Icons.sentiment_dissatisfied;
      case 'fear':
        return Icons.warning;
      case 'surprise':
        return Icons.new_releases;
      case 'neutral':
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getMoodColor(StoryMood mood) {
    switch (mood) {
      case StoryMood.excitement:
        return Colors.orange;
      case StoryMood.calm:
        return Colors.blue;
      case StoryMood.comfort:
        return Colors.green;
      case StoryMood.adventure:
        return Colors.purple;
      case StoryMood.creative:
        return Colors.pink;
      case StoryMood.social:
        return Colors.teal;
      case StoryMood.neutral:
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _generateInsights() {
    if (_analytics.isEmpty) return [];

    final insights = <Map<String, dynamic>>[];
    final positiveRatio = _analytics['positiveRatio'] as double;
    final averageArousal = _analytics['averageArousal'] as double;
    final dominantEmotion = _analytics['dominantEmotion'] as String;

    if (positiveRatio > 0.7) {
      insights.add({
        'icon': Icons.sentiment_satisfied,
        'color': Colors.green,
        'title': 'Positive Emotional State',
        'description': 'Great! ${(positiveRatio * 100).toInt()}% of emotions are positive. Keep up the good work!',
      });
    } else if (positiveRatio < 0.4) {
      insights.add({
        'icon': Icons.sentiment_neutral,
        'color': Colors.orange,
        'title': 'Room for Improvement',
        'description': 'Consider incorporating more positive activities and supportive content.',
      });
    }

    if (averageArousal > 0.7) {
      insights.add({
        'icon': Icons.flash_on,
        'color': Colors.orange,
        'title': 'High Energy Levels',
        'description': 'Energy levels are high. Consider adding calming activities for balance.',
      });
    } else if (averageArousal < 0.3) {
      insights.add({
        'icon': Icons.battery_low,
        'color': Colors.blue,
        'title': 'Low Energy Pattern',
        'description': 'Energy levels are low. Try more engaging and interactive content.',
      });
    }

    if (dominantEmotion == 'happy') {
      insights.add({
        'icon': Icons.star,
        'color': Colors.amber,
        'title': 'Happiness Dominates',
        'description': 'Happy emotions are most common - this indicates great engagement!',
      });
    }

    return insights;
  }

  List<String> _generateRecommendations() {
    if (_analytics.isEmpty) {
      return ['Start engaging with learning activities to build emotional insights'];
    }

    final recommendations = <String>[];
    final positiveRatio = _analytics['positiveRatio'] as double;
    final averageArousal = _analytics['averageArousal'] as double;
    final dominantMood = _analytics['dominantMood'] as StoryMood;

    if (positiveRatio < 0.5) {
      recommendations.add('Focus on comfort and calm story themes to build emotional security');
      recommendations.add('Incorporate more positive reinforcement and encouragement');
    }

    if (averageArousal > 0.7) {
      recommendations.add('Include more calming activities and quiet time');
      recommendations.add('Use "calm" and "comfort" story moods more frequently');
    } else if (averageArousal < 0.3) {
      recommendations.add('Add more interactive and engaging elements');
      recommendations.add('Try "adventure" and "excitement" themed content');
    }

    switch (dominantMood) {
      case StoryMood.excitement:
        recommendations.add('Balance excitement with calming activities');
        break;
      case StoryMood.calm:
        recommendations.add('Current approach is working well - maintain consistency');
        break;
      case StoryMood.comfort:
        recommendations.add('Gradually introduce more adventurous content as confidence grows');
        break;
      default:
        recommendations.add('Experiment with different story moods to find optimal engagement');
    }

    final hourlyData = _analytics['hourlyData'] as Map<int, List<EmotionalState>>;
    if (hourlyData.isNotEmpty) {
      final peakHour = hourlyData.entries
          .reduce((a, b) => a.value.length > b.value.length ? a : b)
          .key;
      recommendations.add('Peak engagement time is around ${_formatHour(peakHour)} - schedule important activities then');
    }

    return recommendations.take(5).toList();
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour < 12) return '$hour:00 AM';
    if (hour == 12) return '12:00 PM';
    return '${hour - 12}:00 PM';
  }
} 