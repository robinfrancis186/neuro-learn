import 'dart:async';
import 'dart:math';
import '../models/emotional_state.dart';
import '../models/emotion_analytics.dart';

/// Service for generating detailed emotion analytics and insights
class EmotionAnalyticsService {
  static final EmotionAnalyticsService _instance = EmotionAnalyticsService._internal();
  factory EmotionAnalyticsService() => _instance;
  EmotionAnalyticsService._internal();

  /// Generate comprehensive analytics for emotion history
  Future<EmotionAnalytics> generateAnalytics({
    required List<EmotionalState> emotionHistory,
    required String studentId,
    Duration? period,
  }) async {
    if (emotionHistory.isEmpty) {
      return EmotionAnalytics.empty(studentId);
    }

    // Filter by period if specified
    List<EmotionalState> filteredEmotions = emotionHistory;
    if (period != null) {
      final cutoff = DateTime.now().subtract(period);
      filteredEmotions = emotionHistory
          .where((emotion) => emotion.timestamp.isAfter(cutoff))
          .toList();
    }

    return _analyzeEmotions(filteredEmotions, studentId);
  }

  /// Main analysis method
  EmotionAnalytics _analyzeEmotions(List<EmotionalState> emotions, String studentId) {
    // Basic metrics
    final basicMetrics = _calculateBasicMetrics(emotions);
    
    // Trends and patterns
    final trends = _analyzeTrends(emotions);
    final patterns = _analyzePatterns(emotions);
    
    // Time-based analysis
    final timeAnalysis = _analyzeTimePatterns(emotions);
    
    // Weekly/daily patterns
    final weeklyPatterns = _analyzeWeeklyPatterns(emotions);
    
    // Recommendations
    final recommendations = _generateRecommendations(basicMetrics, trends, patterns);

    return EmotionAnalytics(
      studentId: studentId,
      totalEmotions: emotions.length,
      emotionCounts: basicMetrics['emotionCounts'] as Map<String, int>,
      moodCounts: basicMetrics['moodCounts'] as Map<String, int>,
      averageArousal: basicMetrics['averageArousal'] as double,
      averageConfidence: basicMetrics['averageConfidence'] as double,
      positiveRatio: basicMetrics['positiveRatio'] as double,
      negativeRatio: basicMetrics['negativeRatio'] as double,
      emotionalStability: basicMetrics['emotionalStability'] as double,
      dominantEmotion: basicMetrics['dominantEmotion'] as String,
      dominantMood: basicMetrics['dominantMood'] as StoryMood,
      trends: trends,
      patterns: patterns,
      timePatterns: timeAnalysis,
      weeklyPatterns: weeklyPatterns,
      recommendations: recommendations,
      generatedAt: DateTime.now(),
      periodDays: emotions.isNotEmpty ? 
          emotions.first.timestamp.difference(emotions.last.timestamp).inDays : 0,
    );
  }

  /// Calculate basic emotion metrics
  Map<String, dynamic> _calculateBasicMetrics(List<EmotionalState> emotions) {
    final emotionCounts = <String, int>{};
    final moodCounts = <String, int>{};
    
    double totalArousal = 0.0;
    double totalConfidence = 0.0;
    int positiveCount = 0;
    int negativeCount = 0;

    for (final emotion in emotions) {
      // Count detected emotions
      for (final detected in emotion.detectedEmotions) {
        emotionCounts[detected.label] = (emotionCounts[detected.label] ?? 0) + 1;
      }

      // Count moods
      final moodKey = emotion.recommendedMood.toString().split('.').last;
      moodCounts[moodKey] = (moodCounts[moodKey] ?? 0) + 1;

      // Accumulate metrics
      totalArousal += emotion.arousal;
      totalConfidence += emotion.confidence;

      if (emotion.valence == EmotionalValence.positive) positiveCount++;
      if (emotion.valence == EmotionalValence.negative) negativeCount++;
    }

    final length = emotions.length;
    final stability = _calculateEmotionalStability(emotions);

    return {
      'emotionCounts': emotionCounts,
      'moodCounts': moodCounts,
      'averageArousal': length > 0 ? totalArousal / length : 0.0,
      'averageConfidence': length > 0 ? totalConfidence / length : 0.0,
      'positiveRatio': length > 0 ? positiveCount / length : 0.0,
      'negativeRatio': length > 0 ? negativeCount / length : 0.0,
      'emotionalStability': stability,
      'dominantEmotion': _findDominantEmotion(emotionCounts),
      'dominantMood': _findDominantMood(moodCounts),
    };
  }

