import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';

/// Service pour interagir avec la base de données Supabase
class DatabaseService {
  final SupabaseClient _supabase;

  DatabaseService() : _supabase = Supabase.instance.client;

  /// Enregistrer les statistiques d'un utilisateur
  Future<void> saveUserStats({
    required String userId,
    required Map<String, dynamic> stats,
  }) async {
    await _supabase
        .from(AppConstants.userStatsTable)
        .upsert({
          'user_id': userId,
          ...stats,
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  /// Récupérer les statistiques d'un utilisateur
  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    final response = await _supabase
        .from(AppConstants.userStatsTable)
        .select()
        .eq('user_id', userId)
        .single();

    return response as Map<String, dynamic>?;
  }

  /// Enregistrer l'historique d'un quiz
  Future<void> saveQuizHistory({
    required String userId,
    required Map<String, dynamic> quizData,
  }) async {
    await _supabase
        .from(AppConstants.quizHistoryTable)
        .insert({
          'user_id': userId,
          ...quizData,
          'created_at': DateTime.now().toIso8601String(),
        });
  }

  /// Récupérer l'historique des quiz d'un utilisateur
  Future<List<Map<String, dynamic>>> getQuizHistory(
    String userId, {
    int limit = 50,
  }) async {
    final response = await _supabase
        .from(AppConstants.quizHistoryTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Créer ou mettre à jour un profil utilisateur
  Future<void> upsertUserProfile({
    required String userId,
    required Map<String, dynamic> profile,
  }) async {
    await _supabase
        .from(AppConstants.usersTable)
        .upsert({
          'id': userId,
          ...profile,
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  /// Récupérer le profil d'un utilisateur
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from(AppConstants.usersTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      // Si le profil n'existe pas, retourner null
      return null;
    }
  }
}

