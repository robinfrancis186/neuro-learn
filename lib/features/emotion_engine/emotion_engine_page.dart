import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:js' as js;
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:html' as html;
import '../../core/services/emotion_service.dart';
import 'widgets/emotion_insights_widget.dart';

class EmotionEnginePage extends StatefulWidget {
  const EmotionEnginePage({Key? key}) : super(key: key);

  @override
  State<EmotionEnginePage> createState() => _EmotionEnginePageState();
}

class _EmotionEnginePageState extends State<EmotionEnginePage> with TickerProviderStateMixin {
  final RealEmotionService _emotionService = RealEmotionService();
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  Timer? _pollingTimer;
  
  Map<String, double> _currentEmotions = {};
  bool _isDetectionReady = false;
  String _statusMessage = 'Initializing real emotion detection...';
  String _dominantEmotion = 'neutral';
  double _confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _registerCameraView();
    _initializeEmotionEngine();
    _startEmotionPolling();
  }

  void _registerCameraView() {
    if (kIsWeb) {
      // Register the camera video element for Flutter Web
      ui.platformViewRegistry.registerViewFactory(
        'camera-video-view',
        (int viewId) {
          final videoElement = html.document.getElementById('camera-video');
          if (videoElement != null) {
            return videoElement;
          } else {
            // Create a fallback element if the original is not found
            final fallback = html.DivElement()
              ..style.width = '100%'
              ..style.height = '100%'
              ..style.backgroundColor = '#333'
              ..style.color = 'white'
              ..style.display = 'flex'
              ..style.alignItems = 'center'
              ..style.justifyContent = 'center'
              ..innerText = 'Camera loading...';
            return fallback;
          }
        },
      );
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }

  void _startEmotionPolling() {
    _pollingTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (kIsWeb) {
        _checkEmotionDetectionStatus();
      }
    });
  }

  void _checkEmotionDetectionStatus() {
    try {
      if (js.context.hasProperty('getRealEmotion')) {
        final jsResult = js.context.callMethod('getRealEmotion');
        
        if (jsResult != null) {
          final String currentEmotion = _getJsStringProperty('window.emotionDetection.currentEmotion') ?? 'neutral';
          final double confidence = _getJsNumberProperty('window.emotionDetection.confidence') ?? 0.0;
          final bool isInitialized = _getJsBoolProperty('window.emotionDetection.isInitialized') ?? false;
          final String status = _getJsStringProperty('window.emotionDetection.status') ?? 'initializing';
          
          final Map<String, dynamic> emotionData = {
            'currentEmotion': currentEmotion,
            'confidence': confidence,
            'allEmotions': _extractAllEmotions(),
            'isInitialized': isInitialized,
            'status': status,
          };
          
          _processEmotionData(emotionData);
        }
      }
    } catch (e) {
      print('❌ Error checking emotion detection status: $e');
    }
  }

  String? _getJsStringProperty(String path) {
    try {
      final result = js.context.callMethod('eval', [path]);
      return result?.toString();
    } catch (e) {
      return null;
    }
  }

  double? _getJsNumberProperty(String path) {
    try {
      final result = js.context.callMethod('eval', [path]);
      if (result != null) {
        return (result as num).toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  bool? _getJsBoolProperty(String path) {
    try {
      final result = js.context.callMethod('eval', [path]);
      if (result != null) {
        return result as bool;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Map<String, double> _extractAllEmotions() {
    Map<String, double> result = {};
    List<String> emotions = ['happy', 'sad', 'angry', 'surprise', 'fear', 'neutral'];
    
    for (String emotion in emotions) {
      try {
        final value = js.context.callMethod('eval', ['window.emotionDetection.allEmotions.$emotion || 0']);
        if (value != null) {
          result[emotion] = (value as num).toDouble();
        } else {
          result[emotion] = 0.0;
        }
      } catch (e) {
        result[emotion] = 0.0;
      }
    }
    
    return result;
  }

  void _processEmotionData(Map<String, dynamic> data) {
    final String emotion = data['currentEmotion'] ?? 'neutral';
    final double confidence = (data['confidence'] ?? 0.0).toDouble();
    final Map<String, double> allEmotions = data['allEmotions'] ?? {};
    final bool isInitialized = data['isInitialized'] ?? false;
    final String status = data['status'] ?? 'initializing';

    print('[DEBUG] _processEmotionData called with: emotion=$emotion, confidence=$confidence, allEmotions=$allEmotions, isInitialized=$isInitialized, status=$status');

    if (mounted) {
      setState(() {
        _dominantEmotion = emotion;
        _confidence = confidence;
        
        if (allEmotions.isNotEmpty) {
          _currentEmotions = allEmotions;
        } else {
          _currentEmotions = {
            'happy': 0.0,
            'sad': 0.0,
            'angry': 0.0,
            'surprise': 0.0,
            'fear': 0.0,
            'neutral': 1.0,
          };
          _currentEmotions[emotion] = confidence;
        }
        
        _isDetectionReady = isInitialized && status == 'active';
        _statusMessage = _isDetectionReady 
            ? '✅ Real-time emotion detection active'
            : '⏳ $status';
      });

      if (isInitialized && confidence > 0.1) {
        print('[DEBUG] Calling onEmotionDetected with: emotion=$emotion, confidence=$confidence, allEmotions=$allEmotions');
        _emotionService.onEmotionDetected({
          'emotion': emotion,
          'confidence': confidence,
          'allEmotions': allEmotions,
        });
      }
    }
  }

  Future<void> _initializeEmotionEngine() async {
    try {
      await _emotionService.initialize();
      
      // Start the web-based emotion detection
      _startWebEmotionDetection();
      
      if (mounted) {
        setState(() {
          _statusMessage = 'Emotion service initialized';
        });
      }
    } catch (e) {
      print('Error initializing emotion service: $e');
    }
  }

  void _startWebEmotionDetection() {
    if (kIsWeb) {
      try {
        js.context.callMethod('startEmotionDetection');
        print('Started web emotion detection');
      } catch (e) {
        print('Error starting web emotion detection: $e');
      }
    }
  }

  void _stopWebEmotionDetection() {
    if (kIsWeb) {
      try {
        js.context.callMethod('stopEmotionDetection');
        print('Stopped web emotion detection');
      } catch (e) {
        print('Error stopping web emotion detection: $e');
      }
    }
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Colors.amber;
      case 'sad':
        return Colors.blue;
      case 'angry':
        return Colors.red;
      case 'surprise':
        return Colors.orange;
      case 'fear':
        return Colors.purple;
      case 'neutral':
      default:
        return Colors.grey;
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
      case 'surprise':
        return Icons.new_releases;
      case 'fear':
        return Icons.warning;
      case 'neutral':
      default:
        return Icons.sentiment_neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Emotion Engine',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E3192),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Card
            Container(
              width: double.infinity,
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
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Icon(
                          _isDetectionReady ? Icons.videocam : Icons.hourglass_empty,
                          color: _isDetectionReady ? Colors.green : Colors.orange,
                          size: 28,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Real AI Emotion Detection',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Main Content Row - Detection + Analytics
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side - Live Detection
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildLiveCameraSection(),
                      const SizedBox(height: 16),
                      _buildCurrentEmotionDisplay(),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Right Side - Analytics
                Expanded(
                  flex: 1,
                  child: EmotionInsightsWidget(
                    studentId: 'default_student',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Bottom - Real-time Emotion Distribution
            _buildEmotionDistribution(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveCameraSection() {
    return Container(
      width: double.infinity,
      height: 300,
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
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E3192),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Live Camera Processing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: _buildCameraPreview(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
      ),
      child: Stack(
        children: [
          // Live camera feed
          if (kIsWeb)
            Container(
              width: double.infinity,
              height: double.infinity,
              child: HtmlElementView(
                viewType: 'camera-video-view',
              ),
            ),
          // Fallback for non-web platforms
          if (!kIsWeb)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.videocam,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Camera Preview',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Web platform required for camera',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          // Grid overlay for camera-like appearance
          CustomPaint(
            size: Size.infinite,
            painter: CameraGridPainter(),
          ),
          // Real-time emotion overlay
          Positioned(
            bottom: 15,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_getEmotionEmoji(_dominantEmotion)} ${_dominantEmotion.toUpperCase()} - ${(_confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      case 'surprise':
        return '😲';
      case 'fear':
        return '😨';
      case 'neutral':
      default:
        return '😐';
    }
  }

  Widget _buildCurrentEmotionDisplay() {
    return Container(
      width: double.infinity,
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
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E3192),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Text(
              'Current Emotion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _getEmotionColor(_dominantEmotion).withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getEmotionColor(_dominantEmotion),
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          _getEmotionIcon(_dominantEmotion),
                          color: _getEmotionColor(_dominantEmotion),
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  _dominantEmotion.toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getEmotionColor(_dominantEmotion),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionDistribution() {
    return Container(
      width: double.infinity,
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
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E3192),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Text(
              'Real-Time Emotion Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _currentEmotions.entries.map((entry) {
                final emotion = entry.key;
                final confidence = entry.value;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getEmotionColor(emotion).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getEmotionIcon(emotion),
                        color: _getEmotionColor(emotion),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emotion.toUpperCase(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: confidence,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getEmotionColor(emotion),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getEmotionColor(emotion),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pollingTimer?.cancel();
    
    // Stop web emotion detection when leaving the page
    _stopWebEmotionDetection();
    
    super.dispose();
  }
}

class CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;

    // Draw rule of thirds grid
    // Vertical lines
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(2 * size.width / 3, 0),
      Offset(2 * size.width / 3, size.height),
      paint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, 2 * size.height / 3),
      Offset(size.width, 2 * size.height / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 