  /// Calculate emotional stability (less variation = more stable)
  double _calculateEmotionalStability(List<EmotionalState> emotions) {
    if (emotions.length < 2) return 1.0;

    double totalVariation = 0.0;
    for (int i = 1; i < emotions.length; i++) {
      final prev = emotions[i - 1];
      final curr = emotions[i];
      
      final arousalChange = (curr.arousal - prev.arousal).abs();
      final valenceChange = prev.valence != curr.valence ? 1.0 : 0.0;
      
      totalVariation += (arousalChange + valenceChange) / 2;
    }

    return max(0.0, 1.0 - (totalVariation / (emotions.length - 1)));
  }

  /// Find the dominant emotion
  String _findDominantEmotion(Map<String, int> emotionCounts) {
    if (emotionCounts.isEmpty) return 'neutral';
    return emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Find the dominant mood
  StoryMood _findDominantMood(Map<String, int> moodCounts) {
    if (moodCounts.isEmpty) return StoryMood.neutral;
    final dominantMoodStr = moodCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    return StoryMood.values.firstWhere(
      (mood) => mood.toString().split('.').last == dominantMoodStr,
      orElse: () => StoryMood.neutral,
    );
  }

  /// Analyze emotional trends over time
  List<EmotionTrend> _analyzeTrends(List<EmotionalState> emotions) {
    if (emotions.length < 5) return [];

    final trends = <EmotionTrend>[];

    // Arousal trend
    final arousalTrend = _calculateLinearTrend(emotions.map((e) => e.arousal).toList());
    trends.add(EmotionTrend(
      type: 'arousal',
      direction: arousalTrend > 0.1 ? 'increasing' : 
                arousalTrend < -0.1 ? 'decreasing' : 'stable',
      strength: arousalTrend.abs(),
      description: _getTrendDescription('Energy levels', arousalTrend),
    ));

    // Confidence trend
    final confidenceTrend = _calculateLinearTrend(emotions.map((e) => e.confidence).toList());
    trends.add(EmotionTrend(
      type: 'confidence',
      direction: confidenceTrend > 0.1 ? 'increasing' : 
                confidenceTrend < -0.1 ? 'decreasing' : 'stable',
      strength: confidenceTrend.abs(),
      description: _getTrendDescription('Detection confidence', confidenceTrend),
    ));

    // Positivity trend (based on valence over time)
    final positivityScores = emotions.map((e) {
      switch (e.valence) {
        case EmotionalValence.positive:
          return 1.0;
        case EmotionalValence.negative:
          return -1.0;
        case EmotionalValence.neutral:
          return 0.0;
      }
    }).toList();

    final positivityTrend = _calculateLinearTrend(positivityScores);
    trends.add(EmotionTrend(
      type: 'positivity',
      direction: positivityTrend > 0.1 ? 'increasing' : 
                positivityTrend < -0.1 ? 'decreasing' : 'stable',
      strength: positivityTrend.abs(),
      description: _getTrendDescription('Positive emotions', positivityTrend),
    ));

    return trends;
  }

  /// Calculate linear trend
  double _calculateLinearTrend(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final n = values.length;
    final x = List.generate(n, (i) => i.toDouble());
    
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumX += x[i];
      sumY += values[i];
      sumXY += x[i] * values[i];
      sumX2 += x[i] * x[i];
    }
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope;
  }

  /// Get trend description
  String _getTrendDescription(String metric, double trend) {
    final direction = trend > 0.1 ? 'increasing' :
                     trend < -0.1 ? 'decreasing' : 'stable';
    final strength = trend.abs() > 0.3 ? 'significantly' :
                    trend.abs() > 0.1 ? 'slightly' : '';
    
    if (strength.isEmpty) {
      return '$metric are stable';
    }
    return '$metric are $strength $direction';
  }

