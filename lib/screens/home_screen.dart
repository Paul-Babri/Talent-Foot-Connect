import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talent_foot_connect/feed/feed_video_controller.dart';
import 'package:talent_foot_connect/media/media_file_utils.dart';
import 'package:talent_foot_connect/models/feed_post.dart';
import 'package:talent_foot_connect/screens/create_feed_post_screen.dart';
import 'package:talent_foot_connect/screens/talent_public_profile_screen.dart';
import 'package:talent_foot_connect/services/feed_service.dart';
import 'package:talent_foot_connect/theme/app_colors.dart';
import 'package:talent_foot_connect/widgets/feed_media_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const Color mint = Color(0xFFA1D494);
  static const Color orangeSoft = Color(0xFFFFB693);
  static const Color textSecondary = Color(0xFFC2C9BB);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _feedService = FeedService();
  final _pageController = PageController();
  final _video = FeedVideoController();

  late Future<List<FeedPost>> _future;
  List<FeedPost> _posts = const [];
  bool _canPublish = false;
  int _currentIndex = 0;
  bool _appActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _future = _loadFeed();
    _loadPublishAccess();
  }

  Future<List<FeedPost>> _loadFeed() async {
    final posts = await _feedService.fetchFeed();
    _posts = posts;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncActiveVideo();
    });
    return posts;
  }

  Future<void> _loadPublishAccess() async {
    final canPublish = await _feedService.currentUserIsPlayer();
    if (mounted) setState(() => _canPublish = canPublish);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _loadFeed();
      _currentIndex = 0;
    });
    await _future;
  }

  Future<void> _openCreatePost() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateFeedPostScreen()),
    );
    if (created == true && mounted) await _reload();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _syncActiveVideo();
  }

  Future<void> _syncActiveVideo() async {
    if (!_appActive || _posts.isEmpty) {
      await _video.clear();
      return;
    }

    final current = _posts[_currentIndex.clamp(0, _posts.length - 1)];
    if (current.mediaType != FeedMediaType.video) {
      await _video.clear();
      return;
    }

    if (!isPlayableVideoUrl(current.mediaUrl)) {
      await _video.showError(
        'Cette ancienne vidéo est illisible. '
        'Publie une nouvelle vidéo (MP4) depuis +.',
      );
      return;
    }

    await _video.activate(current.mediaUrl, volume: 1.0);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (!_appActive) {
      _video.pause();
    } else {
      _syncActiveVideo();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          children: [
            Column(
              children: [
                // Header temporairement masqué — le feed passe sous la status bar.
                // SizedBox(height: MediaQuery.paddingOf(context).top),
                // _HomeHeader(
                //   canPublish: _canPublish,
                //   onPublish: _openCreatePost,
                //   onRefresh: _reload,
                // ),
                Expanded(
                  child: FutureBuilder<List<FeedPost>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          _posts.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: HomeScreen.mint,
                          ),
                        );
                      }

                      if (snapshot.hasError && _posts.isEmpty) {
                        return _EmptyFeed(
                          title: 'Erreur de chargement',
                          subtitle: '${snapshot.error}',
                          actionLabel: 'Réessayer',
                          onAction: _reload,
                        );
                      }

                      final posts = snapshot.data ?? _posts;
                      if (posts.isEmpty) {
                        return _EmptyFeed(
                          title: 'Aucun post pour le moment',
                          subtitle: _canPublish
                              ? 'Sois le premier à publier une photo ou une vidéo.'
                              : 'Les joueurs publieront bientôt leurs highlights.',
                          actionLabel: _canPublish ? 'Publier' : null,
                          onAction: _canPublish ? _openCreatePost : null,
                        );
                      }

                      return PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        physics: const PageScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: posts.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          final isActive = index == _currentIndex && _appActive;
                          return _FeedPage(
                            post: post,
                            isActive: isActive,
                            videoController: _video,
                            onRetryVideo: _syncActiveVideo,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_canPublish)
              Positioned(
                top: topPad + 8,
                right: 12,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    onPressed: _openCreatePost,
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 28,
                    ),
                    tooltip: 'Publier',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.canPublish,
    required this.onPublish,
    required this.onRefresh,
  });

  final bool canPublish;
  final VoidCallback onPublish;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xCC0C0F0F),
        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HomeScreen.mint, width: 2),
              color: const Color(0xFF1A1C1C),
            ),
            child: const Icon(
              Icons.sports_soccer,
              color: HomeScreen.mint,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'TALENTFOOT CONNECT',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              color: HomeScreen.mint,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, color: HomeScreen.mint, size: 22),
          ),
          if (canPublish)
            IconButton(
              onPressed: onPublish,
              icon: const Icon(
                Icons.add_circle_outline,
                color: HomeScreen.mint,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dynamic_feed, color: HomeScreen.mint, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: HomeScreen.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFE6B00),
                  foregroundColor: const Color(0xFF572000),
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedPage extends StatelessWidget {
  const _FeedPage({
    required this.post,
    required this.isActive,
    required this.videoController,
    this.onRetryVideo,
  });

  final FeedPost post;
  final bool isActive;
  final FeedVideoController videoController;
  final VoidCallback? onRetryVideo;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FeedMediaPlayer(
          post: post,
          isActive: isActive,
          videoController: videoController,
          onRetry: onRetryVideo,
          showSeekBar: false,
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xE50C0F0F),
                  Color(0x660C0F0F),
                  Color(0x000C0F0F),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 72,
          bottom: 16,
          child: IgnorePointer(child: _PlayerInfo(post: post)),
        ),
        Positioned(
          right: 12,
          bottom: 24,
          child: _SideActions(post: post),
        ),
        if (post.mediaType == FeedMediaType.video)
          Positioned(
            left: 0,
            right: 0,
            bottom: 3.5,
            child: FeedVideoSeekBar(controller: videoController),
          ),
      ],
    );
  }
}

