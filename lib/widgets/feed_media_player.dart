import 'package:flutter/material.dart';
import 'package:talent_foot_connect/feed/feed_video_controller.dart';
import 'package:talent_foot_connect/models/feed_post.dart';
import 'package:talent_foot_connect/theme/app_colors.dart';
import 'package:video_player/video_player.dart';

/// Reusable feed media player (image or video) with TikTok-like tap to play/pause.
class FeedMediaPlayer extends StatelessWidget {
  const FeedMediaPlayer({
    super.key,
    required this.post,
    required this.isActive,
    required this.videoController,
    this.onRetry,
    this.showPlayPauseIcon = true,
    this.showSeekBar = true,
  });

  final FeedPost post;
  final bool isActive;
  final FeedVideoController videoController;
  final VoidCallback? onRetry;
  final bool showPlayPauseIcon;
  final bool showSeekBar;

  @override
  Widget build(BuildContext context) {
    if (post.mediaType == FeedMediaType.image) {
      return _FeedImage(url: post.mediaUrl);
    }

    return _FeedVideoPlayer(
      controller: videoController,
      isActive: isActive,
      onRetry: onRetry,
      showPlayPauseIcon: showPlayPauseIcon,
      showSeekBar: showSeekBar,
    );
  }
}

class _FeedImage extends StatelessWidget {
  const _FeedImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/bg-stadium.jpg',
        fit: BoxFit.cover,
      ),
    );
  }
}

class _FeedVideoPlayer extends StatelessWidget {
  const _FeedVideoPlayer({
    required this.controller,
    required this.isActive,
    this.onRetry,
    this.showPlayPauseIcon = true,
    this.showSeekBar = true,
  });

  final FeedVideoController controller;
  final bool isActive;
  final VoidCallback? onRetry;
  final bool showPlayPauseIcon;
  final bool showSeekBar;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!isActive) {
          return const ColoredBox(color: Colors.black);
        }

        if (controller.error != null) {
          return _VideoError(message: controller.error!, onRetry: onRetry);
        }

        final player = controller.player;
        if (player == null || !player.value.isInitialized || controller.loading) {
          return const _VideoLoading();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.togglePlayPause,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CoverVideo(player: player),
                  if (showPlayPauseIcon)
                    IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: controller.isPlaying ? 0 : 1,
                        duration: const Duration(milliseconds: 160),
                        child: const Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0x66000000),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 56,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (showSeekBar)
              Positioned(
                left: 12,
                right: 12,
                bottom: 6,
                child: FeedVideoSeekBar(controller: controller),
              ),
          ],
        );
      },
    );
  }
}

/// TikTok-style scrubber: full-bleed, flush above the bottom nav.
class FeedVideoSeekBar extends StatefulWidget {
  const FeedVideoSeekBar({super.key, required this.controller});

  final FeedVideoController controller;

  @override
  State<FeedVideoSeekBar> createState() => _FeedVideoSeekBarState();
}

