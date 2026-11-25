import '../models/language.dart';

/// Profil du joueur, propre à ce téléphone (aucun compte en ligne).
class UserProfile {
  final String? username;
  final Language? language;

  const UserProfile({
    this.username,
    this.language,
  });

  /// Vérifier si le profil est complet (a un username et une langue)
  bool get isComplete => username != null && username!.isNotEmpty && language != null;
}
