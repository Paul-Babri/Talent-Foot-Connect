enum FeedMediaType { image, video }

class FeedPost {
  const FeedPost({
    required this.id,
    required this.playerId,
    required this.mediaUrl,
    required this.mediaType,
    required this.playerName,
    required this.age,
    required this.likesCount,
    required this.createdAt,
    this.caption,
    this.position,
    this.city,
    this.country,
    this.goals = 0,
    this.assists = 0,
    this.playerPhotoUrl,
  });

  final String id;
  final String playerId;
  final String mediaUrl;
  final FeedMediaType mediaType;
  final String? caption;
  final String playerName;
  final int age;
  final String? position;
  final String? city;
  final String? country;
  final int goals;
  final int assists;
  final String? playerPhotoUrl;
  final int likesCount;
  final DateTime createdAt;

  String get location {
    final parts = [
      if (city != null && city!.isNotEmpty) city!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  factory FeedPost.fromRow(Map<String, dynamic> row) {
    final player = row['player_profiles'] as Map<String, dynamic>? ?? {};
    final typeRaw = row['media_type'] as String? ?? 'image';

    return FeedPost(
      id: row['id'] as String,
      playerId: row['player_id'] as String,
      mediaUrl: row['media_url'] as String,
      mediaType: typeRaw == 'video' ? FeedMediaType.video : FeedMediaType.image,
      caption: row['caption'] as String?,
      playerName: (player['name'] as String?)?.trim().isNotEmpty == true
          ? (player['name'] as String).trim()
          : 'Joueur',
      age: player['age'] as int? ?? 0,
      position: player['position'] as String?,
      city: player['city'] as String?,
      country: player['country'] as String?,
      goals: player['goals'] as int? ?? 0,
      assists: player['assists'] as int? ?? 0,
      playerPhotoUrl: player['photo_url'] as String?,
      likesCount: row['likes_count'] as int? ?? 0,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
