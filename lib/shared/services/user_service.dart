import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/language.dart';
import '../../core/constants/app_constants.dart';

/// Service pour gérer le profil local du joueur
class UserService {
  final SharedPreferences _prefs;

  UserService(this._prefs);

  /// Obtenir le profil enregistré sur le téléphone
  UserProfile getCurrentProfile() {
    final languageCode = _prefs.getString(AppConstants.selectedLanguageKey);
    return UserProfile(
      username: _prefs.getString(AppConstants.usernameKey),
      language: languageCode != null ? Language.fromCode(languageCode) : null,
    );
  }

  /// Enregistrer le pseudo et la langue
  Future<void> saveProfile({
    required String username,
    required Language language,
  }) async {
    await _prefs.setString(AppConstants.usernameKey, username);
    await updateLanguage(language);
  }

  /// Mettre à jour la langue
  Future<void> updateLanguage(Language language) async {
    await _prefs.setString(AppConstants.selectedLanguageKey, language.code);
  }

  /// Vérifier si le profil est complet
  bool isProfileComplete() => getCurrentProfile().isComplete;
}
