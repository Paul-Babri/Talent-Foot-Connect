enum AppRole {
  player,
  academy,
  recruiter;

  String get dbValue => name;

  String get label {
    switch (this) {
      case AppRole.player:
        return 'Joueur';
      case AppRole.academy:
        return 'Académie';
      case AppRole.recruiter:
        return 'Recruteur';
    }
  }

  static AppRole fromDb(String? value) {
    switch (value) {
      case 'academy':
        return AppRole.academy;
      case 'recruiter':
        return AppRole.recruiter;
      case 'player':
      default:
        return AppRole.player;
    }
  }
}
