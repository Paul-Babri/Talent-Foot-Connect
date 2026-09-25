import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talent_foot_connect/screens/talent_public_profile_screen.dart';
import 'package:talent_foot_connect/services/search_service.dart';
import 'package:talent_foot_connect/services/talent_service.dart';
import 'package:talent_foot_connect/theme/app_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _search = SearchService();
  String? _position;
  late Future<List<SearchPlayer>> _future = _search.search();

  void _reload() {
    setState(() => _future = _search.search(position: _position));
  }

  Future<void> _open(SearchPlayer player) async {
    final profile = await TalentService().fetch(player.id);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TalentPublicProfileScreen(profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top + 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'RECHERCHE',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.mint,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _Chip(
                  label: 'Tous',
                  selected: _position == null,
                  onTap: () {
                    _position = null;
                    _reload();
                  },
                ),
                for (final position in SearchService.positions) ...[
                  const SizedBox(width: 8),
                  _Chip(
                    label: position,
                    selected: _position == position,
                    onTap: () {
                      _position = position;
                      _reload();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<SearchPlayer>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.mint),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Impossible de charger les joueurs.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                  );
                }
                final players = snapshot.data ?? const <SearchPlayer>[];
                if (players.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun joueur pour ce poste.',
                      style: GoogleFonts.inter(color: AppColors.textMuted),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return ListTile(
                      onTap: () => _open(player),
                      tileColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      title: Text(
                        player.name,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${player.position} · ${player.age} ans · ${player.location}',
                        style: GoogleFonts.inter(color: AppColors.textSecondary),
                      ),
                      trailing: player.isPro
                          ? Text(
                              'PRO',
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.orange,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0x33FE6B00) : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: selected ? AppColors.orange : AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
