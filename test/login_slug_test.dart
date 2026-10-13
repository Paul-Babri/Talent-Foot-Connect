import 'package:flutter_test/flutter_test.dart';
import 'package:talent_foot_connect/services/auth_service.dart';

void main() {
  test('le nom devient un identifiant de connexion stable', () {
    expect(loginSlug('Jean Kouassi'), 'jean.kouassi');
    expect(
      loginEmailFromName('Aminata Diallo'),
      'aminata.diallo@login.talentfoot.app',
    );
    expect(
      resolveAuthEmail(name: 'Jean Kouassi', email: ''),
      'jean.kouassi@login.talentfoot.app',
    );
    expect(
      resolveAuthEmail(name: 'Jean Kouassi', email: 'jean@mail.com'),
      'jean@mail.com',
    );
  });
}
