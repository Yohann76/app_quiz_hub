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
        'total_score': 0,
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
      
      // Calculer les statistiques
      final totalResponses = data.length;
      final totalCorrect = data.where((r) => r['is_correct'] == true).length;
      
      // Calculer le nombre de questions uniques répondues
      final Set<String> uniqueQuestionIds = data.map((r) => r['question_id'] as String).toSet();
      final uniqueQuestionsAnswered = uniqueQuestionIds.length;
      
      final averageScore = totalResponses > 0 ? (totalCorrect / totalResponses * 100) : 0.0;
      
      // Calculer le score total : 5 points par bonne réponse
      const pointsPerCorrectAnswer = 5;
      final totalScore = totalCorrect * pointsPerCorrectAnswer;
      
      // Calculer par catégorie (normalisées vers le français)
      final Map<String, int> totalByCategory = {};
      final Map<String, int> correctByCategory = {};
      
      for (final response in data) {
        final rawCategory = response['category'] as String? ?? 'unknown';
        // Normaliser la catégorie vers le français
        final category = CategoryNormalizer.normalize(rawCategory);
        
        totalByCategory[category] = (totalByCategory[category] ?? 0) + 1;
        if (response['is_correct'] == true) {
          correctByCategory[category] = (correctByCategory[category] ?? 0) + 1;
        }
      }
      
      if (kDebugMode) {
        print('📊 Stats calculées: $totalResponses réponses, $uniqueQuestionsAnswered questions uniques, $totalCorrect correctes, score total: $totalScore');
      }
      
      return {
        'total_questions': totalResponses, // Nombre total de réponses (lignes en DB)
        'unique_questions_answered': uniqueQuestionsAnswered, // Nombre de questions uniques
        'total_correct_answers': totalCorrect,
        'average_score': averageScore,
        'total_score': totalScore,
        'total_by_category': totalByCategory,
        'total_correct_by_category': correctByCategory,
      };
    } catch (e) {
      print('Erreur lors du calcul des stats: $e');
      return {
        'total_questions': 0,
        'total_correct_answers': 0,
        'average_score': 0.0,
        'total_score': 0,
        'total_by_category': <String, int>{},
        'total_correct_by_category': <String, int>{},
      };
    }
  }

  /// Obtenir les statistiques de l'utilisateur (calculées depuis user_question_responses)
  Future<Map<String, dynamic>> getUserStats({Language? language}) async {
    return await calculateUserStats(language: language);
  }

  /// Calculer le classement de l'utilisateur
  /// Retourne: position, total joueurs, top 10%, top 20%, top 50%
  Future<Map<String, dynamic>> getUserRanking() async {
    final user = _authService.currentUser;
    if (user == null) {
      return {
        'position': 0,
        'total_players': 0,
        'score': 0.0,
        'is_top_10_percent': false,
        'is_top_20_percent': false,
        'is_top_50_percent': false,
      };
    }

    try {
      final supabase = Supabase.instance.client;
      
      // Utiliser une fonction SQL pour calculer les statistiques agrégées
      // Cette fonction sera créée via une migration SQL
      final response = await supabase.rpc('get_user_ranking', params: {
        'p_user_id': user.id,
      });

      if (response == null) {
        // Si la fonction n'existe pas encore, calculer manuellement
        return await _calculateRankingManually(user.id);
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur lors du calcul du classement (fonction SQL): $e');
        print('📊 Tentative de calcul manuel...');
      }
      // Fallback: calcul manuel si la fonction SQL n'existe pas
      return await _calculateRankingManually(user.id);
    }
  }

  /// Calcul manuel du classement (fallback si la fonction SQL n'existe pas)
  Future<Map<String, dynamic>> _calculateRankingManually(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Récupérer toutes les réponses de tous les utilisateurs
      // Note: Cela nécessite que les politiques RLS permettent la lecture agrégée
      // Pour l'instant, on utilise une requête directe qui peut échouer si RLS bloque
      final response = await supabase
          .from('user_question_responses')
          .select('user_id, is_correct');
      
      final List<dynamic> allResponses = response;
      
      // Calculer les statistiques par utilisateur
      final Map<String, Map<String, int>> userStats = {};
      
      for (final response in allResponses) {
        final uid = response['user_id'] as String;
        final isCorrect = response['is_correct'] as bool? ?? false;
        
        if (!userStats.containsKey(uid)) {
          userStats[uid] = {'total': 0, 'correct': 0};
        }
        
        userStats[uid]!['total'] = (userStats[uid]!['total'] ?? 0) + 1;
        if (isCorrect) {
          userStats[uid]!['correct'] = (userStats[uid]!['correct'] ?? 0) + 1;
        }
      }
      
      // Calculer le score moyen pour chaque utilisateur
      final List<MapEntry<String, double>> userScores = [];
      for (final entry in userStats.entries) {
        final total = entry.value['total'] ?? 0;
        final correct = entry.value['correct'] ?? 0;
        final score = total > 0 ? (correct / total * 100) : 0.0;
        userScores.add(MapEntry(entry.key, score));
      }
      
      // Trier par score décroissant
      userScores.sort((a, b) => b.value.compareTo(a.value));
      
      // Trouver la position de l'utilisateur
      int position = 0;
      double userScore = 0.0;
      for (int i = 0; i < userScores.length; i++) {
        if (userScores[i].key == userId) {
          position = i + 1;
          userScore = userScores[i].value;
          break;
        }
      }
      
      final totalPlayers = userScores.length;
      final top10Percent = totalPlayers > 0 && position <= (totalPlayers * 0.1).ceil();
      final top20Percent = totalPlayers > 0 && position <= (totalPlayers * 0.2).ceil();
      final top50Percent = totalPlayers > 0 && position <= (totalPlayers * 0.5).ceil();
      
      return {
        'position': position,
        'total_players': totalPlayers,
        'score': userScore,
        'is_top_10_percent': top10Percent,
        'is_top_20_percent': top20Percent,
        'is_top_50_percent': top50Percent,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors du calcul manuel du classement: $e');
      }
      // Retourner des valeurs par défaut en cas d'erreur
      return {
        'position': 0,
        'total_players': 0,
        'score': 0.0,
        'is_top_10_percent': false,
        'is_top_20_percent': false,
        'is_top_50_percent': false,
      };
    }
  }
}

