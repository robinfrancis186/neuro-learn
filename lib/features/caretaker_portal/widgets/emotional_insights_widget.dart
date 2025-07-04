import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/emotion_service.dart';
import '../../../core/services/emotion_analytics_service.dart';
import '../../../core/services/emotion_history_service.dart';
import '../../../core/models/emotional_state.dart';
import '../../../core/models/emotion_analytics.dart';
import '../../../shared/widgets/neuro_card.dart';

class EmotionalInsightsWidget extends StatefulWidget {
  const EmotionalInsightsWidget({Key? key}) : super(key: key);

  @override
  State<EmotionalInsightsWidget> createState() => _EmotionalInsightsWidgetState();
}

class _EmotionalInsightsWidgetState extends State<EmotionalInsightsWidget> {
  final RealEmotionService _emotionService = RealEmotionService();
  final EmotionHistoryService _historyService = EmotionHistoryService();
  final EmotionAnalyticsService _analyticsService = EmotionAnalyticsService();
  Map<String, double> _currentEmotions = {};
  List<EmotionalState> _emotionHistory = [];
  EmotionAnalytics? _analytics;
  bool _isLoading = true;
  String _selectedTimeRange = '24h';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _emotionService.initialize();
    await _historyService.initialize();
    _subscribeToEmotions();
    _loadHistoricalData();
  }

  void _subscribeToEmotions() {
    _emotionService.emotionStream.listen((emotionData) {
      if (mounted) {
        setState(() {
          _currentEmotions = Map<String, double>.from(emotionData['emotions'] ?? {});
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadHistoricalData() async {
    final duration = _getDurationFromRange(_selectedTimeRange);
    final history = await _historyService.getHistory(
      studentId: 'default_student',
      startDate: DateTime.now().subtract(duration),
    );
    
    final analytics = await _analyticsService.generateAnalytics(
      emotionHistory: history,
      studentId: 'default_student',
      period: duration,
    );

    if (mounted) {
      setState(() {
        _emotionHistory = history;
        _analytics = analytics;
        _isLoading = false;
      });
    }
  }

  Duration _getDurationFromRange(String range) {
    switch (range) {
      case '24h':
        return const Duration(hours: 24);
      case '7d':
        return const Duration(days: 7);
      case '30d':
        return const Duration(days: 30);
      default:
        return const Duration(hours: 24);
    }
  }

  List<BarChartGroupData> _getBarGroups() {
    final emotions = [
      {'name': 'Calm', 'value': _currentEmotions['neutral'] ?? 0.0, 'color': const Color(0xFF4CAF50)},
      {'name': 'Focused', 'value': _currentEmotions['happy'] ?? 0.0, 'color': const Color(0xFF2196F3)},
      {'name': 'Excited', 'value': _currentEmotions['surprise'] ?? 0.0, 'color': const Color(0xFFFF9800)},
      {'name': 'Overwhelmed', 'value': (_currentEmotions['fear'] ?? 0.0) + (_currentEmotions['angry'] ?? 0.0), 'color': const Color(0xFFE57373)},
    ];

    return emotions.asMap().entries.map((entry) {
      final index = entry.key;
      final emotion = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (emotion['value'] as double) * 100,
            color: emotion['color'] as Color,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return NeuroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emotional Insights',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: _selectedTimeRange,
                items: [
                  DropdownMenuItem(value: '24h', child: Text('Last 24h')),
                  DropdownMenuItem(value: '7d', child: Text('Last 7 days')),
                  DropdownMenuItem(value: '30d', child: Text('Last 30 days')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTimeRange = value;
                    });
                    _loadHistoricalData();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barGroups: _getBarGroups(),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const emotions = ['Calm', 'Focused', 'Excited', 'Overwhelmed'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  emotions[value.toInt()],
                                  style: const TextStyle(
                                    color: Color(0xFF7589A2),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: const TextStyle(
                                  color: Color(0xFF7589A2),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                    ),
                  ),
                ),
                if (_analytics != null) ...[
                  const SizedBox(height: 24),
                  _buildInsightsSummary(),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInsightsSummary() {
    final analytics = _analytics!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                'Emotional Stability',
                '${(analytics.emotionalStability * 100).toInt()}%',
                Icons.psychology_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInsightCard(
                'Positive Ratio',
                '${(analytics.positiveRatio * 100).toInt()}%',
                Icons.sentiment_satisfied_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Trends',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...analytics.trends.map((trend) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Icon(
                trend.direction == 'increasing' ? Icons.trending_up : 
                trend.direction == 'decreasing' ? Icons.trending_down : 
                Icons.trending_flat,
                color: trend.direction == 'increasing' ? Colors.green :
                       trend.direction == 'decreasing' ? Colors.red :
                       Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(trend.description),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 