  /// Analyze emotional patterns
  List<EmotionPattern> _analyzePatterns(List<EmotionalState> emotions) {
    final patterns = <EmotionPattern>[];

    // Peak emotion times
    final hourCounts = <int, int>{};
    for (final emotion in emotions) {
      final hour = emotion.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    if (hourCounts.isNotEmpty) {
      final peakHour = hourCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      patterns.add(EmotionPattern(
        type: 'peak_time',
        description: 'Most active around ${_formatHour(peakHour)}',
        data: {'hour': peakHour, 'count': hourCounts[peakHour]},
      ));
    }

    // Emotion transitions
    if (emotions.length > 1) {
      final transitions = <String>{};
      for (int i = 1; i < emotions.length; i++) {
        final prev = emotions[i - 1].detectedEmotions.firstOrNull?.label ?? 'neutral';
        final curr = emotions[i].detectedEmotions.firstOrNull?.label ?? 'neutral';
        if (prev != curr) {
          transitions.add('$prev → $curr');
        }
      }

      if (transitions.isNotEmpty) {
        patterns.add(EmotionPattern(
          type: 'transitions',
          description: 'Common transitions: ${transitions.take(3).join(', ')}',
          data: {'transitions': transitions.toList()},
        ));
      }
    }

    return patterns;
  }

  /// Analyze time-based patterns
  Map<String, dynamic> _analyzeTimePatterns(List<EmotionalState> emotions) {
    final hourlyDistribution = <int, Map<String, int>>{};
    
    for (final emotion in emotions) {
      final hour = emotion.timestamp.hour;
      hourlyDistribution[hour] ??= {};
      
      for (final detected in emotion.detectedEmotions) {
        hourlyDistribution[hour]![detected.label] = 
            (hourlyDistribution[hour]![detected.label] ?? 0) + 1;
      }
    }

    return {
      'hourlyDistribution': hourlyDistribution,
      'peakHours': _findPeakHours(hourlyDistribution),
    };
  }

  /// Find peak hours for emotions
  List<Map<String, dynamic>> _findPeakHours(Map<int, Map<String, int>> distribution) {
    final peaks = <Map<String, dynamic>>[];
    
    for (final hour in distribution.keys) {
      final emotions = distribution[hour]!;
      if (emotions.isEmpty) continue;
      
      final dominantEmotion = emotions.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      peaks.add({
        'hour': hour,
        'emotion': dominantEmotion,
        'count': emotions[dominantEmotion],
      });
    }
    
    peaks.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return peaks.take(3).toList();
  }

  /// Analyze weekly patterns
  Map<String, dynamic> _analyzeWeeklyPatterns(List<EmotionalState> emotions) {
    final dayDistribution = <int, Map<String, int>>{};
    
    for (final emotion in emotions) {
      final weekday = emotion.timestamp.weekday;
      dayDistribution[weekday] ??= {};
      
      for (final detected in emotion.detectedEmotions) {
        dayDistribution[weekday]![detected.label] = 
            (dayDistribution[weekday]![detected.label] ?? 0) + 1;
      }
    }

    return {
      'dayDistribution': dayDistribution,
      'peakDays': _findPeakDays(dayDistribution),
    };
  }

  /// Find peak days for emotions
  List<Map<String, dynamic>> _findPeakDays(Map<int, Map<String, int>> distribution) {
    final peaks = <Map<String, dynamic>>[];
    
    for (final weekday in distribution.keys) {
      final emotions = distribution[weekday]!;
      if (emotions.isEmpty) continue;
      
      final dominantEmotion = emotions.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      peaks.add({
        'weekday': weekday,
        'emotion': dominantEmotion,
        'count': emotions[dominantEmotion],
      });
    }
    
    peaks.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return peaks.take(3).toList();
  }

  /// Generate recommendations based on analysis
  List<String> _generateRecommendations(
    Map<String, dynamic> metrics,
    List<EmotionTrend> trends,
    List<EmotionPattern> patterns,
  ) {
    final recommendations = <String>[];
    
    // Stability-based recommendations
    final stability = metrics['emotionalStability'] as double;
    if (stability < 0.4) {
      recommendations.add('Consider adding more calming activities to help regulate emotions');
    }
    
    // Trend-based recommendations
    for (final trend in trends) {
      if (trend.type == 'arousal' && trend.direction == 'increasing') {
        recommendations.add('Energy levels are rising - good time for engaging activities');
      }
      if (trend.type == 'positivity' && trend.direction == 'decreasing') {
        recommendations.add('Consider scheduling mood-lifting activities');
      }
    }
    
    // Pattern-based recommendations
    for (final pattern in patterns) {
      if (pattern.type == 'peak_time') {
        recommendations.add('Schedule challenging tasks around ${_formatHour(pattern.data['hour'] as int)}');
      }
    }
    
    return recommendations;
  }

  /// Format hour for display
  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
} 