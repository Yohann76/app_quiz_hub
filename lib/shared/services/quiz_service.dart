import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question.dart';
import '../models/language.dart';
import 'language_service.dart';
import 'database_service.dart';
import 'auth_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/category_normalizer.dart';

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
  /// Note: On ne filtre pas par langue car les IDs sont identiques dans toutes les langues.
  /// Si une question a été répondue dans une langue, elle est considérée comme répondue dans toutes.
  Future<Set<String>> getAnsweredQuestionIds(Language language) async {
    final user = _authService.currentUser;
    if (user == null) return <String>{};

    try {
      final supabase = Supabase.instance.client;
      // Ne pas filtrer par langue : une question répondue dans une langue est considérée comme répondue dans toutes
      final response = await supabase
          .from('user_question_responses')
          .select('question_id')
          .eq('user_id', user.id);

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
      // Normaliser la catégorie vers le français pour cohérence
      final normalizedCategory = CategoryNormalizer.normalize(question.category);
      
      final supabase = Supabase.instance.client;
      await supabase
          .from('user_question_responses')
          .upsert({
            'user_id': user.id,
            'question_id': question.id,
            'language': language.code,
            'is_correct': isCorrect,
            'selected_answer_index': selectedAnswerIndex,
            'category': normalizedCategory, // Catégorie normalisée
            'difficulty': question.difficulty,
            'answered_at': DateTime.now().toIso8601String(),
          });

      // Les statistiques sont calculées dynamiquement depuis user_question_responses
      // Plus besoin de mettre à jour user_stats
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de la réponse: $e');
    }
  }

  /// Calculer les statistiques depuis user_question_responses
  Future<Map<String, dynamic>> calculateUserStats({Language? language}) async {
    final user = _authService.currentUser;
    if (user == null) {
      return {
        'total_questions': 0,
        'total_correct_answers': 0,
        'average_score': 0.0,
        'total_by_category': <String, int>{},
        'total_correct_by_category': <String, int>{},
      };
    }

    try {
      final supabase = Supabase.instance.client;
      
      // Construire la requête
      var query = supabase
          .from('user_question_responses')
          .select()
          .eq('user_id', user.id);
      
      // Filtrer par langue si spécifiée
      if (language != null) {
        query = query.eq('language', language.code);
      }
      
      final response = await query;
      final List<dynamic> data = response;
      
      // Debug: afficher le nombre de réponses récupérées
      if (kDebugMode) {
        print('📊 calculateUserStats: ${data.length} réponses récupérées depuis Supabase');
        if (data.isNotEmpty) {
          print('📊 Première réponse: ${data.first}');
        }
      }
      
      final totalQuestions = data.length;
      final totalCorrect = data.where((r) => r['is_correct'] == true).length;
      final averageScore = totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0.0;
      
      // Calculer par catégorie (normalisées vers le français)
      final Map<String, int> totalByCategory = {};
      final Map<String, int> correctByCategory = {};
      
      for (final response in data) {
        final rawCategory = response['category'] as String? ?? 'unknown';
        // Normaliser la catégorie vers le français
        final category = CategoryNormalizer.normalize(rawCategory);
        
        if (kDebugMode && rawCategory != category) {
          print('📊 Catégorie normalisée: "$rawCategory" → "$category"');
        }
        
        totalByCategory[category] = (totalByCategory[category] ?? 0) + 1;
        if (response['is_correct'] == true) {
          correctByCategory[category] = (correctByCategory[category] ?? 0) + 1;
        }
      }
      
      if (kDebugMode) {
        print('📊 Stats calculées: $totalQuestions questions, $totalCorrect correctes');
        print('📊 Catégories: $totalByCategory');
      }
      
      return {
        'total_questions': totalQuestions,
        'total_correct_answers': totalCorrect,
        'average_score': averageScore,
        'total_by_category': totalByCategory,
        'total_correct_by_category': correctByCategory,
      };
    } catch (e) {
      print('Erreur lors du calcul des stats: $e');
      return {
        'total_questions': 0,
        'total_correct_answers': 0,
        'average_score': 0.0,
        'total_by_category': <String, int>{},
        'total_correct_by_category': <String, int>{},
      };
    }
  }

  /// Obtenir les statistiques de l'utilisateur (calculées depuis user_question_responses)
  Future<Map<String, dynamic>> getUserStats({Language? language}) async {
    return await calculateUserStats(language: language);
  }
}

