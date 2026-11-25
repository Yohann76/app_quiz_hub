import '../models/language.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  static const Map<String, Map<String, String>> _translations = {
    'fr': {
      'app_name': 'WORLD QUIZZ HUB',
      'start_quiz': 'DÉMARRER',
      'ready_challenge': 'Prêt pour le défi ?',
      'correct_answers': 'Correctes',
      'questions': 'Questions',
      'precision': 'Précision',
      'score': 'Score',
      'my_profile': 'MON PROFIL',
      'statistiques': 'STATISTIQUES',
      'performance': 'PERFORMANCE',
      'details_category': 'DÉTAILS PAR CATÉGORIE',
      'choose_language': 'CHOISIR UNE LANGUE',
      'no_stats': 'Aucune statistique',
      'play_more_graph': 'Jouez plus pour voir le graphique',
      'excellent': 'EXCELLENT !',
      'not_quite': 'PAS TOUT À FAIT...',
      'current_language': 'Langue actuelle',
      'tap_to_continue': 'Appuyez pour continuer',
    },
    'en': {
      'app_name': 'WORLD QUIZZ HUB',
      'start_quiz': 'START',
      'ready_challenge': 'Ready for the challenge?',
      'correct_answers': 'Correct',
      'questions': 'Questions',
      'precision': 'Accuracy',
      'score': 'Score',
      'my_profile': 'MY PROFILE',
      'statistiques': 'STATISTICS',
      'performance': 'PERFORMANCE',
      'details_category': 'CATEGORY DETAILS',
      'choose_language': 'CHOOSE A LANGUAGE',
      'no_stats': 'No statistics yet',
      'play_more_graph': 'Play more to see the chart',
      'excellent': 'EXCELLENT!',
      'not_quite': 'NOT QUITE...',
      'current_language': 'Current language',
      'tap_to_continue': 'Tap to continue',
    },
    'es': {
      'app_name': 'WORLD QUIZZ HUB',
      'start_quiz': 'EMPEZAR',
      'ready_challenge': '¿Listo para el desafío?',
      'correct_answers': 'Correctas',
      'questions': 'Preguntas',
      'precision': 'Precisión',
      'score': 'Puntuación',
      'my_profile': 'MI PERFIL',
      'statistiques': 'ESTADÍSTICAS',
      'performance': 'RENDIMIENTO',
      'details_category': 'DETALLES POR CATEGORÍA',
      'choose_language': 'ELEGIR UN IDIOMA',
      'no_stats': 'Sin estadísticas',
      'play_more_graph': 'Juega más para ver el gráfico',
      'excellent': '¡EXCELENTE!',
      'not_quite': 'NO DEL TODO...',
      'current_language': 'Idioma actual',
      'tap_to_continue': 'Toca para continuar',
    }
  };

  String translate(String key, Language language) {
    return _translations[language.code]?[key] ?? _translations['fr']?[key] ?? key;
  }
}

