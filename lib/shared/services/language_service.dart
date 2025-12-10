
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/language.dart';
import '../models/question.dart';

abstract class ILanguageService {
  Future<Language> getCurrentLanguage();
  Future<void> setLanguage(Language language);
  Future<List<Question>> loadQuestionsForLanguage(Language language);
  Future<List<String>> getAvailableCategories(Language language);
}

class LanguageService implements ILanguageService {
  final SharedPreferences _prefs;
  
  LanguageService(this._prefs);

  @override
  Future<Language> getCurrentLanguage() async {
    final languageCode = _prefs.getString(AppConstants.selectedLanguageKey);
    if (languageCode != null) {
      return Language.fromCode(languageCode);
    }
    return Language.french; // Langue par défaut
  }

  @override
  Future<void> setLanguage(Language language) async {
    await _prefs.setString(AppConstants.selectedLanguageKey, language.code);
  }

  @override
  Future<List<Question>> loadQuestionsForLanguage(Language language) async {
    try {
      // Pour l'instant, on va créer des questions d'exemple
      // Plus tard, on chargera depuis Supabase ou des fichiers locaux
      return _generateSampleQuestions(language);
    } catch (e) {
      throw Exception('Erreur lors du chargement des questions: $e');
    }
  }

  @override
  Future<List<String>> getAvailableCategories(Language language) async {
    try {
      final questions = await loadQuestionsForLanguage(language);
      final categories = questions.map((q) => q.category).toSet().toList();
      return categories;
    } catch (e) {
      throw Exception('Erreur lors du chargement des catégories: $e');
    }
  }

  List<Question> _generateSampleQuestions(Language language) {
    switch (language) {
      case Language.french:
        return [
          Question(
            id: '1',
            questionText: 'Les borders collies sont généralement :',
            responses: ['noir et blanc', 'noir et feu', 'feu et bleu', 'feu'],
            correctResponseIndex: 0,
            category: 'general',
            note: 'Les borders collies sont généralement noir et blanc !',
            difficulty: 1,
          ),
          Question(
            id: '2',
            questionText: 'Quelle est la capitale de la France ?',
            responses: ['Lyon', 'Marseille', 'Paris', 'Toulouse'],
            correctResponseIndex: 2,
            category: 'geographie',
            note: 'Paris est la capitale de la France depuis le Moyen Âge.',
            difficulty: 1,
          ),
          Question(
            id: '3',
            questionText: 'Combien de côtés a un hexagone ?',
            responses: ['4', '5', '6', '8'],
            correctResponseIndex: 2,
            category: 'mathematiques',
            note: 'Un hexagone a exactement 6 côtés.',
            difficulty: 1,
          ),
        ];
      
      case Language.english:
        return [
          Question(
            id: '1',
            questionText: 'Border collies are generally:',
            responses: ['black and white', 'black and tan', 'tan and blue', 'tan'],
            correctResponseIndex: 0,
            category: 'general',
            note: 'Border collies are generally black and white!',
            difficulty: 1,
          ),
          Question(
            id: '2',
            questionText: 'What is the capital of England?',
            responses: ['Manchester', 'Liverpool', 'London', 'Birmingham'],
            correctResponseIndex: 2,
            category: 'geography',
            note: 'London has been the capital of England for centuries.',
            difficulty: 1,
          ),
        ];
      
      case Language.spanish:
        return [
          Question(
            id: '1',
            questionText: 'Los border collies son generalmente:',
            responses: ['negro y blanco', 'negro y fuego', 'fuego y azul', 'fuego'],
            correctResponseIndex: 0,
            category: 'general',
            note: '¡Los border collies son generalmente negro y blanco!',
            difficulty: 1,
          ),
          Question(
            id: '2',
            questionText: '¿Cuál es la capital de España?',
            responses: ['Barcelona', 'Valencia', 'Madrid', 'Sevilla'],
            correctResponseIndex: 2,
            category: 'geografia',
            note: 'Madrid es la capital de España desde 1561.',
            difficulty: 1,
          ),
        ];
    }
  }
}
