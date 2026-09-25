import 'package:talent_foot_connect/models/feed_post.dart';

class TalentPublicProfile {
  const TalentPublicProfile({
    required this.playerId,
    required this.name,
    required this.age,
    required this.position,
    required this.badge,
    required this.city,
    required this.height,
    required this.weight,
    required this.clubs,
    required this.media,
    required this.bars,
    required this.followersCount,
    required this.performanceUnlocked,
    required this.verified,
    required this.isPro,
    this.description,
    this.photoUrl,
    this.whatsappUrl,
  });

  final String playerId;
  final String name;
  final int age;
  final String position;
  final String badge;
  final String city;
  final String height;
  final String weight;
  final String? description;
  final List<({String club, String period})> clubs;
  final List<FeedPost> media;
  final List<({String label, int value})> bars;
  final int followersCount;
  final bool performanceUnlocked;
  final bool verified;
  final bool isPro;
  final String? photoUrl;
  final String? whatsappUrl;

  String get prospectLabel => isPro ? 'PRO' : 'JOUEUR';
}
