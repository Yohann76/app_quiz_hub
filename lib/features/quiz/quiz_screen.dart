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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Score: $_correctAnswers/$_totalAnswered',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question
                Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentQuestion!.questionText,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Text(
                          'Catégorie: ${_currentQuestion!.category}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.largePadding),

                // Réponses
                ...List.generate(
                  _currentQuestion!.responses.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
                    child: _AnswerButton(
                      text: _currentQuestion!.responses[index],
                      isSelected: _selectedAnswerIndex == index,
                      isCorrect: _currentQuestion!.correctResponseIndex == index,
                      showResult: _showResult,
                      onTap: () => _selectAnswer(index),
                    ),
                  ),
                ),

                // Note explicative (affichée après la réponse)
                if (_showResult) ...[
                  const SizedBox(height: AppConstants.largePadding),
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: AppConstants.smallPadding),
                              Text(
                                _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                                    ? 'Bonne réponse !'
                                    : 'Mauvaise réponse',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.defaultPadding),
                          Text(
                            _currentQuestion!.note,
                            style: const TextStyle(fontSize: 16),
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
    Color? backgroundColor;
    Color? textColor;
    IconData? icon;

    if (showResult) {
      if (isCorrect) {
        backgroundColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.check_circle;
      } else if (isSelected && !isCorrect) {
        backgroundColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.cancel;
      } else {
        backgroundColor = Colors.grey[300];
        textColor = Colors.black87;
      }
    } else {
      backgroundColor = isSelected ? Colors.blue : Colors.white;
      textColor = isSelected ? Colors.white : Colors.black87;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: InkWell(
        onTap: showResult ? null : onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor),
                const SizedBox(width: AppConstants.smallPadding),
              ],
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: textColor,
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
