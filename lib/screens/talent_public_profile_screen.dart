import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TalentPublicProfile {
  const TalentPublicProfile({
    required this.name,
    required this.age,
    required this.position,
    required this.badge,
    required this.city,
    required this.height,
    required this.weight,
    required this.strongFoot,
    required this.prospectLabel,
    required this.clubs,
    required this.highlights,
    required this.bars,
    required this.radar,
    this.photoUrl,
  });

  final String name;
  final int age;
  final String position;
  final String badge;
  final String city;
  final String height;
  final String weight;
  final String strongFoot;
  final String prospectLabel;
  final List<({String club, String period})> clubs;
  final List<String> highlights;
  final List<({String label, int value})> bars;
  final List<({String label, int value})> radar;
  final String? photoUrl;

  factory TalentPublicProfile.fromFeed({
    required String name,
    required int age,
    required String position,
    required String badge,
    required String city,
    required String stat1,
    required String stat1Label,
    required String stat2,
    required String stat2Label,
    required String stat3,
    required String stat3Label,
    String? photoUrl,
  }) {
    final s1 = int.tryParse(stat1) ?? 80;
    final s2 = int.tryParse(stat2) ?? 80;
    final s3 = int.tryParse(stat3) ?? 80;

    return TalentPublicProfile(
      name: name.toUpperCase(),
      age: age,
      position: position,
      badge: badge,
      city: city,
      height: age >= 19 ? '184 cm' : '178 cm',
      weight: age >= 19 ? '78 kg' : '72 kg',
      strongFoot: 'Droit',
      prospectLabel: 'TOP PROSPECT',
      photoUrl: photoUrl,
      clubs: const [
        (club: 'Olympique Marseille U19', period: '2023 - Prés.'),
        (club: 'Académie OM', period: '2019 - 2023'),
      ],
      highlights: const [
        'Buts saison 23/24',
        'Analyse tactique',
        'Techniques de dribble',
      ],
      bars: [
        (label: 'ACCÉLÉRATION', value: s1),
        (label: 'FINITION', value: (s2 * 0.95).round().clamp(50, 99)),
        (label: 'DRIBBLE', value: s2),
        (label: 'VISION', value: s3),
      ],
      radar: [
        (label: 'VIT.', value: s1),
        (label: 'TIR', value: (s2 * 0.9).round().clamp(40, 99)),
        (label: 'PASSE', value: s3),
        (label: 'DRI', value: s2),
        (
          label: 'DÉF',
          value: position.contains('Défenseur') || position.contains('Gardien')
              ? 88
              : 50,
        ),
      ],
    );
  }
}

class TalentPublicProfileScreen extends StatelessWidget {
  const TalentPublicProfileScreen({super.key, required this.profile});

  final TalentPublicProfile profile;

