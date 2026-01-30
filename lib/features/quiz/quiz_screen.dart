import 'dart:async';
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
  Timer? _autoSkipTimer;

  late QuizService _quizService;

  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }

  @override
  void dispose() {
    _autoSkipTimer?.cancel();
    super.dispose();
  }

  void _skipResult() {
    if (!_showResult || _isSaving) return;
    _autoSkipTimer?.cancel();
    _loadNextQuestion();
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

    // Auto-skip après 10 secondes si l'utilisateur ne fait rien
    _autoSkipTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) _skipResult();
    });
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
      body: GestureDetector(
        onTap: _showResult ? _skipResult : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: AppConstants.backgroundLight,
          child: SafeArea(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _totalAnswered / 20,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryBlue),
                  minHeight: 4,
                ),
                // Question + réponses (scroll si trop long)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _currentQuestion!.category.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.primaryBlue,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _currentQuestion!.questionText,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(
                          _currentQuestion!.responses.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AnswerButton(
                              text: _currentQuestion!.responses[index],
                              isSelected: _selectedAnswerIndex == index,
                              isCorrect: _currentQuestion!.correctResponseIndex == index,
                              showResult: _showResult,
                              onTap: () => _selectAnswer(index),
                            ),
                          ),
                        ),
                        // Espace pour que le bloc résultat en bas ne soit pas masqué
                        if (_showResult) const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                // Résultat toujours visible en bas (pas besoin de scroller)
                if (_showResult)
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                                    ? Icons.check_circle_rounded
                                    : Icons.error_rounded,
                                size: 20,
                                color: _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                                    ? t.translate('excellent', lang)
                                    : t.translate('not_quite', lang),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: _currentQuestion!.isCorrect(_selectedAnswerIndex!)
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currentQuestion!.note,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              t.translate('tap_to_continue', lang),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: showResult ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
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
