import 'package:flutter/material.dart';
import '../../../core/models/emotional_state.dart';
import '../../../core/services/emotion_service.dart';

class MoodAnalyticsPanel extends StatefulWidget {
  final List<EmotionalState> emotionHistory;
  final String studentId;

  const MoodAnalyticsPanel({
    super.key,
    required this.emotionHistory,
    required this.studentId,
  });

  @override
  State<MoodAnalyticsPanel> createState() => _MoodAnalyticsPanelState();
}

class _MoodAnalyticsPanelState extends State<MoodAnalyticsPanel> {
  bool _showDetailedAnalysis = false;

  @override
  Widget build(BuildContext context) {
    final analytics = EmotionalAnalytics.analyzeEmotionalPattern(widget.emotionHistory);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Mood Analytics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showDetailedAnalysis = !_showDetailedAnalysis;
                  });
                },
                icon: Icon(
                  _showDetailedAnalysis ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Quick overview
          _buildQuickOverview(analytics),
          
          if (_showDetailedAnalysis) ...[
            const SizedBox(height: 20),
            _buildDetailedAnalysis(analytics),
          ],
          
          const SizedBox(height: 16),
          _buildRecommendations(analytics),
        ],
      ),
    );
  }

  Widget _buildQuickOverview(Map<String, dynamic> analytics) {
    final emotionCounts = analytics['emotionCounts'] as Map<String, int>? ?? {};
    final positiveRatio = analytics['positiveRatio'] as double? ?? 0.0;
    final emotionalStability = analytics['emotionalStability'] as double? ?? 1.0;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Positive Emotions',
                '${(positiveRatio * 100).toInt()}%',
                Colors.green,
                Icons.sentiment_satisfied,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Stability',
                '${(emotionalStability * 100).toInt()}%',
                Colors.blue,
                Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Emotion timeline
        if (widget.emotionHistory.isNotEmpty) ...[
          Text(
            'Recent Emotion Timeline',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildEmotionTimeline(),
        ],
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionTimeline() {
    final recentEmotions = widget.emotionHistory.take(10).toList();
    
    return Container(
      height: 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: recentEmotions.map((emotion) {
          final primaryEmotion = emotion.detectedEmotions.isNotEmpty 
              ? emotion.detectedEmotions.first 
              : null;
          
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _getEmotionColor(primaryEmotion?.label).withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Icon(
                  _getEmotionIcon(primaryEmotion?.label),
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailedAnalysis(Map<String, dynamic> analytics) {
    final emotionCounts = analytics['emotionCounts'] as Map<String, int>? ?? {};
    final moodCounts = analytics['moodCounts'] as Map<String, int>? ?? {};
    final averageArousal = analytics['averageArousal'] as double? ?? 0.5;
    final dominantMood = analytics['dominantMood'] as String? ?? 'neutral';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Analysis',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Emotion breakdown
        if (emotionCounts.isNotEmpty) ...[
          Text(
            'Emotion Distribution',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...emotionCounts.entries.map((entry) => 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getEmotionColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key.toUpperCase(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${entry.value}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Key metrics
        Row(
          children: [
            Expanded(
              child: _buildAnalysisMetric(
                'Average Arousal',
                '${(averageArousal * 100).toInt()}%',
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalysisMetric(
                'Dominant Mood',
                dominantMood.split('.').last.toUpperCase(),
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisMetric(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(Map<String, dynamic> analytics) {
    final recommendations = _generateRecommendations(analytics);
    
    if (recommendations.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...recommendations.map((rec) => 
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: rec['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: rec['color'].withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  rec['icon'],
                  color: rec['color'],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec['text'],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _generateRecommendations(Map<String, dynamic> analytics) {
    final recommendations = <Map<String, dynamic>>[];
    final positiveRatio = analytics['positiveRatio'] as double? ?? 0.0;
    final negativeRatio = analytics['negativeRatio'] as double? ?? 0.0;
    final emotionalStability = analytics['emotionalStability'] as double? ?? 1.0;
    
    // Check if calming intervention is needed
    if (EmotionService.instance.needsCalmingIntervention(widget.studentId)) {
      recommendations.add({
        'icon': Icons.spa,
        'color': Colors.green,
        'text': 'Consider calming activities or stories to help regulate emotions.',
      });
    }
    
    // Check if excitement boost is needed
    if (EmotionService.instance.needsExcitementBoost(widget.studentId)) {
      recommendations.add({
        'icon': Icons.celebration,
        'color': Colors.orange,
        'text': 'Try exciting stories or activities to boost engagement.',
      });
    }
    
    // Emotional stability recommendation
    if (emotionalStability < 0.6) {
      recommendations.add({
        'icon': Icons.balance,
        'color': Colors.blue,
        'text': 'Emotional patterns show variability. Consider consistent routine.',
      });
    }
    
    // Positive emotion encouragement
    if (positiveRatio > 0.7) {
      recommendations.add({
        'icon': Icons.star,
        'color': Colors.amber,
        'text': 'Great emotional balance! Continue with current approach.',
      });
    }
    
    // General wellness check
    if (negativeRatio > 0.6) {
      recommendations.add({
        'icon': Icons.health_and_safety,
        'color': Colors.red,
        'text': 'Consider checking in with student about wellbeing.',
      });
    }
    
    return recommendations;
  }

  Color _getEmotionColor(String? emotion) {
    switch (emotion?.toLowerCase()) {
      case 'happiness':
        return Colors.amber;
      case 'sadness':
        return Colors.blue;
      case 'anger':
        return Colors.red;
      case 'fear':
        return Colors.purple;
      case 'surprise':
        return Colors.orange;
      case 'disgust':
        return Colors.brown;
      case 'contempt':
        return Colors.indigo;
      case 'neutral':
      default:
        return Colors.grey;
    }
  }

  IconData _getEmotionIcon(String? emotion) {
    switch (emotion?.toLowerCase()) {
      case 'happiness':
        return Icons.sentiment_very_satisfied;
      case 'sadness':
        return Icons.sentiment_very_dissatisfied;
      case 'anger':
        return Icons.sentiment_dissatisfied;
      case 'fear':
        return Icons.warning;
      case 'surprise':
        return Icons.error_outline;
      case 'disgust':
        return Icons.sick;
      case 'contempt':
        return Icons.thumb_down;
      case 'neutral':
      default:
        return Icons.sentiment_neutral;
    }
  }
} 