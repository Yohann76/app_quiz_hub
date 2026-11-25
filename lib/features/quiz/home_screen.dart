import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/language.dart';
import '../../shared/services/language_service.dart';
import '../../shared/services/answer_storage.dart';
import '../../shared/services/quiz_service.dart';
import '../../shared/services/translation_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Language? _currentLanguage;
  Map<String, dynamic>? _userStats;
  int _totalQuestionsInAssets = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (mounted && !silent) {
      setState(() => _isLoading = true);
    }
    await _loadCurrentLanguage();
    await _loadStats();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageService = LanguageService(prefs);
      final quizService = QuizService(
        languageService: languageService,
        answerStorage: AnswerStorage(prefs),
      );

      // Charger les stats globales
      final stats = await quizService.calculateUserStats();

      // Charger le nombre total de questions disponibles dans les fichiers
      if (_currentLanguage != null) {
        final questions = await languageService.loadQuestionsForLanguage(_currentLanguage!);
        if (mounted) {
          setState(() {
            _userStats = stats;
            _totalQuestionsInAssets = questions.length;
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des stats: $e');
    }
  }

  /// Charger la langue enregistrée sur le téléphone
  Future<void> _loadCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final language = await LanguageService(prefs).getCurrentLanguage();
      
      if (mounted) {
        setState(() {
          _currentLanguage = language;
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final t = TranslationService();
    final lang = _currentLanguage ?? Language.french;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('app_name', lang), style: const TextStyle(letterSpacing: 2)),
        actions: [
          TextButton(
            onPressed: _showLanguageSelector,
            child: Text(
              lang.flag,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.pushNamed(context, '/profile').then((_) => _loadData(silent: true)),
          ),
        ],
      ),
      body: Container(
        color: AppConstants.backgroundLight,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                const SizedBox(height: AppConstants.largePadding),
                
                // Option principale - Démarrer un Quiz
                _StartQuizOption(
                  onTap: () => Navigator.pushNamed(context, '/quiz').then((_) => _loadData(silent: true)),
                  language: lang,
                ),
                
                const SizedBox(height: AppConstants.largePadding * 2),
                
                // Statistiques rapides
                _QuickStatsRow(
                  stats: _userStats,
                  totalAvailable: _totalQuestionsInAssets,
                  language: lang,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LanguageSelectorBottomSheet(
        currentLanguage: _currentLanguage,
        onLanguageChanged: (language) async {
          // Mettre à jour l'état local immédiatement
          setState(() {
            _currentLanguage = language;
          });
          
          // Sauvegarder sur le téléphone
          await _saveLanguage(language);
          // Recharger les stats pour la nouvelle langue (total questions)
          await _loadStats();
        },
      ),
    );
  }

  /// Sauvegarder la langue sur le téléphone
  Future<void> _saveLanguage(Language language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await LanguageService(prefs).setLanguage(language);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Langue sauvegardée avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class _QuickStatsRow extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final int totalAvailable;
  final Language language;

  const _QuickStatsRow({
    this.stats,
    required this.totalAvailable,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final t = TranslationService();
    final totalCorrect = stats?['total_correct_answers'] as int? ?? 0;
    final uniqueAnswered = stats?['unique_questions_answered'] as int? ?? 0;
    final accuracy = stats?['average_score'] as double? ?? 0.0;
    final totalScore = stats?['total_score'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: AppConstants.largePadding),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.check_circle_outline_rounded,
            value: totalCorrect.toString(),
            label: t.translate('correct_answers', language),
            color: Colors.green,
          ),
          _StatItem(
            icon: Icons.quiz_outlined,
            value: '$uniqueAnswered/$totalAvailable',
            label: t.translate('questions', language),
            color: AppConstants.primaryBlue,
          ),
          _StatItem(
            icon: Icons.bolt_rounded,
            value: '${accuracy.toStringAsFixed(0)}%',
            label: t.translate('precision', language),
            color: AppConstants.primaryOrange,
          ),
          _StatItem(
            icon: Icons.stars_rounded,
            value: totalScore.toString(),
            label: t.translate('score', language),
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

class _StartQuizOption extends StatelessWidget {
  final VoidCallback onTap;
  final Language language;

  const _StartQuizOption({
    required this.onTap,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final t = TranslationService();
    return Container(
      width: double.infinity,
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppConstants.primaryBlue,
                  AppConstants.lightBlue,
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryBlue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_filled_rounded,
                  size: 72,
                  color: Colors.white,
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.translate('start_quiz', language),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      t.translate('ready_challenge', language),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LanguageSelectorBottomSheet extends StatelessWidget {
  final Language? currentLanguage;
  final Function(Language) onLanguageChanged;

  const _LanguageSelectorBottomSheet({
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = TranslationService();
    final lang = currentLanguage ?? Language.french;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              t.translate('choose_language', lang),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppConstants.primaryBlue,
                letterSpacing: 1,
              ),
            ),
          ),
          ...Language.values.map((language) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            leading: Text(
              language.flag,
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(
              language.displayName,
              style: TextStyle(
                fontWeight: language == currentLanguage ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: language == currentLanguage
                ? const Icon(Icons.check_circle_rounded, color: AppConstants.primaryBlue)
                : null,
            onTap: () {
              onLanguageChanged(language);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
