import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talent_foot_connect/media/media_file_utils.dart';
import 'package:talent_foot_connect/models/feed_post.dart';
import 'package:talent_foot_connect/models/publish_quota.dart';
import 'package:talent_foot_connect/services/entitlement_service.dart';
import 'package:talent_foot_connect/services/social_service.dart';

class FeedService {
  FeedService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<FeedPost>> fetchFeed({int limit = 50}) async {
    final rows = await _client
        .from('feed_posts')
        .select(
          'id, player_id, media_url, media_type, caption, likes_count, comments_count, created_at, '
          'player_profiles(name, age, position, city, country, goals, assists, photo_url, followers_count, '
          'player_entitlements(plan, pro_until))',
        )
        .order('created_at', ascending: false)
        .limit(limit);

    final posts = (rows as List)
        .map((row) => FeedPost.fromRow(Map<String, dynamic>.from(row as Map)))
        .toList();
    posts.sort((a, b) {
      if (a.isPro != b.isPro) return a.isPro ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    final social = SocialService(client: _client);
    final ids = posts.map((post) => post.id).toList();
    final playerIds = posts.map((post) => post.playerId).toSet().toList();
    final liked = await social.likedPostIds(ids);
    final followed = await social.followedPlayerIds(playerIds);
    return [
      for (final post in posts)
        post.copyWith(
          likedByMe: liked.contains(post.id),
          followedByMe: followed.contains(post.playerId),
        ),
    ];
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

    final quota = await EntitlementService(client: _client).fetchQuota();
    final isVideo = mediaType == FeedMediaType.video;
    if (isVideo && !quota.canVideo) {
      throw const QuotaExceeded(
        'Tu as atteint les 3 vidéos gratuites. Choisis une offre pour continuer.',
      );
    }
    if (!isVideo && !quota.canPhoto) {
      throw const QuotaExceeded(
        'Tu as atteint les 10 photos du pack gratuit.',
      );
    }

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
          'id, player_id, media_url, media_type, caption, likes_count, comments_count, created_at, '
          'player_profiles(name, age, position, city, country, goals, assists, photo_url, followers_count, '
          'player_entitlements(plan, pro_until))',
        )
        .single();

    return FeedPost.fromRow(Map<String, dynamic>.from(inserted));
  }
}
