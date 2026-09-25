enum OfferSku { videoUnit, pack5, pack10, proMonth }

class Offer {
  const Offer({
    required this.sku,
    required this.title,
    required this.detail,
    required this.amountFcfa,
  });

  final OfferSku sku;
  final String title;
  final String detail;
  final int amountFcfa;

  String get dbValue {
    switch (sku) {
      case OfferSku.videoUnit:
        return 'video_unit';
      case OfferSku.pack5:
        return 'pack_5';
      case OfferSku.pack10:
        return 'pack_10';
      case OfferSku.proMonth:
        return 'pro_month';
    }
  }

  String get priceLabel => '$amountFcfa FCFA';
}

const offers = <Offer>[
  Offer(
    sku: OfferSku.videoUnit,
    title: '1 vidéo',
    detail: 'Une vidéo en plus du pack gratuit',
    amountFcfa: 100,
  ),
  Offer(
    sku: OfferSku.pack5,
    title: 'Pack 5 vidéos',
    detail: '5 vidéos supplémentaires',
    amountFcfa: 400,
  ),
  Offer(
    sku: OfferSku.pack10,
    title: 'Pack 10 vidéos',
    detail: '10 vidéos supplémentaires',
    amountFcfa: 700,
  ),
  Offer(
    sku: OfferSku.proMonth,
    title: 'PRO',
    detail:
        'Vidéos illimitées, profil mis en avant, analyse de performance, éligibilité au badge vérifié',
    amountFcfa: 2000,
  ),
];

const freeVideoLimit = 3;
const freePhotoLimit = 10;
