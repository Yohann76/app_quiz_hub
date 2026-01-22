import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/language.dart';
import '../../core/constants/app_constants.dart';
import 'auth_service.dart';
import 'database_service.dart';

/// Service pour gérer le profil utilisateur avec cache local
class UserService {
  final AuthService _authService;
  final DatabaseService _databaseService;
  final SharedPreferences _prefs;
  
  UserProfile? _cachedProfile;

  UserService({
    required AuthService authService,
    required DatabaseService databaseService,
    required SharedPreferences prefs,
  })  : _authService = authService,
        _databaseService = databaseService,
        _prefs = prefs;

  /// Obtenir le profil utilisateur actuel (depuis le cache ou Supabase)
  Future<UserProfile?> getCurrentProfile() async {
    final user = _authService.currentUser;
    if (user == null) {
      _cachedProfile = null;
      return null;
    }

    // Vérifier le cache local d'abord
    if (_cachedProfile != null && _cachedProfile!.id == user.id) {
      return _cachedProfile;
    }

    try {
      // Charger depuis Supabase
      final profileData = await _databaseService.getUserProfile(user.id);
      
      if (profileData != null) {
        _cachedProfile = UserProfile.fromJson(profileData);
        // Sauvegarder dans le cache local
        await _saveProfileToCache(_cachedProfile!);
        return _cachedProfile;
      }

      // Si le profil n'existe pas encore, créer un profil minimal
      final newProfile = UserProfile(
        id: user.id,
        email: user.email,
      );
      await saveProfile(newProfile);
      _cachedProfile = newProfile;
      return newProfile;
    } catch (e) {
      // En cas d'erreur, essayer de charger depuis le cache local
      return await _loadProfileFromCache(user.id);
    }
  }

  /// Sauvegarder le profil utilisateur (Supabase + cache local)
  Future<void> saveProfile(UserProfile profile) async {
    try {
      // Sauvegarder dans Supabase
      await _databaseService.upsertUserProfile(
        userId: profile.id,
        profile: profile.toJson(),
      );
      
      // Mettre à jour le cache
      _cachedProfile = profile;
      await _saveProfileToCache(profile);
    } catch (e) {
      // En cas d'erreur réseau, sauvegarder quand même dans le cache local
      await _saveProfileToCache(profile);
      rethrow;
    }
  }

  /// Mettre à jour le username
  Future<void> updateUsername(String username) async {
    // Vérifier que l'utilisateur est connecté
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecté. Veuillez vous reconnecter.');
    }

    // Obtenir ou créer le profil
    var currentProfile = await getCurrentProfile();
    if (currentProfile == null) {
      // Créer un nouveau profil si il n'existe pas
      currentProfile = UserProfile(
        id: user.id,
        email: user.email,
      );
      await saveProfile(currentProfile);
    }

    final updatedProfile = currentProfile.copyWith(
      username: username,
      updatedAt: DateTime.now(),
    );

    await saveProfile(updatedProfile);
  }

  /// Mettre à jour la langue
  Future<void> updateLanguage(Language language) async {
    // Vérifier que l'utilisateur est connecté
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecté. Veuillez vous reconnecter.');
    }

    // Obtenir ou créer le profil
    var currentProfile = await getCurrentProfile();
    if (currentProfile == null) {
      // Créer un nouveau profil si il n'existe pas
      currentProfile = UserProfile(
        id: user.id,
        email: user.email,
      );
      await saveProfile(currentProfile);
    }

    final updatedProfile = currentProfile.copyWith(
      language: language,
      updatedAt: DateTime.now(),
    );

    await saveProfile(updatedProfile);
    
    // Sauvegarder aussi dans SharedPreferences pour compatibilité
    await _prefs.setString(AppConstants.selectedLanguageKey, language.code);
  }

  /// Vérifier si le profil est complet
  Future<bool> isProfileComplete() async {
    final profile = await getCurrentProfile();
    return profile?.isComplete ?? false;
  }

  /// Sauvegarder le profil dans le cache local
  Future<void> _saveProfileToCache(UserProfile profile) async {
    await _prefs.setString('user_profile_id', profile.id);
    if (profile.username != null) {
      await _prefs.setString('user_profile_username', profile.username!);
    }
    if (profile.language != null) {
      await _prefs.setString('user_profile_language', profile.language!.code);
    }
    if (profile.email != null) {
      await _prefs.setString('user_profile_email', profile.email!);
    }
  }

  /// Charger le profil depuis le cache local
  Future<UserProfile?> _loadProfileFromCache(String userId) async {
    try {
      final cachedId = _prefs.getString('user_profile_id');
      if (cachedId != userId) {
        return null;
      }

      final username = _prefs.getString('user_profile_username');
      final languageCode = _prefs.getString('user_profile_language');
      final email = _prefs.getString('user_profile_email');

      return UserProfile(
        id: userId,
        email: email,
        username: username,
        language: languageCode != null ? Language.fromCode(languageCode) : null,
      );
    } catch (e) {
      return null;
    }
  }

  /// Effacer le cache local
  Future<void> clearCache() async {
    _cachedProfile = null;
    await _prefs.remove('user_profile_id');
    await _prefs.remove('user_profile_username');
    await _prefs.remove('user_profile_language');
    await _prefs.remove('user_profile_email');
  }
}

