import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talent_foot_connect/media/media_file_utils.dart';
import 'package:talent_foot_connect/models/feed_post.dart';

class FeedService {
  FeedService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<FeedPost>> fetchFeed({int limit = 50}) async {
    final rows = await _client
        .from('feed_posts')
        .select(
          'id, player_id, media_url, media_type, caption, likes_count, created_at, '
          'player_profiles(name, age, position, city, country, goals, assists, photo_url)',
        )
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((row) => FeedPost.fromRow(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<bool> currentUserIsPlayer() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    final row = await _client
        .from('player_profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    return row != null;
  }

  Future<FeedPost> createPost({
    required File file,
    required FeedMediaType mediaType,
    String? caption,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Tu dois être connecté pour publier.');
    }

    final isPlayer = await currentUserIsPlayer();
    if (!isPlayer) {
      throw const AuthException(
        'Seuls les joueurs peuvent publier sur le feed.',
      );
    }

    final isVideo = mediaType == FeedMediaType.video;
    final uploadFile = await ensureLocalPlayableFile(file, isVideo: isVideo);
    final ext = safeMediaExtension(uploadFile.path, isVideo: isVideo);
    final contentType = contentTypeForExtension(ext, isVideo: isVideo);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final path = '${user.id}/$fileName';

    await _client.storage.from('feed').upload(
          path,
          uploadFile,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );
    final mediaUrl = _client.storage.from('feed').getPublicUrl(path);

    final inserted = await _client
        .from('feed_posts')
        .insert({
          'player_id': user.id,
          'media_url': mediaUrl,
          'media_type': isVideo ? 'video' : 'image',
          'caption':
              caption?.trim().isEmpty == true ? null : caption?.trim(),
        })
        .select(
          'id, player_id, media_url, media_type, caption, likes_count, created_at, '
          'player_profiles(name, age, position, city, country, goals, assists, photo_url)',
        )
        .single();

    return FeedPost.fromRow(Map<String, dynamic>.from(inserted));
  }
}
