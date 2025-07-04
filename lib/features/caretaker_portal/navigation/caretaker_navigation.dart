import 'package:flutter/material.dart';
import '../pages/caretaker_dashboard_page.dart';
import '../pages/caretaker_settings_page.dart';
import '../pages/voice_setup_page.dart';

class CaretakerPortal extends StatefulWidget {
  const CaretakerPortal({Key? key}) : super(key: key);

  @override
  State<CaretakerPortal> createState() => _CaretakerPortalState();
}

class _CaretakerPortalState extends State<CaretakerPortal> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const CaretakerDashboardPage(),
    const VoiceSetupPage(),
    const CaretakerSettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'Voice Setup',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
} 