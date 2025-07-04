import 'package:flutter/material.dart';
import '../../../core/services/emotion_service.dart';
import '../../../core/services/emotion_history_service.dart';
import '../../../core/models/emotional_state.dart';
import '../../../shared/widgets/neuro_card.dart';

class EmotionInsightsWidget extends StatefulWidget {
  final String studentId;

  const EmotionInsightsWidget({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  State<EmotionInsightsWidget> createState() => _EmotionInsightsWidgetState();
}

class _EmotionInsightsWidgetState extends State<EmotionInsightsWidget> {
  final RealEmotionService _emotionService = RealEmotionService();
  final EmotionHistoryService _historyService = EmotionHistoryService();
  Map<String, dynamic> _analytics = {};
  List<EmotionalState> _recentHistory = [];
  bool _isLoading = true;

  // Define emotion colors
  final Map<String, Color> _emotionColors = {
    'happy': Color(0xFFFFD93D),    // Bright yellow
    'sad': Color(0xFF6C9BCF),      // Soft blue
    'angry': Color(0xFFFF6B6B),    // Soft red
    'surprise': Color(0xFFB088F9), // Soft purple
    'fear': Color(0xFFFF9F45),     // Soft orange
    'neutral': Color(0xFF98A8B9),  // Soft gray
  };

  @override
  void initState() {
    super.initState();
    _initializeServices();
    
    // Listen to emotion history updates
    _historyService.historyStream.listen((history) {
      if (mounted) {
        setState(() {
          _recentHistory = history
              .where((state) => state.studentId == widget.studentId)
              .take(10)
              .toList();
        });
      }
    });
    
    // Listen to real-time emotion updates
    _emotionService.emotionStream.listen((emotionData) {
      if (mounted && emotionData['isRealDetection'] == true) {
        _loadAnalytics();
      }
    });
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize both services
      await _emotionService.initialize();
      await _historyService.initialize();
      
      // Set student ID for tracking
      _emotionService.setStudentId(widget.studentId);
      
      // Load initial data
      await _loadAnalytics();
      
      print('✅ Emotion services initialized for student: ${widget.studentId}');
    } catch (e) {
      print('❌ Error initializing emotion services: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Get recent history
      final history = await _historyService.getHistory(
        studentId: widget.studentId,
        limit: 10,
      );
      
      // Calculate emotion percentages
      final emotionCounts = <String, int>{};
      for (var state in history) {
        for (var emotion in state.detectedEmotions) {
          emotionCounts[emotion.label] = (emotionCounts[emotion.label] ?? 0) + 1;
        }
      }
      
      if (mounted) {
        setState(() {
          _analytics = {
            'emotionCounts': emotionCounts,
            'totalEmotions': history.length,
          };
          _recentHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading analytics: $e');
      if (mounted) {
        setState(() {
          _analytics = {
            'emotionCounts': <String, int>{},
            'totalEmotions': 0,
          };
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return NeuroCard(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading emotion insights...'),
            ],
          ),
        ),
      );
    }

    return NeuroCard(
      child: Container(
        height: 600,
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            _buildBarChartSection(),
            SizedBox(height: 24),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.psychology_outlined, size: 24, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text(
              'Emotional Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          'Track emotional patterns and responses over time',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBarChartSection() {
    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emotion Distribution',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Expanded(child: _buildEmotionBarChart()),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Last ${_recentHistory.length} entries',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(child: _buildEmotionHistory()),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionBarChart() {
    if (_recentHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No emotion data available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final emotionCounts = _analytics['emotionCounts'] as Map<String, int>;
    final totalEmotions = _analytics['totalEmotions'] as int;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _emotionColors.keys.map((emotion) {
        final count = emotionCounts[emotion] ?? 0;
        final percentage = totalEmotions > 0 ? count / totalEmotions : 0.0;
        return _buildBar(emotion, percentage, count);
      }).toList(),
    );
  }

  Widget _buildBar(String emotion, double percentage, int count) {
    // Calculate height with a maximum cap and scale factor
    final maxHeight = 100.0;
    final minHeight = 4.0;
    final scaleFactor = 0.8; // Reduce overall height by 20%
    
    // Scale the height and ensure it doesn't exceed maxHeight
    final height = percentage > 0 
        ? (maxHeight * percentage * scaleFactor).clamp(minHeight, maxHeight)
        : minHeight;
    
    return Tooltip(
      message: '$emotion: ${(percentage * 100).toStringAsFixed(1)}% ($count times)',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: height,
            decoration: BoxDecoration(
              color: _emotionColors[emotion],
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            emotion,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${(percentage * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionHistory() {
    if (_recentHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No recent emotions recorded',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _recentHistory.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (context, index) {
        final state = _recentHistory[index];
        final emotion = state.detectedEmotions.isNotEmpty 
            ? state.detectedEmotions.first 
            : null;
        
        return Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: emotion != null 
                      ? _emotionColors[emotion.label]?.withOpacity(0.2)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: emotion != null 
                          ? _emotionColors[emotion.label]
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emotion?.label ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${state.timestamp.hour}:${state.timestamp.minute.toString().padLeft(2, '0')} - ${state.timestamp.day}/${state.timestamp.month}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(emotion?.confidence ?? 0 * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 