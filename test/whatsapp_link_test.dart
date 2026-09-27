import 'package:flutter_test/flutter_test.dart';
import 'package:talent_foot_connect/services/talent_service.dart';

void main() {
  test('le numéro admin ouvre WhatsApp au format Côte d\'Ivoire', () {
    expect(whatsappDigits(platformAdminPhone), '2250173221661');
    expect(whatsappLink(platformAdminPhone), 'https://wa.me/2250173221661');
  });
}
