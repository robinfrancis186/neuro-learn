import 'package:hive/hive.dart';
import 'emotional_state.dart';

@HiveType(typeId: 16)
class EmotionAnalytics extends HiveObject {
  @HiveField(0)
  final String studentId;

  @HiveField(1)
  final int totalEmotions;

  @HiveField(2)
  final Map<String, int> emotionCounts;

  @HiveField(3)
  final Map<String, int> moodCounts;

  @HiveField(4)
  final double averageArousal;

  @HiveField(5)
  final double averageConfidence;

  @HiveField(6)
  final double positiveRatio;

  @HiveField(7)
  final double negativeRatio;

  @HiveField(8)
  final double emotionalStability;

  @HiveField(9)
  final String dominantEmotion;

  @HiveField(10)
  final StoryMood dominantMood;

  @HiveField(11)
  final List<EmotionTrend> trends;

  @HiveField(12)
  final List<EmotionPattern> patterns;

  @HiveField(13)
  final Map<String, dynamic> timePatterns;

  @HiveField(14)
  final Map<String, dynamic> weeklyPatterns;

  @HiveField(15)
  final List<String> recommendations;

  @HiveField(16)
  final DateTime generatedAt;

  @HiveField(17)
  final int periodDays;

  EmotionAnalytics({
    required this.studentId,
    required this.totalEmotions,
    required this.emotionCounts,
    required this.moodCounts,
    required this.averageArousal,
    required this.averageConfidence,
    required this.positiveRatio,
    required this.negativeRatio,
    required this.emotionalStability,
    required this.dominantEmotion,
    required this.dominantMood,
    required this.trends,
    required this.patterns,
    required this.timePatterns,
    required this.weeklyPatterns,
    required this.recommendations,
    required this.generatedAt,
    required this.periodDays,
  });

  factory EmotionAnalytics.empty(String studentId) {
    return EmotionAnalytics(
      studentId: studentId,
      totalEmotions: 0,
      emotionCounts: {},
      moodCounts: {},
      averageArousal: 0.0,
      averageConfidence: 0.0,
      positiveRatio: 0.0,
      negativeRatio: 0.0,
      emotionalStability: 1.0,
      dominantEmotion: 'neutral',
      dominantMood: StoryMood.neutral,
      trends: [],
      patterns: [],
      timePatterns: {},
      weeklyPatterns: {},
      recommendations: [],
      generatedAt: DateTime.now(),
      periodDays: 0,
    );
  }
}

@HiveType(typeId: 17)
class EmotionTrend extends HiveObject {
  @HiveField(0)
  final String type;

  @HiveField(1)
  final String direction;

  @HiveField(2)
  final double strength;

  @HiveField(3)
  final String description;

  EmotionTrend({
    required this.type,
    required this.direction,
    required this.strength,
    required this.description,
  });
}

@HiveType(typeId: 18)
class EmotionPattern extends HiveObject {
  @HiveField(0)
  final String type;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final Map<String, dynamic> data;

  EmotionPattern({
    required this.type,
    required this.description,
    required this.data,
  });
} 