class _FeedVideoSeekBarState extends State<FeedVideoSeekBar> {
  bool _dragging = false;
  double? _dragValue;
  double _trackWidth = 1;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final player = widget.controller.player;
        if (player == null || !player.value.isInitialized) {
          return const SizedBox(height: 28);
        }

        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: player,
          builder: (context, value, _) {
            final durationMs = value.duration.inMilliseconds;
            final progress = durationMs <= 0
                ? 0.0
                : (_dragging && _dragValue != null
                      ? _dragValue!
                      : (value.position.inMilliseconds / durationMs)
                            .clamp(0.0, 1.0));

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _seekImmediate(details.localPosition.dx),
              onHorizontalDragStart: (details) {
                setState(() {
                  _dragging = true;
                  _dragValue =
                      (details.localPosition.dx / _trackWidth).clamp(0.0, 1.0);
                });
              },
              onHorizontalDragUpdate: (details) {
                final next =
                    (details.localPosition.dx / _trackWidth).clamp(0.0, 1.0);
                setState(() => _dragValue = next);
                widget.controller.seekFraction(next);
              },
              onHorizontalDragEnd: (_) => _endDrag(),
              onHorizontalDragCancel: _endDrag,
              child: SizedBox(
                height: 28,
                width: double.infinity,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _trackWidth = constraints.maxWidth;
                      return _SeekTrack(
                        progress: progress,
                        dragging: _dragging,
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _seekImmediate(double dx) async {
    final fraction = (dx / _trackWidth).clamp(0.0, 1.0);
    setState(() {
      _dragging = true;
      _dragValue = fraction;
    });
    await widget.controller.seekFraction(fraction);
    if (!mounted) return;
    setState(() {
      _dragging = false;
      _dragValue = null;
    });
  }

  Future<void> _endDrag() async {
    final value = _dragValue;
    if (value != null) {
      await widget.controller.seekFraction(value);
    }
    if (!mounted) return;
    setState(() {
      _dragging = false;
      _dragValue = null;
    });
  }
}

class _SeekTrack extends StatelessWidget {
  const _SeekTrack({required this.progress, required this.dragging});

  final double progress;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    // TikTok: hairline when idle, slightly thicker + larger thumb while scrubbing.
    final barHeight = dragging ? 3.0 : 1.5;
    final thumbSize = dragging ? 6.0 : 4.0;

    return SizedBox(
      height: dragging ? 12 : 6,
      width: double.infinity,
      child: CustomPaint(
        painter: _SeekTrackPainter(
          progress: progress,
          barHeight: barHeight,
          thumbSize: thumbSize,
          trackColor: AppColors.mint.withValues(alpha: 0.1),
          fillColor: Colors.white,
          thumbColor: Colors.white,
        ),
      ),
    );
  }
}

class _SeekTrackPainter extends CustomPainter {
  _SeekTrackPainter({
    required this.progress,
    required this.barHeight,
    required this.thumbSize,
    required this.trackColor,
    required this.fillColor,
    required this.thumbColor,
  });

  final double progress;
  final double barHeight;
  final double thumbSize;
  final Color trackColor;
  final Color fillColor;
  final Color thumbColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Hairline flush to the bottom edge (above bottom nav).
    final trackTop = size.height - barHeight;
    final track = RRect.fromLTRBR(
      0,
      trackTop,
      size.width,
      size.height,
      Radius.circular(barHeight),
    );
    canvas.drawRRect(track, Paint()..color = trackColor);

    final fillWidth = (size.width * progress).clamp(0.0, size.width);
    if (fillWidth > 0) {
      final fill = RRect.fromLTRBR(
        0,
        trackTop,
        fillWidth,
        size.height,
        Radius.circular(barHeight),
      );
      canvas.drawRRect(fill, Paint()..color = fillColor);
    }

    final thumbCy = size.height - barHeight / 2;
    final thumbX = fillWidth.clamp(thumbSize / 2, size.width - thumbSize / 2);
    canvas.drawCircle(
      Offset(thumbX, thumbCy),
      thumbSize / 2,
      Paint()..color = thumbColor,
    );
  }

  @override
  bool shouldRepaint(covariant _SeekTrackPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.barHeight != barHeight ||
        oldDelegate.thumbSize != thumbSize;
  }
}

class _CoverVideo extends StatelessWidget {
  const _CoverVideo({required this.player});

  final VideoPlayerController player;

  @override
  Widget build(BuildContext context) {
    final size = player.value.size;
    if (size.width <= 0 || size.height <= 0) {
      return VideoPlayer(player);
    }

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(player),
      ),
    );
  }
}

class _VideoLoading extends StatelessWidget {
  const _VideoLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
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
  }
}

class _VideoError extends StatelessWidget {
  const _VideoError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                color: Colors.white54,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onRetry,
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(color: Color(0xFFA1D494)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
