import 'dart:async';
import 'package:hive/hive.dart';
import '../models/emotional_state.dart';
import '../models/emotion_analytics.dart';

/// Comprehensive emotion history tracking and analytics service
class EmotionHistoryService {
  static final EmotionHistoryService _instance = EmotionHistoryService._internal();
  factory EmotionHistoryService() => _instance;
  EmotionHistoryService._internal();

  static const String _boxName = 'emotion_history';
  static const String _analyticsBoxName = 'emotion_analytics';
  static const String _sessionBoxName = 'emotion_sessions';
  
  Box<EmotionalState>? _emotionBox;
  Box<Map<dynamic, dynamic>>? _analyticsBox;
  Box<Map<dynamic, dynamic>>? _sessionBox;
  
  final StreamController<List<EmotionalState>> _historyStreamController =
      StreamController<List<EmotionalState>>.broadcast();
  
  final StreamController<EmotionAnalytics> _analyticsStreamController =
      StreamController<EmotionAnalytics>.broadcast();
  
  Stream<List<EmotionalState>> get historyStream => _historyStreamController.stream;
  Stream<EmotionAnalytics> get analyticsStream => _analyticsStreamController.stream;
  
  bool _isInitialized = false;
  Timer? _analyticsTimer;
  
  /// Initialize the emotion history service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _emotionBox = await Hive.openBox<EmotionalState>(_boxName);
      _analyticsBox = await Hive.openBox<Map<dynamic, dynamic>>(_analyticsBoxName);
      _sessionBox = await Hive.openBox<Map<dynamic, dynamic>>(_sessionBoxName);
      
      _isInitialized = true;
      
      // Start periodic analytics updates
      _startAnalyticsTimer();
      
      // Emit initial data
      _emitCurrentHistory();
      
      print('✅ Emotion History Service initialized');
    } catch (e) {
      print('❌ Error initializing Emotion History Service: $e');
    }
  }
  
  /// Save an emotional state to history
  Future<void> saveEmotionalState(EmotionalState state) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _emotionBox?.put(state.id, state);
      
      // Update current session
      await _updateCurrentSession(state);
      
      // Emit updated history
      _emitCurrentHistory();
      
      print('📊 Emotion saved: ${state.detectedEmotions.isNotEmpty ? state.detectedEmotions.first.label : 'unknown'}');
    } catch (e) {
      print('❌ Error saving emotional state: $e');
    }
  }
  
  /// Get emotion history for a specific student
  Future<List<EmotionalState>> getHistory({
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      var emotions = _emotionBox?.values
          .where((emotion) => emotion.studentId == studentId)
          .toList() ?? [];
      
      // Filter by date range
      if (startDate != null) {
        emotions = emotions.where((e) => e.timestamp.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        emotions = emotions.where((e) => e.timestamp.isBefore(endDate)).toList();
      }
      
      // Sort by timestamp (newest first)
      emotions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Limit results
      if (limit != null && emotions.length > limit) {
        emotions = emotions.take(limit).toList();
      }
      
      return emotions;
    } catch (e) {
      print('❌ Error getting emotion history: $e');
      return [];
    }
  }
  
  /// Start periodic analytics updates
  void _startAnalyticsTimer() {
    _analyticsTimer?.cancel();
    _analyticsTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _updateAnalytics();
    });
  }
  
  /// Update current session with new emotional state
  Future<void> _updateCurrentSession(EmotionalState state) async {
    final sessionKey = _getSessionKey(state.timestamp);
    final existingSession = _sessionBox?.get(sessionKey) as Map<dynamic, dynamic>?;
    
    if (existingSession != null) {
      existingSession['states'] = [...(existingSession['states'] as List), state.id];
      existingSession['lastUpdated'] = state.timestamp.toIso8601String();
      await _sessionBox?.put(sessionKey, existingSession);
    } else {
      await _sessionBox?.put(sessionKey, {
        'studentId': state.studentId,
        'date': state.timestamp.toIso8601String(),
        'states': [state.id],
        'lastUpdated': state.timestamp.toIso8601String(),
      });
    }
  }
  
  /// Get session key for a timestamp
  String _getSessionKey(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month}-${timestamp.day}';
  }
  
  /// Emit current history to stream
  void _emitCurrentHistory() {
    if (!_isInitialized) return;
    
    final history = _emotionBox?.values.toList() ?? [];
    _historyStreamController.add(history);
  }
  
  /// Update analytics
  Future<void> _updateAnalytics() async {
    if (!_isInitialized) return;
    
    try {
      final history = _emotionBox?.values.toList() ?? [];
      if (history.isEmpty) return;
      
      // Group by student
      final studentGroups = <String, List<EmotionalState>>{};
      for (final state in history) {
        studentGroups.putIfAbsent(state.studentId, () => []).add(state);
      }
      
      // Generate analytics for each student
      for (final entry in studentGroups.entries) {
        final studentId = entry.key;
        final studentHistory = entry.value;
        
        // Save analytics
        await _analyticsBox?.put(studentId, {
          'studentId': studentId,
          'lastUpdated': DateTime.now().toIso8601String(),
          'totalStates': studentHistory.length,
          'lastState': studentHistory.last.id,
        });
      }
    } catch (e) {
      print('❌ Error updating analytics: $e');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _analyticsTimer?.cancel();
    _historyStreamController.close();
    _analyticsStreamController.close();
  }
}