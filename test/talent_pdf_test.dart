import 'package:flutter_test/flutter_test.dart';
import 'package:talent_foot_connect/models/feed_post.dart';
import 'package:talent_foot_connect/models/talent_public_profile.dart';
import 'package:talent_foot_connect/services/talent_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('génère une fiche PDF avec les infos du joueur', () async {
    final profile = TalentPublicProfile(
      playerId: 'player-1',
      name: 'Aminata Diallo',
      age: 19,
      position: 'Ailière',
      badge: 'Ailière',
      city: 'Dakar, Sénégal',
      height: '168 cm',
      weight: '58 kg',
      description: 'Joueuse rapide, pied gauche.',
      clubs: const [
        (club: 'ASC Dakar', period: 'Actuel'),
        (club: 'US Ouakam', period: '2023'),
      ],
      media: [
        FeedPost(
          id: 'post-1',
          playerId: 'player-1',
          mediaUrl: 'https://example.com/photo.jpg',
          mediaType: FeedMediaType.image,
          playerName: 'Aminata Diallo',
          age: 19,
          likesCount: 4,
          createdAt: DateTime(2026, 1, 2),
          caption: 'But contre l\'US Ouakam',
        ),
      ],
      bars: const [
        (label: 'ACCÉLÉRATION', value: 8),
        (label: 'FINITION', value: 7),
        (label: 'DRIBBLE', value: 9),
        (label: 'VISION', value: 6),
      ],
      followersCount: 120,
      performanceUnlocked: true,
      verified: true,
      isPro: true,
    );

    final bytes = await buildTalentProfilePdf(profile);

    expect(talentPdfFileName(profile.name), 'fiche-aminata-diallo.pdf');
    expect(bytes.length, greaterThan(500));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
