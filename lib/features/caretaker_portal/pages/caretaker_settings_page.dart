import 'package:flutter/material.dart';
import '../../../shared/widgets/neuro_card.dart';

class CaretakerSettingsPage extends StatelessWidget {
  const CaretakerSettingsPage({Key? key}) : super(key: key);

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
                      colors: [Color(0xFF6B8BFF), Color(0xFF53A0FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.settings, color: Colors.white, size: 28),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Configure caretaker portal preferences',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 32),

            // Settings Sections
            NeuroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildSettingSwitch(
                    context,
                    'Learning Progress Updates',
                    'Get notified about completed lessons and achievements',
                    true,
                  ),
                  _buildSettingSwitch(
                    context,
                    'Emotional State Alerts',
                    'Receive alerts for significant emotional changes',
                    true,
                  ),
                  _buildSettingSwitch(
                    context,
                    'Daily Summary',
                    'Get a daily summary of learning activities',
                    false,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            NeuroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data & Privacy',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildSettingSwitch(
                    context,
                    'Share Analytics',
                    'Help improve learning experience by sharing anonymous data',
                    true,
                  ),
                  _buildSettingSwitch(
                    context,
                    'Store History',
                    'Keep detailed history of learning sessions',
                    true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            NeuroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accessibility',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildSettingSwitch(
                    context,
                    'High Contrast Mode',
                    'Increase contrast for better visibility',
                    false,
                  ),
                  _buildSettingSwitch(
                    context,
                    'Large Text',
                    'Make text larger throughout the app',
                    false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(
    BuildContext context,
    String title,
    String subtitle,
    bool initialValue,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: initialValue,
            onChanged: (value) {
              // TODO: Implement settings persistence
            },
          ),
        ],
      ),
    );
  }
} 