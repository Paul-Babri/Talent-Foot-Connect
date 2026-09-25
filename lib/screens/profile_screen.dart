import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talent_foot_connect/models/app_role.dart';
import 'package:talent_foot_connect/models/app_user_profile.dart';
import 'package:talent_foot_connect/screens/admin_dashboard_screen.dart';
import 'package:talent_foot_connect/screens/create_feed_post_screen.dart';
import 'package:talent_foot_connect/screens/offers_screen.dart';
import 'package:talent_foot_connect/screens/player_account_screen.dart';
import 'package:talent_foot_connect/screens/talent_public_profile_screen.dart';
import 'package:talent_foot_connect/screens/welcome_screen.dart';
import 'package:talent_foot_connect/services/admin_service.dart';
import 'package:talent_foot_connect/services/auth_service.dart';
import 'package:talent_foot_connect/services/profile_service.dart';
import 'package:talent_foot_connect/services/social_service.dart';
import 'package:talent_foot_connect/services/talent_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const Color _mint = Color(0xFFA1D494);
  static const Color _orange = Color(0xFFFE6B00);
  static const Color _orangeSoft = Color(0xFFFFB693);
  static const Color _orangeDark = Color(0xFF561F00);
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _surface = Color(0x991A1A1A);
  static const Color _textPrimary = Color(0xFFE2E2E2);
  static const Color _textSecondary = Color(0xFFC2C9BB);
  static const Color _textMuted = Color(0xFF8C9387);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  final _admin = AdminService();
  late Future<AppUserProfile?> _future;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _future = _profileService.fetchCurrentProfile();
    _admin.amIAdmin().then((value) {
      if (mounted) setState(() => _isAdmin = value);
    }).catchError((_) {});
  }

  Future<void> _reload() async {
    setState(() {
      _future = _profileService.fetchCurrentProfile();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: ProfileScreen._bg,
      child: Column(
        children: [
          SizedBox(height: topPad),
          // _buildHeader(),
          Expanded(
            child: FutureBuilder<AppUserProfile?>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: ProfileScreen._mint),
                  );
                }

                if (snapshot.hasError) {
                  return _ErrorState(
                    message: 'Impossible de charger ton profil.',
                    detail: '${snapshot.error}',
                    onRetry: _reload,
                  );
                }

                final profile = snapshot.data;
                if (profile == null) {
                  return _ErrorState(
                    message: 'Aucun profil trouvé pour ce compte.',
                    onRetry: _reload,
                  );
                }

                return RefreshIndicator(
                  color: ProfileScreen._mint,
                  onRefresh: _reload,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroCard(profile: profile),
                        if (profile.description != null &&
                            profile.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _DescriptionBlock(text: profile.description!),
                        ],
                        if (profile.details.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _DetailsBlock(details: profile.details),
                        ],
                        if (profile.role == AppRole.player) ...[
                          const SizedBox(height: 24),
                          _MonCompteOption(
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      PlayerAccountScreen(profile: profile),
                                ),
                              );
                              if (mounted) await _reload();
                            },
                          ),
                          const SizedBox(height: 12),
                          _SettingsLink(
                            icon: Icons.add_photo_alternate_outlined,
                            title: 'Publier sur le feed',
                            subtitle: 'Ajoute une photo ou une vidéo sur l\'accueil',
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const CreateFeedPostScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsLink(
                            icon: Icons.workspace_premium_outlined,
                            title: 'Offres',
                            subtitle: 'Vidéos supplémentaires ou abonnement PRO',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const OffersScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 32),
                        const _FollowedPlayers(),
                        const SizedBox(height: 32),
                        const _Management(),
                        if (_isAdmin) ...[
                          const SizedBox(height: 12),
                          _SettingsLink(
                            icon: Icons.dashboard_outlined,
                            title: 'Tableau de bord',
                            subtitle: 'Indicateurs, vérification et crédits',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AdminDashboardScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        _LogoutButton(onDone: () {}),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xCC0C0F0F),
        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Row(
        children: [
          Text(
            'TALENT FOOT',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              color: ProfileScreen._mint,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _reload,
            icon: const Icon(
              Icons.refresh,
              color: ProfileScreen._textSecondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.profile});

  final AppUserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: ProfileScreen._surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x33A1D494), width: 4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: profile.avatarUrl != null &&
                          profile.avatarUrl!.isNotEmpty
                      ? Image.network(
                          profile.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _AvatarFallback(),
                        )
                      : const _AvatarFallback(),
                ),
              ),
              if (profile.verified)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ProfileScreen._orange,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0C0F0F),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.verified,
                      size: 16,
                      color: ProfileScreen._orangeDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: ProfileScreen._textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x332D5A27),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  profile.badgeLabel ?? profile.role.label.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: ProfileScreen._mint,
                  ),
                ),
              ),
              if (profile.subtitle != null &&
                  profile.subtitle!.trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    profile.subtitle!,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: ProfileScreen._textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (profile.stat1 != null ||
              profile.stat2 != null ||
              profile.stat3 != null) ...[
            const SizedBox(height: 20),
            const Divider(color: Color(0x0DFFFFFF), height: 1),
            const SizedBox(height: 20),
            Row(
              children: [
                if (profile.stat1 != null)
                  Expanded(
                    child: _ProfileStat(
                      value: profile.stat1!.value,
                      label: profile.stat1!.label,
                    ),
                  ),
                if (profile.stat2 != null)
                  Expanded(
                    child: _ProfileStat(
                      value: profile.stat2!.value,
                      label: profile.stat2!.label,
                      bordered: true,
                    ),
                  ),
                if (profile.stat3 != null)
                  Expanded(
                    child: _ProfileStat(
                      value: profile.stat3!.value,
                      label: profile.stat3!.label,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF282A2B),
      child: const Icon(Icons.person, size: 48, color: ProfileScreen._mint),
    );
  }
}

class _DescriptionBlock extends StatelessWidget {
  const _DescriptionBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'À propos',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ProfileScreen._textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ProfileScreen._surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: ProfileScreen._textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailsBlock extends StatelessWidget {
  const _DetailsBlock({required this.details});

  final List<({String label, String value})> details;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ProfileScreen._textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...details.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ProfileScreen._surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x14FFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: ProfileScreen._textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ProfileScreen._textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MonCompteOption extends StatelessWidget {
  const _MonCompteOption({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mon compte',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ProfileScreen._textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _SettingsLink(
          icon: Icons.manage_accounts_outlined,
          title: 'Mon compte',
          subtitle: 'Voir et modifier mes informations joueur',
          onTap: onTap,
        ),
      ],
    );
  }
}

class _FollowedPlayers extends StatefulWidget {
  const _FollowedPlayers();

  @override
  State<_FollowedPlayers> createState() => _FollowedPlayersState();
}

class _FollowedPlayersState extends State<_FollowedPlayers> {
  final _social = SocialService();
  final _talents = TalentService();
  late final Future<List<FollowedPlayer>> _future = _social.followedPlayers();

  Future<void> _open(FollowedPlayer player) async {
    final profile = await _talents.fetch(player.id);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TalentPublicProfileScreen(profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Abonnements',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ProfileScreen._textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<FollowedPlayer>>(
          future: _future,
          builder: (context, snapshot) {
            final players = snapshot.data ?? const <FollowedPlayer>[];
            if (players.isEmpty) {
              return Text(
                'Tu ne suis encore aucun joueur.',
                style: GoogleFonts.inter(color: ProfileScreen._textMuted),
              );
            }
            return Column(
              children: [
                for (final player in players)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _open(player),
                    title: Text(
                      player.name,
                      style: GoogleFonts.montserrat(
                        color: ProfileScreen._textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${player.position} · ${player.age} ans',
                      style: GoogleFonts.inter(color: ProfileScreen._textMuted),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Management extends StatelessWidget {
  const _Management();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestion',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ProfileScreen._textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const _SettingsLink(
          icon: Icons.person_outline,
          title: 'Paramètres du compte',
          subtitle: 'Sécurité, notifications et détails du profil',
        ),
        const SizedBox(height: 12),
        const _SettingsLink(
          icon: Icons.shield_outlined,
          title: 'Politique de confidentialité',
          subtitle: 'Gérer l\'usage des données et l\'anonymat scout',
        ),
        const SizedBox(height: 12),
        const _SettingsLink(
          icon: Icons.help_outline,
          title: 'Aide & Support',
          subtitle: 'Guides de scouting et assistance technique',
        ),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () async {
          await AuthService().signOut();
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
            (_) => false,
          );
          onDone();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: ProfileScreen._orangeSoft,
          side: const BorderSide(color: Color(0x33FE6B00)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          'Se déconnecter',
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    this.detail,
  });

  final String message;
  final String? detail;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: ProfileScreen._textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: ProfileScreen._textMuted,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Réessayer',
                style: GoogleFonts.montserrat(
                  color: ProfileScreen._mint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.value,
    required this.label,
    this.bordered = false,
  });

  final String value;
  final String label;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: bordered
          ? const BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: Color(0x0DFFFFFF)),
              ),
            )
          : null,
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: ProfileScreen._orangeSoft,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: ProfileScreen._textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: ProfileScreen._surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF282A2B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: ProfileScreen._mint, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ProfileScreen._textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: ProfileScreen._textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: ProfileScreen._textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
