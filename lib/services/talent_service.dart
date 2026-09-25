import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talent_foot_connect/models/feed_post.dart';
import 'package:talent_foot_connect/models/talent_public_profile.dart';
import 'package:talent_foot_connect/services/social_service.dart';

class PlayerPerformance {
  const PlayerPerformance({
    required this.acceleration,
    required this.finishing,
    required this.dribble,
    required this.vision,
  });

  final int acceleration;
  final int finishing;
  final int dribble;
  final int vision;
}

class TalentService {
  TalentService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<TalentPublicProfile> fetch(String playerId) async {
    final me = _client.auth.currentUser?.id;
    if (me != null && me != playerId) {
      try {
        await _client.from('profile_views').insert({
          'player_id': playerId,
          'viewer_id': me,
        });
      } catch (_) {}
    }

    final player = await _client
        .from('player_profiles')
        .select(
          'id, name, age, position, height_cm, weight_kg, club, city, country, '
          'description, photo_url, followers_count, '
          'player_entitlements(plan, pro_until)',
        )
        .eq('id', playerId)
        .single();

    final history = await _client
        .from('player_club_history')
        .select('club_name, year_label, sort_order')
        .eq('player_id', playerId)
        .order('sort_order');

    final posts = await _client
        .from('feed_posts')
        .select(
          'id, player_id, media_url, media_type, caption, likes_count, comments_count, created_at',
        )
        .eq('player_id', playerId)
        .order('created_at', ascending: false);

    final performance = await _client
        .from('player_performance')
        .select('acceleration, finishing, dribble, vision')
        .eq('player_id', playerId)
        .maybeSingle();

    String? whatsappUrl;
    if (me != null) {
      final viewer = await _client
          .from('profiles')
          .select('role')
          .eq('id', me)
          .maybeSingle();
      final role = viewer?['role'] as String?;
      if (role == 'academy' || role == 'recruiter') {
        final phoneRow = await _client
            .from('profiles')
            .select('phone')
            .eq('id', playerId)
            .maybeSingle();
        whatsappUrl = whatsappLink(phoneRow?['phone'] as String?);
      }
    }

    final row = Map<String, dynamic>.from(player);
    final entitlement = _asMap(row['player_entitlements']);
    final proUntil = DateTime.tryParse(entitlement?['pro_until'] as String? ?? '');
    final isPro = entitlement?['plan'] == 'pro' &&
        proUntil != null &&
        proUntil.isAfter(DateTime.now());

    final currentClub = (row['club'] as String?)?.trim();
    final clubs = <({String club, String period})>[
      if (currentClub != null && currentClub.isNotEmpty)
        (club: currentClub, period: 'Actuel'),
      for (final raw in history as List)
        (
          club: ((raw as Map)['club_name'] as String).trim(),
          period: (raw['year_label'] as String).trim(),
        ),
    ];

    final media = (posts as List).map((raw) {
      final post = Map<String, dynamic>.from(raw as Map);
      post['player_profiles'] = {
        'name': row['name'],
        'age': row['age'],
        'position': row['position'],
        'city': row['city'],
        'country': row['country'],
        'photo_url': row['photo_url'],
        'followers_count': row['followers_count'],
      };
      return FeedPost.fromRow(post);
    }).toList();

    final bars = performance == null
        ? const <({String label, int value})>[]
        : <({String label, int value})>[
            (label: 'ACCÉLÉRATION', value: performance['acceleration'] as int),
            (label: 'FINITION', value: performance['finishing'] as int),
            (label: 'DRIBBLE', value: performance['dribble'] as int),
            (label: 'VISION', value: performance['vision'] as int),
          ];

    final profileRow = await _client
        .from('profiles')
        .select('verified')
        .eq('id', playerId)
        .maybeSingle();
    final city = [
      if ((row['city'] as String?)?.isNotEmpty == true) row['city'] as String,
      if ((row['country'] as String?)?.isNotEmpty == true)
        row['country'] as String,
    ].join(', ');

    final height = row['height_cm'] as int?;
    final weight = row['weight_kg'] as int?;
    final name = (row['name'] as String?)?.trim();

    return TalentPublicProfile(
      playerId: playerId,
      name: (name == null || name.isEmpty) ? 'Joueur' : name,
      age: row['age'] as int? ?? 0,
      position: (row['position'] as String?)?.trim().isNotEmpty == true
          ? (row['position'] as String).trim()
          : 'Joueur',
      badge: (row['position'] as String?)?.trim().isNotEmpty == true
          ? (row['position'] as String).trim()
          : 'Joueur',
      city: city.isEmpty ? '—' : city,
      height: height == null ? '—' : '$height cm',
      weight: weight == null ? '—' : '$weight kg',
      description: row['description'] as String?,
      clubs: clubs,
      media: media,
      bars: bars,
      followersCount: row['followers_count'] as int? ?? 0,
      performanceUnlocked: isPro,
      verified: profileRow?['verified'] as bool? ?? false,
      isPro: isPro,
      photoUrl: row['photo_url'] as String?,
      whatsappUrl: whatsappUrl,
    );
  }

  Future<void> recordContact(String playerId) async {
    final me = _client.auth.currentUser?.id;
    if (me == null || me == playerId) return;
    await _client.from('profile_contacts').insert({
      'player_id': playerId,
      'viewer_id': me,
    });
  }

  Future<List<ClubEntry>> clubHistory(String playerId) async {
    final rows = await _client
        .from('player_club_history')
        .select('club_name, year_label, sort_order')
        .eq('player_id', playerId)
        .order('sort_order');
    return (rows as List)
        .map(
          (raw) => ClubEntry(
            name: (raw as Map)['club_name'] as String,
            year: raw['year_label'] as String,
          ),
        )
        .toList();
  }

  Future<void> replaceClubHistory({
    required String playerId,
    required List<ClubEntry> clubs,
  }) async {
    await _client.from('player_club_history').delete().eq('player_id', playerId);
    final cleaned = clubs
        .where((club) => club.name.trim().isNotEmpty && club.year.trim().isNotEmpty)
        .take(3)
        .toList();
    if (cleaned.isEmpty) return;
    await _client.from('player_club_history').insert([
      for (var i = 0; i < cleaned.length; i++)
        {
          'player_id': playerId,
          'club_name': cleaned[i].name.trim(),
          'year_label': cleaned[i].year.trim(),
          'sort_order': i + 1,
        },
    ]);
  }

  Future<PlayerPerformance?> performanceFor(String playerId) async {
    final row = await _client
        .from('player_performance')
        .select('acceleration, finishing, dribble, vision')
        .eq('player_id', playerId)
        .maybeSingle();
    if (row == null) return null;
    return PlayerPerformance(
      acceleration: row['acceleration'] as int,
      finishing: row['finishing'] as int,
      dribble: row['dribble'] as int,
      vision: row['vision'] as int,
    );
  }

  Future<void> savePerformance({
    required String playerId,
    required PlayerPerformance performance,
  }) async {
    await _client.from('player_performance').upsert({
      'player_id': playerId,
      'acceleration': performance.acceleration,
      'finishing': performance.finishing,
      'dribble': performance.dribble,
      'vision': performance.vision,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    return null;
  }
}

String? whatsappLink(String? phone) {
  if (phone == null) return null;
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.startsWith('0') && digits.length == 10) {
    digits = '225${digits.substring(1)}';
  }
  if (digits.length < 8) return null;
  return 'https://wa.me/$digits';
}
