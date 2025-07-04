import 'package:flutter/material.dart';
import '../widgets/stat_card.dart';
import '../widgets/learning_time_chart.dart';
import '../widgets/emotional_insights_widget.dart';
import '../../../shared/widgets/neuro_card.dart';

class CaretakerDashboardPage extends StatelessWidget {
  const CaretakerDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B8B), Color(0xFFFF8E53)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.dashboard, color: Colors.white, size: 28),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caretaker Portal',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Oversee and support the learning journey.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 32),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Learning Time',
                    value: '0h 35m',
                    icon: Icons.timer_outlined,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Completed Lessons',
                    value: '1',
                    icon: Icons.school_outlined,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Current Well-being',
                    value: 'Calm',
                    icon: Icons.favorite_outline,
                    valueColor: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),

            // Emotional Insights
            const EmotionalInsightsWidget(),
            SizedBox(height: 24),

            // Learning Time Chart
            NeuroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning Time (Last 7 Days)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: LearningTimeChart(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 