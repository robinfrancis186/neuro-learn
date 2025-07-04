import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../shared/themes/app_theme.dart';
import '../../../../shared/widgets/animated_card.dart';

class LearningClassroomPage extends ConsumerStatefulWidget {
  const LearningClassroomPage({super.key});

  @override
  ConsumerState<LearningClassroomPage> createState() => _LearningClassroomPageState();
}

class _LearningClassroomPageState extends ConsumerState<LearningClassroomPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar with gradient background
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.focusGradient,
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
                              child: const Icon(
                                Icons.school,
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
                                    'Learning Classroom',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Choose your learning adventure',
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
            ),
            
            // Subject cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a Subject',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore different subjects and start your learning journey',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSubjectCards(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCards() {
    final subjects = [
      {
        'title': 'Mathematics',
        'subtitle': 'Numbers, counting, shapes, and problem solving',
        'icon': Icons.calculate,
        'color': Colors.blue,
        'gradient': LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        'onTap': () => _navigateToSubject('mathematics'),
      },
      {
        'title': 'Science',
        'subtitle': 'Discover nature, experiments, and how things work',
        'icon': Icons.science,
        'color': Colors.green,
        'gradient': LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        'onTap': () => _navigateToSubject('science'),
      },
      {
        'title': 'Reading',
        'subtitle': 'Stories, letters, words, and comprehension',
        'icon': Icons.menu_book,
        'color': Colors.orange,
        'gradient': LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange.shade400, Colors.orange.shade600],
        ),
        'onTap': () => _navigateToSubject('reading'),
      },
      {
        'title': 'Social Skills',
        'subtitle': 'Communication, friendship, and emotional learning',
        'icon': Icons.people,
        'color': Colors.purple,
        'gradient': LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple.shade400, Colors.purple.shade600],
        ),
        'onTap': () => _navigateToSubject('social_skills'),
      },
    ];

    return Column(
      children: subjects.asMap().entries.map((entry) {
        final index = entry.key;
        final subject = entry.value;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AnimatedCard(
            onTap: subject['onTap'] as VoidCallback,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: subject['gradient'] as LinearGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (subject['color'] as Color).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
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
                      subject['icon'] as IconData,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject['title'] as String,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subject['subtitle'] as String,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: 200 * index))
              .slide(
                begin: Offset(0, 1),
                end: Offset.zero,
                duration: 600.ms,
                curve: Curves.easeOutCubic,
              )
              .fadeIn(),
        );
      }).toList(),
    );
  }

  void _navigateToSubject(String subject) {
    // TODO: Implement navigation to specific subject pages
    // This will be implemented in future sessions as mentioned by the user
    print('Navigate to $subject - Implementation pending');
    
    // Show a temporary message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$subject learning coming soon!'),
        backgroundColor: AppTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
} 