class _PlayerInfo extends StatelessWidget {
  const _PlayerInfo({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final position =
        post.position?.isNotEmpty == true ? post.position! : 'Joueur';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _Chip(
              label: position,
              color: HomeScreen.mint,
              border: const Color(0x33A1D494),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: post.mediaType == FeedMediaType.video ? 'VIDÉO' : 'PHOTO',
              color: HomeScreen.orangeSoft,
              border: const Color(0x33FFB693),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          post.age > 0 ? '${post.playerName}, ${post.age} ans' : post.playerName,
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: HomeScreen.textSecondary.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                post.location,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: HomeScreen.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
        if (post.caption != null && post.caption!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            post.caption!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            _StatBubble(value: '${post.goals}', label: 'BUTS'),
            const SizedBox(width: 16),
            _StatBubble(value: '${post.assists}', label: 'ASSISTS'),
            const SizedBox(width: 16),
            _StatBubble(
              value: post.age > 0 ? '${post.age}' : '—',
              label: 'ÂGE',
            ),
          ],
        ),
      ],
    );
  }
}

class _SideActions extends StatelessWidget {
  const _SideActions({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SideAction(icon: Icons.person_add_alt_1, label: 'Suivre'),
        const SizedBox(height: 20),
        _SideAction(icon: Icons.favorite_border, label: '${post.likesCount}'),
        const SizedBox(height: 20),
        const _SideAction(icon: Icons.chat_bubble_outline, label: '0'),
        const SizedBox(height: 20),
        const _SideAction(icon: Icons.ios_share, label: 'Partager'),
        const SizedBox(height: 20),
        _EyeButton(post: post),
      ],
    );
  }
}

class _EyeButton extends StatelessWidget {
  const _EyeButton({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TalentPublicProfileScreen(
                profile: TalentPublicProfile.fromFeed(
                  name: post.playerName,
                  age: post.age,
                  position: post.position ?? 'Joueur',
                  badge: post.mediaType == FeedMediaType.video
                      ? 'Highlight'
                      : 'Photo',
                  city: post.location,
                  photoUrl: post.playerPhotoUrl ??
                      (post.mediaType == FeedMediaType.image
                          ? post.mediaUrl
                          : null),
                  stat1: '${post.goals}',
                  stat1Label: 'BUTS',
                  stat2: '${post.assists}',
                  stat2Label: 'ASSISTS',
                  stat3: post.age > 0 ? '${post.age}' : '0',
                  stat3Label: 'ÂGE',
                ),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFE6B00),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66FE6B00),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.remove_red_eye_outlined,
            color: Color(0xFF572000),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.border});

  final String label;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xCC282A2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: color,
        ),
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  const _StatBubble({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0x66000000),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HomeScreen.mint, width: 2),
          ),
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: HomeScreen.mint,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: HomeScreen.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SideAction extends StatelessWidget {
  const _SideAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0x66000000),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
