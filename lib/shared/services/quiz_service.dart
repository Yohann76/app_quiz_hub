import 'package:flutter/foundation.dart';
import '../models/answer_record.dart';
import '../models/question.dart';
import '../models/language.dart';
import 'language_service.dart';
import 'answer_storage.dart';
import '../../core/utils/category_normalizer.dart';

/// Service pour gérer le quiz et la progression
class QuizService {
  final LanguageService _languageService;
  final AnswerStorage _answerStorage;

  QuizService({
    required LanguageService languageService,
    required AnswerStorage answerStorage,
  })  : _languageService = languageService,
        _answerStorage = answerStorage;

  /// Points gagnés par bonne réponse
  static const int pointsPerCorrectAnswer = 5;

  /// Charger toutes les questions pour une langue
  Future<List<Question>> loadQuestions(Language language) async {
    return await _languageService.loadQuestionsForLanguage(language);
  }

  /// Obtenir les IDs des questions déjà répondues par le joueur
  /// Note: On ne filtre pas par langue car les IDs sont identiques dans toutes les langues.
  /// Si une question a été répondue dans une langue, elle est considérée comme répondue dans toutes.
  Set<String> getAnsweredQuestionIds() {
    return _answerStorage.loadAll().map((a) => a.questionId).toSet();
  }

  /// Obtenir la dernière question non répondue
  Future<Question?> getLastUnansweredQuestion(Language language) async {
    final allQuestions = await loadQuestions(language);
    final answeredIds = getAnsweredQuestionIds();
    
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
    await _answerStorage.save(AnswerRecord(
      questionId: question.id,
      languageCode: language.code,
      isCorrect: question.isCorrect(selectedAnswerIndex),
      selectedAnswerIndex: selectedAnswerIndex,
      // Catégorie normalisée vers le français pour cohérence
      category: CategoryNormalizer.normalize(question.category),
      difficulty: question.difficulty,
      answeredAt: DateTime.now(),
    ));
  }

  /// Calculer les statistiques depuis les réponses enregistrées
  Future<Map<String, dynamic>> calculateUserStats({Language? language}) async {
    // Filtrer par langue si spécifiée
    final answers = _answerStorage
        .loadAll()
        .where((a) => language == null || a.languageCode == language.code)
        .toList();

    // Calculer les statistiques
    final totalResponses = answers.length;
    final totalCorrect = answers.where((a) => a.isCorrect).length;

    // Calculer le nombre de questions uniques répondues
    final uniqueQuestionsAnswered =
        answers.map((a) => a.questionId).toSet().length;

    final averageScore = totalResponses > 0 ? (totalCorrect / totalResponses * 100) : 0.0;

    // Calculer le score total : 5 points par bonne réponse
    final totalScore = totalCorrect * pointsPerCorrectAnswer;

    // Calculer par catégorie
    final Map<String, int> totalByCategory = {};
    final Map<String, int> correctByCategory = {};

    for (final answer in answers) {
      final category = CategoryNormalizer.normalize(answer.category);

      totalByCategory[category] = (totalByCategory[category] ?? 0) + 1;
      if (answer.isCorrect) {
        correctByCategory[category] = (correctByCategory[category] ?? 0) + 1;
      }
    }

    if (kDebugMode) {
      print('📊 Stats calculées: $totalResponses réponses, $uniqueQuestionsAnswered questions uniques, $totalCorrect correctes, score total: $totalScore');
    }

    return {
      'total_questions': totalResponses, // Nombre total de réponses enregistrées
      'unique_questions_answered': uniqueQuestionsAnswered, // Nombre de questions uniques
      'total_correct_answers': totalCorrect,
      'average_score': averageScore,
      'total_score': totalScore,
      'total_by_category': totalByCategory,
      'total_correct_by_category': correctByCategory,
    };
  }

  /// Obtenir les statistiques de l'utilisateur (calculées depuis user_question_responses)
  Future<Map<String, dynamic>> getUserStats({Language? language}) async {
    return await calculateUserStats(language: language);
  }
}
