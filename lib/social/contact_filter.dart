final _digitsOnly = RegExp(r'[^0-9]');
final _contactWords = RegExp(
  r'(whatsapp|wa\.me|telegram|t\.me|\+225)',
  caseSensitive: false,
);

bool containsContact(String body) {
  final digits = body.replaceAll(_digitsOnly, '');
  return RegExp(r'[0-9]{6,}').hasMatch(digits) || _contactWords.hasMatch(body);
}

const contactBlockedMessage =
    'Les commentaires ne peuvent pas contenir de numéro ou de coordonnées.';
