import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question.dart';
import '../models/language.dart';
import 'language_service.dart';
import 'database_service.dart';
import 'auth_service.dart';
import '../../core/constants/app_constants.dart';

/// Service pour gérer le quiz et la progression
class QuizService {
  final LanguageService _languageService;
  final DatabaseService _databaseService;
  final AuthService _authService;
  final SharedPreferences _prefs;

  QuizService({
    required LanguageService languageService,
    required DatabaseService databaseService,
    required AuthService authService,
    required SharedPreferences prefs,
  })  : _languageService = languageService,
        _databaseService = databaseService,
        _authService = authService,
        _prefs = prefs;

  /// Charger toutes les questions pour une langue
  Future<List<Question>> loadQuestions(Language language) async {
    return await _languageService.loadQuestionsForLanguage(language);
  }

  /// Obtenir les IDs des questions déjà répondues par l'utilisateur
  Future<Set<String>> getAnsweredQuestionIds(Language language) async {
    final user = _authService.currentUser;
    if (user == null) return <String>{};

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('user_question_responses')
          .select('question_id')
          .eq('user_id', user.id)
          .eq('language', language.code);

      final List<dynamic> data = response;
      return data.map((e) => e['question_id'] as String).toSet();
    } catch (e) {
      return <String>{};
    }
  }

  /// Obtenir la dernière question non répondue
  Future<Question?> getLastUnansweredQuestion(Language language) async {
    final allQuestions = await loadQuestions(language);
    final answeredIds = await getAnsweredQuestionIds(language);
    
    // Trouver la première question non répondue
    for (final question in allQuestions) {
      if (!answeredIds.contains(question.id)) {
        return question;
      }
    }
    
    return null; // Toutes les questions ont été répondues
  }

  /// Enregistrer une réponse à une question
  Future<void> saveAnswer({
    required Question question,
    required Language language,
    required int selectedAnswerIndex,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    final isCorrect = question.isCorrect(selectedAnswerIndex);

    try {
      // Enregistrer la réponse dans user_question_responses
      final supabase = Supabase.instance.client;
      await supabase
          .from('user_question_responses')
          .upsert({
            'user_id': user.id,
            'question_id': question.id,
            'language': language.code,
            'is_correct': isCorrect,
            'selected_answer_index': selectedAnswerIndex,
            'category': question.category,
            'difficulty': question.difficulty,
            'answered_at': DateTime.now().toIso8601String(),
          });

      // Mettre à jour les statistiques globales
      await _updateUserStats(isCorrect);
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de la réponse: $e');
    }
  }

  /// Mettre à jour les statistiques utilisateur
  Future<void> _updateUserStats(bool isCorrect) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      // Récupérer les stats actuelles
      final currentStats = await _databaseService.getUserStats(user.id);
      
      final totalQuestions = (currentStats?['total_questions'] as int? ?? 0) + 1;
      final totalCorrect = (currentStats?['total_correct_answers'] as int? ?? 0) + (isCorrect ? 1 : 0);
      final averageScore = totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0.0;

      // Mettre à jour les stats
      await _databaseService.saveUserStats(
        userId: user.id,
        stats: {
          'total_questions': totalQuestions,
          'total_correct_answers': totalCorrect,
          'average_score': averageScore,
        },
      );
    } catch (e) {
      print('Erreur lors de la mise à jour des stats: $e');
    }
  }

  /// Obtenir les statistiques de l'utilisateur
  Future<Map<String, dynamic>?> getUserStats() async {
    final user = _authService.currentUser;
    if (user == null) return null;

    return await _databaseService.getUserStats(user.id);
  }
}

