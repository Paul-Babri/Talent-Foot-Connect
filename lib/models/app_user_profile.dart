import 'package:talent_foot_connect/models/app_role.dart';

class AppUserProfile {
  const AppUserProfile({
    required this.id,
    required this.role,
    required this.email,
    required this.phone,
    required this.verified,
    required this.displayName,
    this.subtitle,
    this.badgeLabel,
    this.avatarUrl,
    this.description,
    this.stat1,
    this.stat2,
    this.stat3,
    this.details = const [],
  });

  final String id;
  final AppRole role;
  final String? email;
  final String? phone;
  final bool verified;
  final String displayName;
  final String? subtitle;
  final String? badgeLabel;
  final String? avatarUrl;
  final String? description;
  final ({String value, String label})? stat1;
  final ({String value, String label})? stat2;
  final ({String value, String label})? stat3;
  final List<({String label, String value})> details;
}
