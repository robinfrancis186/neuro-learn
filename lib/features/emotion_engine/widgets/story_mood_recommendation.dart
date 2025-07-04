import 'package:flutter/material.dart';
import '../../../core/models/emotional_state.dart';

class StoryMoodRecommendation extends StatelessWidget {
  final EmotionalState emotionalState;
  final Function(StoryMood) onStoryRequested;

  const StoryMoodRecommendation({
    super.key,
    required this.emotionalState,
    required this.onStoryRequested,
  });

  @override
  Widget build(BuildContext context) {
    final recommendedMood = emotionalState.recommendedMood;
    final intervention = _getInterventionType();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getMoodColor(recommendedMood).withOpacity(0.1),
            _getMoodColor(recommendedMood).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getMoodColor(recommendedMood).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getMoodColor(recommendedMood).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getMoodIcon(recommendedMood),
                  size: 28,
                  color: _getMoodColor(recommendedMood),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Story Mood',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _getMoodDisplayName(recommendedMood),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _getMoodColor(recommendedMood),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Intervention explanation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  intervention['icon'] as IconData,
                  color: intervention['color'] as Color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    intervention['description'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Story examples
          Text(
            'Story Examples:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          ...(_getStoryExamples(recommendedMood).map((example) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _getMoodColor(recommendedMood),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      example,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onStoryRequested(recommendedMood),
                  icon: const Icon(Icons.auto_stories),
                  label: Text('Generate ${_getMoodDisplayName(recommendedMood)} Story'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getMoodColor(recommendedMood),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showAlternativeMoods(context),
                icon: const Icon(Icons.tune),
                label: const Text('More Options'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _getMoodColor(recommendedMood),
                  side: BorderSide(color: _getMoodColor(recommendedMood)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getInterventionType() {
    final primaryEmotion = emotionalState.detectedEmotions.isNotEmpty 
        ? emotionalState.detectedEmotions.first.label.toLowerCase()
        : 'neutral';
    
    switch (primaryEmotion) {
      case 'sadness':
        return {
          'icon': Icons.favorite,
          'color': Colors.pink,
          'description': 'Comfort stories help process emotions and provide emotional support.',
        };
      case 'anger':
        return {
          'icon': Icons.spa,
          'color': Colors.green,
          'description': 'Calming stories promote emotional regulation and mindfulness.',
        };
      case 'fear':
        return {
          'icon': Icons.shield,
          'color': Colors.blue,
          'description': 'Comforting stories build confidence and reduce anxiety.',
        };
      case 'happiness':
        return {
          'icon': Icons.celebration,
          'color': Colors.orange,
          'description': 'Adventure stories channel positive energy into learning.',
        };
      case 'surprise':
        return {
          'icon': Icons.explore,
          'color': Colors.purple,
          'description': 'Adventure stories satisfy curiosity and encourage exploration.',
        };
      case 'neutral':
        return {
          'icon': Icons.palette,
          'color': Colors.indigo,
          'description': 'Creative stories stimulate imagination and engagement.',
        };
      default:
        return {
          'icon': Icons.balance,
          'color': Colors.grey,
          'description': 'Balanced stories provide appropriate emotional support.',
        };
    }
  }

  List<String> _getStoryExamples(StoryMood mood) {
    switch (mood) {
      case StoryMood.calm:
        return [
          'A gentle journey through a peaceful garden',
          'Learning numbers while counting raindrops',
          'A quiet adventure in a cozy library',
        ];
      case StoryMood.excitement:
        return [
          'Racing through space to learn about planets',
          'Solving math puzzles to save the kingdom',
          'High-energy treasure hunt with letters',
        ];
      case StoryMood.comfort:
        return [
          'A warm story about friendship and kindness',
          'Learning with supportive animal friends',
          'Overcoming challenges with family help',
        ];
      case StoryMood.adventure:
        return [
          'Exploring underwater worlds while learning',
          'Time-traveling to discover history',
          'Mysterious quests that teach new skills',
        ];
      case StoryMood.creative:
        return [
          'Building magical inventions with science',
          'Creating art while learning colors and shapes',
          'Imaginative stories that spark creativity',
        ];
      case StoryMood.social:
        return [
          'Making new friends in different countries',
          'Learning communication through fun games',
          'Collaborative adventures that teach teamwork',
        ];
      case StoryMood.neutral:
        return [
          'Balanced stories that adapt to your mood',
          'Educational adventures with steady pacing',
          'Stories that grow with your learning needs',
        ];
    }
  }

  void _showAlternativeMoods(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Choose Story Mood',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: StoryMood.values.map((mood) => 
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getMoodColor(mood).withOpacity(0.2),
                        child: Icon(
                          _getMoodIcon(mood),
                          color: _getMoodColor(mood),
                        ),
                      ),
                      title: Text(_getMoodDisplayName(mood)),
                      subtitle: Text(_getMoodDescription(mood)),
                      trailing: mood == emotionalState.recommendedMood
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        onStoryRequested(mood);
                      },
                    ),
                  ),
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodDisplayName(StoryMood mood) {
    switch (mood) {
      case StoryMood.calm:
        return 'Calming';
      case StoryMood.excitement:
        return 'Exciting';
      case StoryMood.comfort:
        return 'Comforting';
      case StoryMood.adventure:
        return 'Adventure';
      case StoryMood.creative:
        return 'Creative';
      case StoryMood.social:
        return 'Social';
      case StoryMood.neutral:
        return 'Neutral';
    }
  }

  String _getMoodDescription(StoryMood mood) {
    switch (mood) {
      case StoryMood.calm:
        return 'Soothing stories for relaxation and focus';
      case StoryMood.excitement:
        return 'High-energy stories for motivation';
      case StoryMood.comfort:
        return 'Warm stories for emotional support';
      case StoryMood.adventure:
        return 'Exciting journeys for curiosity';
      case StoryMood.creative:
        return 'Imaginative stories for expression';
      case StoryMood.social:
        return 'Collaborative stories for connection';
      case StoryMood.neutral:
        return 'Balanced stories that adapt to you';
    }
  }

  Color _getMoodColor(StoryMood mood) {
    switch (mood) {
      case StoryMood.calm:
        return Colors.green;
      case StoryMood.excitement:
        return Colors.orange;
      case StoryMood.comfort:
        return Colors.pink;
      case StoryMood.adventure:
        return Colors.purple;
      case StoryMood.creative:
        return Colors.indigo;
      case StoryMood.social:
        return Colors.teal;
      case StoryMood.neutral:
        return Colors.grey;
    }
  }

  IconData _getMoodIcon(StoryMood mood) {
    switch (mood) {
      case StoryMood.calm:
        return Icons.spa;
      case StoryMood.excitement:
        return Icons.celebration;
      case StoryMood.comfort:
        return Icons.favorite;
      case StoryMood.adventure:
        return Icons.explore;
      case StoryMood.creative:
        return Icons.palette;
      case StoryMood.social:
        return Icons.people;
      case StoryMood.neutral:
        return Icons.balance;
    }
  }
} 