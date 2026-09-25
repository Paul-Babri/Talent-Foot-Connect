import 'package:supabase_flutter/supabase_flutter.dart';

class SearchPlayer {
  const SearchPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.age,
    required this.location,
    required this.isPro,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String position;
  final int age;
  final String location;
  final bool isPro;
  final String? photoUrl;
}

class SearchService {
  SearchService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const positions = [
    'Gardien',
    'Défenseur central',
    'Latéral droit',
    'Latéral gauche',
    'Milieu défensif',
    'Milieu offensif',
    'Ailier droit',
    'Ailier gauche',
    'Attaquant',
  ];

  Future<List<SearchPlayer>> search({String? position}) async {
    var query = _client.from('player_profiles').select(
          'id, name, age, position, city, country, photo_url, '
          'player_entitlements(plan, pro_until)',
        );
    if (position != null && position.isNotEmpty) {
      query = query.eq('position', position);
    }
    final rows = await query.order('name');
    final players = (rows as List).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      final entitlement = row['player_entitlements'];
      Map<String, dynamic>? plan;
      if (entitlement is Map) {
        plan = Map<String, dynamic>.from(entitlement);
      } else if (entitlement is List && entitlement.isNotEmpty) {
        plan = Map<String, dynamic>.from(entitlement.first as Map);
      }
      final until = DateTime.tryParse(plan?['pro_until'] as String? ?? '');
      final isPro = plan?['plan'] == 'pro' &&
          until != null &&
          until.isAfter(DateTime.now());
      final city = [
        if ((row['city'] as String?)?.isNotEmpty == true) row['city'] as String,
        if ((row['country'] as String?)?.isNotEmpty == true)
          row['country'] as String,
      ].join(', ');
      final name = (row['name'] as String?)?.trim();
      return SearchPlayer(
        id: row['id'] as String,
        name: (name == null || name.isEmpty) ? 'Joueur' : name,
        position: (row['position'] as String?) ?? 'Joueur',
        age: row['age'] as int? ?? 0,
        location: city.isEmpty ? '—' : city,
        isPro: isPro,
        photoUrl: row['photo_url'] as String?,
      );
    }).toList();

    players.sort((a, b) {
      if (a.isPro != b.isPro) return a.isPro ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return players;
  }
}
