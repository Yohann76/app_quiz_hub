import 'package:supabase_flutter/supabase_flutter.dart';

/// Service d'authentification utilisant Supabase
class AuthService {
  final SupabaseClient _supabase;

  AuthService() : _supabase = Supabase.instance.client;

  /// Obtenir l'utilisateur actuellement connecté
  User? get currentUser => _supabase.auth.currentUser;

  /// Vérifier si un utilisateur est connecté
  bool get isAuthenticated => currentUser != null;

  /// Stream pour écouter les changements d'authentification
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Connexion avec email et mot de passe
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Inscription avec email et mot de passe
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  /// Connexion avec GitHub (OAuth)
  Future<bool> signInWithGitHub() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: 'io.supabase.quizhub://login-callback',
      );
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la connexion avec GitHub: $e');
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Réinitialiser le mot de passe
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Mettre à jour le mot de passe
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Mettre à jour le profil utilisateur
  Future<UserResponse> updateProfile({
    String? email,
    Map<String, dynamic>? data,
  }) async {
    final attributes = UserAttributes(
      email: email,
      data: data,
    );
    return await _supabase.auth.updateUser(attributes);
  }
}

