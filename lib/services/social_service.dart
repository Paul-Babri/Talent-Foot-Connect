import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talent_foot_connect/models/feed_post.dart';
import 'package:talent_foot_connect/social/contact_filter.dart';

class FeedComment {
  const FeedComment({
    required this.id,
    required this.authorName,
    required this.body,
    required this.createdAt,
    required this.mine,
  });

  final String id;
  final String authorName;
  final String body;
  final DateTime createdAt;
  final bool mine;
}

class FollowedPlayer {
  const FollowedPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.age,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String position;
  final int age;
  final String? photoUrl;
}

class SocialService {
  SocialService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  Future<Set<String>> likedPostIds(List<String> postIds) async {
    final uid = _uid;
    if (uid == null || postIds.isEmpty) return {};
    final rows = await _client
        .from('feed_likes')
        .select('post_id')
        .eq('user_id', uid)
        .inFilter('post_id', postIds);
    return (rows as List)
        .map((row) => (row as Map)['post_id'] as String)
        .toSet();
  }

  Future<Set<String>> followedPlayerIds(List<String> playerIds) async {
    final uid = _uid;
    if (uid == null || playerIds.isEmpty) return {};
    final rows = await _client
        .from('player_follows')
        .select('player_id')
        .eq('follower_id', uid)
        .inFilter('player_id', playerIds);
    return (rows as List)
        .map((row) => (row as Map)['player_id'] as String)
        .toSet();
  }

  Future<void> setLike({required String postId, required bool like}) async {
    final uid = _uid;
    if (uid == null) {
      throw const AuthException('Connecte-toi pour aimer une publication.');
    }
    if (like) {
      await _client.from('feed_likes').insert({
        'post_id': postId,
        'user_id': uid,
      });
    } else {
      await _client
          .from('feed_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', uid);
    }
  }

  Future<void> setFollow({
    required String playerId,
    required bool follow,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw const AuthException('Connecte-toi pour suivre un joueur.');
    }
    if (uid == playerId) return;
    if (follow) {
      await _client.from('player_follows').insert({
        'follower_id': uid,
        'player_id': playerId,
      });
    } else {
      await _client
          .from('player_follows')
          .delete()
          .eq('follower_id', uid)
          .eq('player_id', playerId);
    }
  }

  Future<List<FeedComment>> commentsFor(String postId) async {
    final rows = await _client
        .from('feed_comments')
        .select('id, author_id, body, created_at, profiles(email)')
        .eq('post_id', postId)
        .order('created_at');
    final uid = _uid;
    return (rows as List).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      final profile = row['profiles'];
      String name = 'Membre';
      if (profile is Map && profile['email'] is String) {
        final email = profile['email'] as String;
        name = email.contains('@') ? email.split('@').first : email;
      }
      return FeedComment(
        id: row['id'] as String,
        authorName: name,
        body: row['body'] as String? ?? '',
        createdAt:
            DateTime.tryParse(row['created_at'] as String? ?? '') ??
            DateTime.now(),
        mine: row['author_id'] == uid,
      );
    }).toList();
  }

  Future<void> addComment({required String postId, required String body}) async {
    final uid = _uid;
    if (uid == null) {
      throw const AuthException('Connecte-toi pour commenter.');
    }
    final text = body.trim();
    if (text.isEmpty) {
      throw const AuthException('Écris un commentaire.');
    }
    if (containsContact(text)) {
      throw const AuthException(contactBlockedMessage);
    }
    await _client.from('feed_comments').insert({
      'post_id': postId,
      'author_id': uid,
      'body': text,
    });
  }

  Future<List<FollowedPlayer>> followedPlayers() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _client
        .from('player_follows')
        .select('player_id, player_profiles(name, age, position, photo_url)')
        .eq('follower_id', uid)
        .order('created_at', ascending: false);
    return (rows as List).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      final player = row['player_profiles'];
      final map = player is Map ? Map<String, dynamic>.from(player) : const {};
      final name = (map['name'] as String?)?.trim();
      return FollowedPlayer(
        id: row['player_id'] as String,
        name: (name == null || name.isEmpty) ? 'Joueur' : name,
        position: (map['position'] as String?) ?? 'Joueur',
        age: map['age'] as int? ?? 0,
        photoUrl: map['photo_url'] as String?,
      );
    }).toList();
  }
}

class ClubEntry {
  const ClubEntry({required this.name, required this.year});

  final String name;
  final String year;
}

class TalentMedia {
  const TalentMedia({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
  });

  final String id;
  final String mediaUrl;
  final FeedMediaType mediaType;
  final String? caption;
}
