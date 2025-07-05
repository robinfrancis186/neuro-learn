import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../shared/themes/app_theme.dart';
import '../../../../shared/widgets/animated_card.dart';
import '../../../../shared/providers/app_providers.dart';

class SubjectStoryPage extends ConsumerStatefulWidget {
  final String subject;
  final String subjectTitle;
  final Color subjectColor;
  final IconData subjectIcon;

  const SubjectStoryPage({
    super.key,
    required this.subject,
    required this.subjectTitle,
    required this.subjectColor,
    required this.subjectIcon,
  });

  @override
  ConsumerState<SubjectStoryPage> createState() => _SubjectStoryPageState();
}

class _SubjectStoryPageState extends ConsumerState<SubjectStoryPage> {
  bool _isGenerating = false;
  String? _generatedStory;
  String? _error;

  // Form controllers
  final _topicController = TextEditingController();
  final _memoryController = TextEditingController();
  final _charactersController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setDefaultValues();
  }

  void _setDefaultValues() {
    // Set subject-specific default values
    switch (widget.subject) {
      case 'mathematics':
        _topicController.text = 'Learn addition: 2 + 2 = 4';
        _memoryController.text = 'Recently went to the park and saw children playing';
        _charactersController.text = 'Leo, Maya';
        break;
      case 'science':
        _topicController.text = 'Learn about plant growth and photosynthesis';
        _memoryController.text = 'Helped mom water the garden plants';
        _charactersController.text = 'Dr. Green, Sunny the Sunflower';
        break;
      case 'reading':
        _topicController.text = 'Practice reading simple words and sentences';
        _memoryController.text = 'Visited the library with family';
        _charactersController.text = 'Bookworm Ben, Story Stella';
        break;
      case 'social_skills':
        _topicController.text = 'Learn about sharing and friendship';
        _memoryController.text = 'Had a playdate with friends from school';
        _charactersController.text = 'Friendly Fox, Caring Cat';
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStudent = ref.watch(currentStudentProvider);
    
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar with subject-specific gradient
            _buildAppBar(),
            
            // Main content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Story input form
                    _buildStoryForm(currentStudent?.name ?? 'Student'),
                    
                    const SizedBox(height: 32),
                    
                    // Generate button
                    _buildGenerateButton(),
                    
                    const SizedBox(height: 32),
                    
                    // Story display area
                    if (_generatedStory != null) _buildStoryDisplay(),
                    if (_error != null) _buildErrorDisplay(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.subjectColor.withOpacity(0.8),
                widget.subjectColor,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        widget.subjectIcon,
                        color: Colors.white,
                        size: 48,
                      ),
                    ).animate().scale(
                      begin: Offset(0.8, 0.8),
                      end: Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.subjectTitle} Story',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                          const SizedBox(height: 8),
                          Text(
                            'Create a personalized learning story',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildStoryForm(String studentName) {
    return AnimatedCard(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.subjectColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_note,
                  color: widget.subjectColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Story Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.highContrastDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Student name display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.subjectColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: widget.subjectColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Student: $studentName',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: widget.subjectColor,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Topic input
            _buildInputField(
              controller: _topicController,
              label: 'Learning Topic',
              hint: 'What should the student learn?',
              icon: Icons.lightbulb_outline,
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // Memory context input
            _buildInputField(
              controller: _memoryController,
              label: 'Memory Context',
              hint: 'Recent experiences or memories to include',
              icon: Icons.memory,
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Characters input
            _buildInputField(
              controller: _charactersController,
              label: 'Story Characters',
              hint: 'Character names separated by commas',
              icon: Icons.people_outline,
            ),
          ],
        ),
      ),
    ).animate().slide(
      begin: Offset(0, 0.3),
      end: Offset.zero,
      duration: 600.ms,
    ).fadeIn();
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: widget.subjectColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.highContrastDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.mediumGray),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.subjectColor, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.lightGray.withOpacity(0.3),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: AnimatedCard(
        onTap: _isGenerating ? null : _generateStory,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.subjectColor,
                widget.subjectColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.subjectColor.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isGenerating)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(
                  Icons.auto_stories,
                  color: Colors.white,
                  size: 28,
                ),
              const SizedBox(width: 12),
              Text(
                _isGenerating ? 'Generating Story...' : 'Generate Story',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slide(
      begin: Offset(0, 0.5),
      end: Offset.zero,
      delay: 200.ms,
      duration: 600.ms,
    ).fadeIn();
  }

  // Helper: Call /clone API and play audio
  Future<void> _readAloudStory() async {
    if (_generatedStory == null || _isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      var uri = Uri.parse('http://localhost:8000/clone');
      var request = http.MultipartRequest('POST', uri);
      request.fields['text'] = _generatedStory!;
      request.fields['speed'] = '1';
      request.fields['language'] = 'english';
      request.fields['output_filename'] = 'readaloud';
      // reference_audio omitted to use backend default
      print('Sending fields: \\${request.fields}');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      print('Response status: \\${response.statusCode}');
      print('Response body: \\${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['audio_base64'] != null) {
          final dataUrl = 'data:audio/wav;base64,${data['audio_base64']}';
          final player = AudioPlayer();
          await player.play(UrlSource(dataUrl));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate audio.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API error: \\${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Exception in _readAloudStory: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playback error: $e')),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Widget _buildStoryDisplay() {
    return AnimatedCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.subjectColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.subjectColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  color: widget.subjectColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Personalized Story',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.highContrastDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.subjectColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.subjectColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                _generatedStory!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  fontSize: 16,
                  color: AppTheme.highContrastDark,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: AnimatedCard(
                    onTap: _generateStory,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.subjectColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.subjectColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh,
                            color: widget.subjectColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Generate New',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: widget.subjectColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedCard(
                    onTap: (_generatedStory == null || _isGenerating) ? null : _readAloudStory,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.subjectColor,
                            widget.subjectColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isGenerating)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          else ...[
                            const Icon(
                              Icons.volume_up,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Read Aloud',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slide(
      begin: Offset(0, 0.3),
      end: Offset.zero,
      delay: 300.ms,
      duration: 600.ms,
    ).fadeIn();
  }

  Widget _buildErrorDisplay() {
    return AnimatedCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.shade200,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade600,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AnimatedCard(
              onTap: () {
                setState(() {
                  _error = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Try Again',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().shake(duration: 600.ms);
  }

  Future<void> _generateStory() async {
    final currentStudent = ref.read(currentStudentProvider);
    if (currentStudent == null) return;

    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedStory = null;
    });

    try {
      // Parse characters from comma-separated string
      final characters = _charactersController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final requestBody = {
        'student_name': currentStudent.name,
        'subject': '${widget.subjectTitle}: ${_topicController.text}',
        'topic_to_be_reached': _topicController.text,
        'memory_context': _memoryController.text,
        'characters': characters,
      };

      print('Sending request: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('http://localhost:8000/storygeneration'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: json.encode(requestBody),
        encoding: Encoding.getByName('utf-8'),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        String storyContent = responseData['content'] ?? '';
        
        // Clean up special characters and encoding issues
        storyContent = _cleanStoryText(storyContent);
        
        setState(() {
          _generatedStory = storyContent;
        });
      } else {
        throw Exception('Failed to generate story: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating story: $e');
      setState(() {
        _error = 'Failed to generate story. Please check your connection and try again.\n\nError: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  String _cleanStoryText(String text) {
    // Remove common encoding artifacts and special characters
    String cleanedText = text
        // Fix common Unicode issues
        .replaceAll('â', "'")  // Smart apostrophe
        .replaceAll('â', "'")  // Another apostrophe variant
        .replaceAll('â', '"')  // Smart quote left
        .replaceAll('â', '"')  // Smart quote right
        .replaceAll('â¦', '...')  // Ellipsis
        .replaceAll('â', '-')  // Em dash
        .replaceAll('â', '-')  // En dash
        .replaceAll('Â', '')   // Non-breaking space artifacts
        .replaceAll('Ã', '')   // Common encoding artifact
        
        // Fix newline and spacing issues
        .replaceAll(r'\n', '\n')  // Ensure proper newlines
        .replaceAll(RegExp(r'\s+'), ' ')  // Multiple spaces to single
        .trim();

    // Split into sentences and clean each
    List<String> sentences = cleanedText.split(RegExp(r'[.!?]+'));
    List<String> cleanedSentences = [];
    
    for (String sentence in sentences) {
      String cleaned = sentence.trim();
      if (cleaned.isNotEmpty) {
        // Ensure sentence starts with capital letter
        if (cleaned.length > 0) {
          cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
        }
        cleanedSentences.add(cleaned);
      }
    }
    
    // Join sentences back with proper punctuation
    String result = cleanedSentences.join('. ');
    
    // Add final punctuation if missing
    if (result.isNotEmpty && !result.endsWith('.') && !result.endsWith('!') && !result.endsWith('?')) {
      result += '.';
    }
    
    return result;
  }

  @override
  void dispose() {
    _topicController.dispose();
    _memoryController.dispose();
    _charactersController.dispose();
    super.dispose();
  }
} 