import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';

/// Service pour interagir avec la base de données Supabase
class DatabaseService {
  final SupabaseClient _supabase;

  DatabaseService() : _supabase = Supabase.instance.client;

  // Note: Les méthodes saveUserStats, getUserStats, saveQuizHistory, getQuizHistory
  // ont été supprimées car les tables user_stats et quiz_history ne sont plus utilisées.
  // Les statistiques sont calculées dynamiquement depuis user_question_responses
  // via QuizService.calculateUserStats()

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

