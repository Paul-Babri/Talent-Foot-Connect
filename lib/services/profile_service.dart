import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talent_foot_connect/models/app_role.dart';
import 'package:talent_foot_connect/models/app_user_profile.dart';

class ProfileService {
  ProfileService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AppUserProfile?> fetchCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final profileRow = await _client
        .from('profiles')
        .select('id, role, email, phone, verified')
        .eq('id', user.id)
        .maybeSingle();

    if (profileRow == null) return null;

    final role = AppRole.fromDb(profileRow['role'] as String?);
    final email = profileRow['email'] as String? ?? user.email;
    final phone = profileRow['phone'] as String?;
    final verified = profileRow['verified'] as bool? ?? false;

    switch (role) {
      case AppRole.player:
        return _fetchPlayer(
          userId: user.id,
          email: email,
          phone: phone,
          verified: verified,
        );
      case AppRole.academy:
        return _fetchAcademy(
          userId: user.id,
          email: email,
          phone: phone,
          verified: verified,
        );
      case AppRole.recruiter:
        return _fetchRecruiter(
          userId: user.id,
          email: email,
          phone: phone,
          verified: verified,
        );
    }
  }

  Future<AppUserProfile> _fetchPlayer({
    required String userId,
    required String? email,
    required String? phone,
    required bool verified,
  }) async {
    final row = await _client
        .from('player_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row == null) {
      return AppUserProfile(
        id: userId,
        role: AppRole.player,
        email: email,
        phone: phone,
        verified: verified,
        displayName: email ?? 'Joueur',
        badgeLabel: 'JOUEUR',
      );
    }

    final name = (row['name'] as String?)?.trim();
    final age = row['age'] as int?;
    final position = row['position'] as String?;
    final club = row['club'] as String?;
    final academy = row['academy'] as String?;
    final city = row['city'] as String?;
    final country = row['country'] as String?;
    final goals = row['goals'] as int? ?? 0;
    final assists = row['assists'] as int? ?? 0;
    final height = row['height_cm'] as int?;
    final weight = row['weight_kg'] as int?;
    final description = row['description'] as String?;
    final photoUrl = row['photo_url'] as String?;

    final location = [
      if (city != null && city.isNotEmpty) city,
      if (country != null && country.isNotEmpty) country,
    ].join(', ');

    return AppUserProfile(
      id: userId,
      role: AppRole.player,
      email: email,
      phone: phone,
      verified: verified,
      displayName: (name == null || name.isEmpty) ? 'Joueur' : name,
      subtitle: [
        if (club != null && club.isNotEmpty) club,
        if (academy != null && academy.isNotEmpty) academy,
        if (location.isNotEmpty) location,
      ].join(' · '),
      badgeLabel: position?.toUpperCase() ?? 'JOUEUR',
      avatarUrl: photoUrl,
      description: description,
      stat1: (value: '$goals', label: 'BUTS'),
      stat2: (value: '$assists', label: 'ASSISTS'),
      stat3: age == null ? null : (value: '$age', label: 'ÂGE'),
      details: [
        if (email != null && email.isNotEmpty) (label: 'E-MAIL', value: email),
        if (phone != null && phone.isNotEmpty) (label: 'TÉLÉPHONE', value: phone),
        if (height != null) (label: 'TAILLE', value: '$height cm'),
        if (weight != null) (label: 'POIDS', value: '$weight kg'),
        if (position != null && position.isNotEmpty)
          (label: 'POSTE', value: position),
      ],
    );
  }

  Future<AppUserProfile> _fetchAcademy({
    required String userId,
    required String? email,
    required String? phone,
    required bool verified,
  }) async {
    final row = await _client
        .from('academy_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row == null) {
      return AppUserProfile(
        id: userId,
        role: AppRole.academy,
        email: email,
        phone: phone,
        verified: verified,
        displayName: email ?? 'Académie',
        badgeLabel: 'ACADÉMIE',
      );
    }

    final name = (row['name'] as String?)?.trim();
    final city = row['city'] as String?;
    final country = row['country'] as String?;
    final description = row['description'] as String?;
    final logoUrl = row['logo_url'] as String?;
    final photoUrl = row['photo_url'] as String?;
    final location = [
      if (city != null && city.isNotEmpty) city,
      if (country != null && country.isNotEmpty) country,
    ].join(', ');

    return AppUserProfile(
      id: userId,
      role: AppRole.academy,
      email: email,
      phone: phone,
      verified: verified,
      displayName: (name == null || name.isEmpty) ? 'Académie' : name,
      subtitle: location.isEmpty ? null : location,
      badgeLabel: 'ACADÉMIE',
      avatarUrl: logoUrl ?? photoUrl,
      description: description,
      details: [
        if (email != null && email.isNotEmpty) (label: 'E-MAIL', value: email),
        if (phone != null && phone.isNotEmpty) (label: 'TÉLÉPHONE', value: phone),
        if (location.isNotEmpty) (label: 'LOCALISATION', value: location),
      ],
    );
  }

  Future<AppUserProfile> _fetchRecruiter({
    required String userId,
    required String? email,
    required String? phone,
    required bool verified,
  }) async {
    final row = await _client
        .from('recruiter_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row == null) {
      return AppUserProfile(
        id: userId,
        role: AppRole.recruiter,
        email: email,
        phone: phone,
        verified: verified,
        displayName: email ?? 'Recruteur',
        badgeLabel: 'RECRUTEUR',
      );
    }

    final name = (row['name'] as String?)?.trim();
    final type = row['type'] as String?;
    final country = row['country'] as String?;
    final description = row['description'] as String?;
    final besoins = row['besoins'] as String?;

    return AppUserProfile(
      id: userId,
      role: AppRole.recruiter,
      email: email,
      phone: phone,
      verified: verified,
      displayName: (name == null || name.isEmpty) ? 'Recruteur' : name,
      subtitle: [
        if (type != null && type.isNotEmpty) type,
        if (country != null && country.isNotEmpty) country,
      ].join(' · '),
      badgeLabel: (type ?? 'RECRUTEUR').toUpperCase(),
      description: description,
      details: [
        if (email != null && email.isNotEmpty) (label: 'E-MAIL', value: email),
        if (phone != null && phone.isNotEmpty) (label: 'TÉLÉPHONE', value: phone),
        if (country != null && country.isNotEmpty)
          (label: 'PAYS', value: country),
        if (besoins != null && besoins.isNotEmpty)
          (label: 'BESOINS', value: besoins),
      ],
    );
  }

  Future<Map<String, dynamic>?> fetchPlayerRow(String userId) {
    return _client
        .from('player_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  Future<void> updatePlayerAccount({
    required String userId,
    required String name,
    required int age,
    String? phone,
    String? position,
    int? heightCm,
    int? weightKg,
    String? club,
    String? academy,
    String? city,
    String? country,
    int? goals,
    int? assists,
    String? description,
  }) async {
    final payload = <String, dynamic>{
      'id': userId,
      'name': name.trim(),
      'age': age,
      'position': position,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'club': club,
      'academy': academy,
      'city': city,
      'country': country,
      'goals': goals ?? 0,
      'assists': assists ?? 0,
      'description': description,
    }..removeWhere((_, value) => value == null);

    payload['club'] = club;

    await _client.from('player_profiles').upsert(payload);

    if (phone != null) {
      await _client
          .from('profiles')
          .update({'phone': phone.trim()})
          .eq('id', userId);
    }
  }
}
