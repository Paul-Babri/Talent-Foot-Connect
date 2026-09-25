class PublishQuota {
  const PublishQuota({
    required this.plan,
    required this.proActive,
    required this.videoCredits,
    required this.videosUsed,
    required this.photosUsed,
    required this.canVideo,
    required this.canPhoto,
    this.proUntil,
  });

  final String plan;
  final bool proActive;
  final int videoCredits;
  final int videosUsed;
  final int photosUsed;
  final bool canVideo;
  final bool canPhoto;
  final DateTime? proUntil;

  factory PublishQuota.fromJson(Map<String, dynamic> json) {
    return PublishQuota(
      plan: json['plan'] as String? ?? 'free',
      proActive: json['pro_active'] as bool? ?? false,
      videoCredits: json['video_credits'] as int? ?? 0,
      videosUsed: json['videos_used'] as int? ?? 0,
      photosUsed: json['photos_used'] as int? ?? 0,
      canVideo: json['can_video'] as bool? ?? false,
      canPhoto: json['can_photo'] as bool? ?? false,
      proUntil: DateTime.tryParse(json['pro_until'] as String? ?? ''),
    );
  }
}

class QuotaExceeded implements Exception {
  const QuotaExceeded(this.message);

  final String message;

  @override
  String toString() => message;
}
