import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppTab { feed, search, messages, profile }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final AppTab current;
  final ValueChanged<AppTab> onChanged;

  static const Color _activeBg = Color(0x33FE6B00);
  static const Color _active = Color(0xFFFFB693);
  static const Color _inactive = Color(0xFF42493E);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80 + MediaQuery.paddingOf(context).bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0F0F),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            label: 'Accueil',
            icon: Icons.sports_soccer,
            active: current == AppTab.feed,
            onTap: () => onChanged(AppTab.feed),
          ),
          _NavItem(
            label: 'Recherche',
            icon: Icons.search,
            active: current == AppTab.search,
            onTap: () => onChanged(AppTab.search),
          ),
          _NavItem(
            label: 'Messages',
            icon: Icons.chat_bubble_outline,
            active: current == AppTab.messages,
            onTap: () => onChanged(AppTab.messages),
          ),
          _NavItem(
            label: 'Profil',
            icon: Icons.person_outline,
            active: current == AppTab.profile,
            onTap: () => onChanged(AppTab.profile),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppBottomNav._active : AppBottomNav._inactive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: active ? AppBottomNav._activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
