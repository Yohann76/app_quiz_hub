import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/question.dart';
import '../../shared/models/language.dart';
import '../../shared/services/language_service.dart';
import '../../shared/services/quiz_service.dart';
import '../../shared/services/database_service.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/user_service.dart';
import '../../shared/services/audio_service.dart';
import '../../shared/services/translation_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Question? _currentQuestion;
  Language? _currentLanguage;
  int? _selectedAnswerIndex;
  bool _showResult = false;
  bool _isLoading = true;
  bool _isSaving = false;
  int _correctAnswers = 0;
  int _totalAnswered = 0;
  int _sessionScore = 0; // Score de la session : 5 points par bonne réponse

  late QuizService _quizService;

  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }

  Future<void> _initializeQuiz() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final userService = UserService(
        authService: authService,
        databaseService: DatabaseService(),
        prefs: prefs,
      );

      // Charger la langue depuis le profil utilisateur
      final profile = await userService.getCurrentProfile();
      final language = profile?.language ?? Language.french;

      // Initialiser les services
      final languageService = LanguageService(prefs);
      _quizService = QuizService(
        languageService: languageService,
        databaseService: DatabaseService(),
        authService: authService,
        prefs: prefs,
      );

      // Charger la dernière question non répondue
      final question = await _quizService.getLastUnansweredQuestion(language);

      if (mounted) {
        setState(() {
          _currentLanguage = language;
          _currentQuestion = question;
          _isLoading = false;
        });
      }

      // Si aucune question disponible, afficher un message
      if (question == null && mounted) {
        _showAllQuestionsCompleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAllQuestionsCompleted() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Félicitations !'),
        content: const Text('Vous avez répondu à toutes les questions disponibles !'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer la dialog
              Navigator.pop(context); // Retourner à l'écran d'accueil
            },
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectAnswer(int index) async {
    if (_showResult || _isSaving || _currentQuestion == null) return;

    setState(() {
      _selectedAnswerIndex = index;
      _showResult = true;
      _isSaving = true;
    });

    final isCorrect = _currentQuestion!.isCorrect(index);
    if (isCorrect) {
      _correctAnswers++;
      _sessionScore += 5; // 5 points par bonne réponse
      AudioService().playSuccess();
    } else {
      AudioService().playError();
    }
    _totalAnswered++;

    // Sauvegarder la réponse
    try {
      await _quizService.saveAnswer(
        question: _currentQuestion!,
        language: _currentLanguage!,
        selectedAnswerIndex: index,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isSaving = false;
    });

    // Attendre 2 secondes avant de passer à la question suivante
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      await _loadNextQuestion();
    }
  }

  Future<void> _loadNextQuestion() async {
    if (_currentLanguage == null) return;

    try {
      final question = await _quizService.getLastUnansweredQuestion(_currentLanguage!);

      if (mounted) {
        setState(() {
          _currentQuestion = question;
          _selectedAnswerIndex = null;
          _showResult = false;
        });
      }

      // Si plus de questions, afficher le message de fin
      if (question == null && mounted) {
        _showAllQuestionsCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentQuestion == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Text('Aucune question disponible'),
        ),
      );
    }

    final t = TranslationService();
    final lang = _currentLanguage ?? Language.french;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${t.translate('score', lang)}: $_sessionScore',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '$_correctAnswers/$_totalAnswered ${t.translate('correct_answers', lang).toLowerCase()}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                lang.flag,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: AppConstants.backgroundLight,
        child: SafeArea(
          child: Column(
            children: [
              // Barre de progression
              LinearProgressIndicator(
                value: _totalAnswered / 20, // Exemple pour 20 questions
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryBlue),
                minHeight: 6,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Question Card
                      Container(
                        padding: const EdgeInsets.all(AppConstants.largePadding),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _currentQuestion!.category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.primaryBlue,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentQuestion!.questionText,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
        
                      const SizedBox(height: AppConstants.largePadding * 1.5),
        
                      // Réponses
                      ...List.generate(
                        _currentQuestion!.responses.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _AnswerButton(
                            text: _currentQuestion!.responses[index],
                            isSelected: _selectedAnswerIndex == index,
                            isCorrect: _currentQuestion!.correctResponseIndex == index,
                            showResult: _showResult,
                            onTap: () => _selectAnswer(index),
                          ),
                        ),
                      ),
        
                      // Note explicative
                      if (_showResult) ...[
                        const SizedBox(height: AppConstants.largePadding),
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            padding: const EdgeInsets.all(AppConstants.largePadding),
                            decoration: BoxDecoration(
                              color: _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                              border: Border.all(
                                color: _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                                          ? Icons.check_circle_rounded
                                          : Icons.error_rounded,
                                      color: _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                                          ? t.translate('excellent', lang)
                                          : t.translate('not_quite', lang),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                                            ? Colors.green
                                            : Colors.red,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _currentQuestion!.note,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[800],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.withOpacity(0.2);
    Color textColor = Colors.black87;
    double elevation = 0;

    if (showResult) {
      if (isCorrect) {
        backgroundColor = Colors.green;
        borderColor = Colors.green;
        textColor = Colors.white;
      } else if (isSelected) {
        backgroundColor = Colors.red;
        borderColor = Colors.red;
        textColor = Colors.white;
      }
    } else if (isSelected) {
      backgroundColor = AppConstants.primaryBlue.withOpacity(0.1);
      borderColor = AppConstants.primaryBlue;
      textColor = AppConstants.primaryBlue;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: showResult ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (showResult && isCorrect)
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                if (showResult && isSelected && !isCorrect)
                  const Icon(Icons.cancel_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
