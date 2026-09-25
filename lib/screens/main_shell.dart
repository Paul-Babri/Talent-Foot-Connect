import 'package:flutter/material.dart';
import 'package:talent_foot_connect/screens/home_screen.dart';
import 'package:talent_foot_connect/screens/profile_screen.dart';
import 'package:talent_foot_connect/screens/search_screen.dart';
import 'package:talent_foot_connect/widgets/app_bottom_nav.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = AppTab.feed});

  final AppTab initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late AppTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: IndexedStack(
        index: _tabIndex(_tab),
        children: const [
          HomeScreen(),
          SearchScreen(),
          _PlaceholderTab(
            title: 'Messages',
            subtitle: 'Bientôt disponible',
            icon: Icons.chat_bubble_outline,
          ),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        current: _tab,
        onChanged: (tab) => setState(() => _tab = tab),
      ),
    );
  }

  int _tabIndex(AppTab tab) {
    switch (tab) {
      case AppTab.feed:
        return 0;
      case AppTab.search:
        return 1;
      case AppTab.messages:
        return 2;
      case AppTab.profile:
        return 3;
    }
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: const Color(0xFFA1D494)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE2E2E2),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFF8C9387))),
        ],
      ),
    );
  }
}
