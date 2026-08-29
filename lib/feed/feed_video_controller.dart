import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// Owns the single active feed video (TikTok-style).
class FeedVideoController extends ChangeNotifier {
  VideoPlayerController? _player;
  String? _url;
  String? _error;
  bool _loading = false;
  bool _playing = false;
  int _generation = 0;

  VideoPlayerController? get player => _player;
  String? get url => _url;
  String? get error => _error;
  bool get loading => _loading;
  bool get isReady => _player?.value.isInitialized == true;
  bool get isPlaying => _playing;

  Future<void> activate(String url, {double volume = 1.0}) async {
    if (_url == url && isReady) {
      _error = null;
      await _player?.setVolume(volume);
      await _player?.play();
      _playing = true;
      notifyListeners();
      return;
    }

    final gen = ++_generation;
    await _disposeCurrent();
    _url = url;
    _error = null;
    _loading = true;
    _playing = false;
    notifyListeners();

    VideoPlayerController? created;
    try {
      created = VideoPlayerController.networkUrl(
        Uri.parse(url),
        formatHint: VideoFormat.other,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await created.initialize().timeout(const Duration(seconds: 10));
      if (gen != _generation) {
        await created.dispose();
        return;
      }
      await created.setLooping(true);
      await created.setVolume(volume.clamp(0.0, 1.0));
      await created.play();
      _player = created;
      created.addListener(_onTick);
      _loading = false;
      _playing = true;
      _error = null;
      notifyListeners();
    } catch (e, st) {
      debugPrint('Feed video init failed: $e\n$st');
      await created?.dispose();
      if (gen != _generation) return;
      _player = null;
      _loading = false;
      _playing = false;
      _error = 'Impossible de lire cette vidéo. Republie-la en MP4.';
      notifyListeners();
    }
  }

  void _onTick() {
    // Ignore transient "not playing" while we intentionally keep playback on
    // after seeks — otherwise the play icon flashes on every scrub/tap.
    final playing = _player?.value.isPlaying ?? false;
    if (playing && !_playing) {
      _playing = true;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    final c = _player;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
      _playing = false;
    } else {
      await c.play();
      _playing = true;
    }
    notifyListeners();
  }

  Future<void> pause() async {
    final c = _player;
    if (c == null || !c.value.isInitialized) return;
    await c.pause();
    _playing = false;
    notifyListeners();
  }

  Future<void> play() async {
    final c = _player;
    if (c == null || !c.value.isInitialized) return;
    await c.play();
    _playing = true;
    notifyListeners();
  }

  Future<void> seekTo(Duration position, {bool resume = true}) async {
    final c = _player;
    if (c == null || !c.value.isInitialized) return;
    final duration = c.value.duration;
    if (duration.inMilliseconds <= 0) return;
    final ms = position.inMilliseconds.clamp(0, duration.inMilliseconds);
    await c.seekTo(Duration(milliseconds: ms));
    if (resume) {
      await c.play();
      _playing = true;
      notifyListeners();
    }
  }

  Future<void> seekFraction(double fraction, {bool resume = true}) async {
    final c = _player;
    if (c == null || !c.value.isInitialized) return;
    final duration = c.value.duration;
    if (duration.inMilliseconds <= 0) return;
    final ms = (duration.inMilliseconds * fraction.clamp(0.0, 1.0)).round();
    await c.seekTo(Duration(milliseconds: ms));
    // Seeking often reports isPlaying=false briefly — keep playback on.
    if (resume) {
      await c.play();
      _playing = true;
      notifyListeners();
    }
  }

  Future<void> showError(String message) async {
    _generation++;
    await _disposeCurrent();
    _url = null;
    _loading = false;
    _playing = false;
    _error = message;
    notifyListeners();
  }

  Future<void> clear() async {
    _generation++;
    await _disposeCurrent();
    _url = null;
    _error = null;
    _loading = false;
    _playing = false;
    notifyListeners();
  }

  Future<void> _disposeCurrent() async {
    final c = _player;
    _player = null;
    if (c != null) {
      c.removeListener(_onTick);
      try {
        await c.pause();
      } catch (_) {}
      await c.dispose();
    }
  }

  @override
  void dispose() {
    _generation++;
    final c = _player;
    _player = null;
    c?.removeListener(_onTick);
    unawaited(c?.dispose() ?? Future.value());
    super.dispose();
  }
}