  static const Color _mint = Color(0xFFA1D494);
  static const Color _orange = Color(0xFFFE6B00);
  static const Color _orangeDark = Color(0xFF572000);
  static const Color _bg = Color(0xFF121414);
  static const Color _surface = Color(0xFF1A1C1C);
  static const Color _textPrimary = Color(0xFFE2E2E2);
  static const Color _textSecondary = Color(0xFFC2C9BB);
  static const Color _textMuted = Color(0xFF8C9387);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Column(
            children: [
              // _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 100 + bottomPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(context),
                      _buildScoutBar(),
                      const SizedBox(height: 28),
                      _buildBio(),
                      const SizedBox(height: 28),
                      _buildHighlights(),
                      const SizedBox(height: 28),
                      _buildPerformance(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: topPad + 8,
            left: 12,
            child: Material(
              color: const Color(0x66000000),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: Colors.white,
                ),
                tooltip: 'Retour',
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(bottomPad),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 64 + MediaQuery.paddingOf(context).top,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top,
        left: 8,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xCC0C0F0F),
        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: _textPrimary,
            ),
          ),
          Text(
            'TALENT FOOT',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              color: _mint,
            ),
          ),
          const Spacer(),
          const Icon(Icons.notifications_none, color: _mint, size: 22),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF333535),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x33A1D494)),
            ),
            clipBehavior: Clip.antiAlias,
            child: profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                ? Image.network(
                    profile.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 16,
                      color: _textMuted,
                    ),
                  )
                : const Icon(Icons.person, size: 16, color: _textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPhotoViewer(context),
      child: SizedBox(
        height: 420,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _ProfileHeroImage(url: profile.photoUrl),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xFF121414),
                      Color(0x99121414),
                      Color(0x00121414),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            profile.prospectLabel,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                              color: _orangeDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x99282A2B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x1AFFFFFF)),
                          ),
                          child: Text(
                            profile.badge.toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      profile.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          profile.city,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.sports_soccer,
                          size: 14,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          profile.position,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPhotoViewer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _PhotoLightbox(
            url: profile.photoUrl,
            animation: animation,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );
  }

  Widget _buildScoutBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0x661A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: profile.radar
              .map(
                (item) => Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0x66000000),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _mint, width: 2),
                      ),
                      child: Text(
                        '${item.value}',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _mint,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildBio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Bio du joueur'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoCard(label: 'ÂGE', value: '${profile.age} ans'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoCard(label: 'TAILLE', value: profile.height),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoCard(label: 'PIED FORT', value: profile.strongFoot),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoCard(label: 'POIDS', value: profile.weight),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x0DFFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HISTORIQUE CLUBS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...profile.clubs.asMap().entries.map((entry) {
                  final club = entry.value;
                  final faded = entry.key > 0;
                  return Opacity(
                    opacity: faded ? 0.6 : 1,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == profile.clubs.length - 1 ? 0 : 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF333535),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: _mint,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              club.club,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            club.period,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const _SectionTitle('Highlights'),
              const Spacer(),
              Text(
                'Tout voir',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _mint,
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: _mint),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: profile.highlights.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _HighlightCard(title: profile.highlights[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPerformance() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Analyse de\nperformance'),
          const SizedBox(height: 20),
          ...profile.bars.map(
            (bar) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _StatBar(label: bar.label, value: bar.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double bottomPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFF121414), Color(0xF2121414), Color(0x00121414)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x1AFFFFFF)),
                  backgroundColor: const Color(0xFF333535),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'PDF',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'CONTACTER',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 24,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: TalentPublicProfileScreen._mint,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.15,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TalentPublicProfileScreen._surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x0DFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: TalentPublicProfileScreen._textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 260,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/bg-stadium.jpg', fit: BoxFit.cover),
            Container(color: const Color(0x66000000)),
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x4DFFFFFF)),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x99000000),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  title,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: TalentPublicProfileScreen._textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '$value',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TalentPublicProfileScreen._mint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 6,
            backgroundColor: const Color(0xFF333535),
            color: TalentPublicProfileScreen._mint,
          ),
        ),
      ],
    );
  }
}

class _ProfileHeroImage extends StatelessWidget {
  const _ProfileHeroImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return Image.asset('assets/images/bg-stadium.jpg', fit: BoxFit.cover);
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) =>
          Image.asset('assets/images/bg-stadium.jpg', fit: BoxFit.cover),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: Color(0xFF1A1C1C),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFA1D494),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Fullscreen photo viewer with fade + soft scale on open/close.
class _PhotoLightbox extends StatelessWidget {
  const _PhotoLightbox({
    required this.animation,
    this.url,
  });

  final Animation<double> animation;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final fade = curved;
    final scale = Tween<double>(begin: 0.94, end: 1).animate(curved);
    final topPad = MediaQuery.paddingOf(context).top;

    return FadeTransition(
      opacity: fade,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Dim backdrop
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const ColoredBox(color: Color(0xE6000000)),
            ),
            // Photo
            Center(
              child: ScaleTransition(
                scale: scale,
                child: FadeTransition(
                  opacity: fade,
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width,
                        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                      ),
                      child: _LightboxImage(url: url),
                    ),
                  ),
                ),
              ),
            ),
            // Close
            Positioned(
              top: topPad + 8,
              right: 12,
              child: FadeTransition(
                opacity: fade,
                child: Material(
                  color: const Color(0x66FFFFFF),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    tooltip: 'Fermer',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LightboxImage extends StatelessWidget {
  const _LightboxImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return Image.asset(
        'assets/images/bg-stadium.jpg',
        fit: BoxFit.contain,
      );
    }

    return Image.network(
      url!,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/bg-stadium.jpg',
        fit: BoxFit.contain,
      ),
    );
  }
}
