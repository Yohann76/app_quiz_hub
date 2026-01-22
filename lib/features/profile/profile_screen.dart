import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/user_service.dart';
import '../../shared/services/database_service.dart';
import '../../shared/services/quiz_service.dart';
import '../../shared/services/language_service.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/language.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  Language? _currentLanguage;
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final userService = UserService(
        authService: authService,
        databaseService: DatabaseService(),
        prefs: prefs,
      );

      final profile = await userService.getCurrentProfile();
      final language = profile?.language;
      
      // Charger les statistiques calculées depuis user_question_responses
      Map<String, dynamic>? stats;
      if (authService.isAuthenticated) {
        final languageService = LanguageService(prefs);
        final quizService = QuizService(
          languageService: languageService,
          databaseService: DatabaseService(),
          authService: authService,
          prefs: prefs,
        );
        stats = await quizService.calculateUserStats(language: language);
      }
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _currentLanguage = language;
          _userStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Sauvegarder la langue dans Supabase et cache local
  Future<void> _saveLanguage(Language language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      
      if (authService.isAuthenticated) {
        final userService = UserService(
          authService: authService,
          databaseService: DatabaseService(),
          prefs: prefs,
        );
        
        await userService.updateLanguage(language);
        
        // Recharger le profil pour mettre à jour l'affichage
        await _loadUserProfile();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Langue sauvegardée avec succès'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
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

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LanguageSelectorBottomSheet(
        currentLanguage: _currentLanguage,
        onLanguageChanged: (language) async {
          await _saveLanguage(language);
          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageSelector,
            tooltip: 'Changer de langue',
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
              children: [
                // En-tête du profil
                _ProfileHeader(userProfile: _userProfile, isLoading: _isLoading),
                
                const SizedBox(height: AppConstants.largePadding),
                
                // Statistiques globales
                _GlobalStatsCard(stats: _userStats),
                
                const SizedBox(height: AppConstants.defaultPadding),
                
                // Points par catégorie
                _CategoryStatsCard(stats: _userStats),
                
                const SizedBox(height: AppConstants.defaultPadding),
                
                // Historique des dernières questions
                _RecentHistoryCard(),
                
                const SizedBox(height: AppConstants.defaultPadding),
                
                // Classement
                _LeaderboardCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserProfile? userProfile;
  final bool isLoading;

  const _ProfileHeader({
    required this.userProfile,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  // Pseudo
                  Text(
                    userProfile?.username ?? 'Utilisateur',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  // Email
                  if (userProfile?.email != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.email,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            userProfile!.email!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Email non disponible',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalStatsCard extends StatelessWidget {
  final Map<String, dynamic>? stats;

  const _GlobalStatsCard({this.stats});

  @override
  Widget build(BuildContext context) {
    final totalCorrect = stats?['total_correct_answers'] as int? ?? 0;
    final totalQuestions = stats?['total_questions'] as int? ?? 0;
    final averageScore = stats?['average_score'] as double? ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: AppConstants.smallPadding),
              const Text(
                'Statistiques Globales',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.check_circle,
                value: totalCorrect.toString(),
                label: 'Correctes',
                color: Colors.green,
              ),
              _StatItem(
                icon: Icons.quiz,
                value: totalQuestions.toString(),
                label: 'Total',
                color: Colors.blue,
              ),
              _StatItem(
                icon: Icons.trending_up,
                value: '${averageScore.toStringAsFixed(1)}%',
                label: 'Précision',
                color: Colors.orange,
              ),
              _StatItem(
                icon: Icons.star,
                value: totalCorrect.toString(),
                label: 'Score',
                color: Colors.yellow,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryStatsCard extends StatelessWidget {
  final Map<String, dynamic>? stats;

  const _CategoryStatsCard({this.stats});

  @override
  Widget build(BuildContext context) {
    final totalByCategory = stats?['total_by_category'] as Map<String, dynamic>? ?? {};
    final correctByCategory = stats?['total_correct_by_category'] as Map<String, dynamic>? ?? {};

    // Couleurs par catégorie
    final categoryColors = {
      'general': Colors.blue,
      'geographie': Colors.green,
      'geography': Colors.green,
      'geografia': Colors.green,
      'histoire': Colors.orange,
      'history': Colors.orange,
      'historia': Colors.orange,
      'science': Colors.purple,
      'sciences': Colors.purple,
      'ciencia': Colors.purple,
      'mathematiques': Colors.red,
      'mathematics': Colors.red,
      'matematicas': Colors.red,
    };

    final categories = totalByCategory.keys.toList();

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: AppConstants.smallPadding),
              const Text(
                'Points par Catégorie',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          if (categories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: Text(
                  'Aucune statistique par catégorie',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            ...categories.map((category) {
              final total = (totalByCategory[category] as int? ?? 0);
              final correct = (correctByCategory[category] as int? ?? 0);
              final progress = total > 0 ? correct / total : 0.0;
              final color = categoryColors[category.toLowerCase()] ?? Colors.grey;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
                child: _CategoryProgress(
                  category: category,
                  progress: progress,
                  color: color,
                  correct: correct,
                  total: total,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CategoryProgress extends StatelessWidget {
  final String category;
  final double progress;
  final Color color;
  final int correct;
  final int total;

  const _CategoryProgress({
    required this.category,
    required this.progress,
    required this.color,
    this.correct = 0,
    this.total = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '$correct/$total (${(progress * 100).toInt()}%)',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.smallPadding),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}

class _RecentHistoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: AppConstants.smallPadding),
              const Text(
                'Historique Récent',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          const Center(
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 60,
                  color: Colors.white54,
                ),
                SizedBox(height: AppConstants.smallPadding),
                Text(
                  'Aucun quiz terminé',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Commencez votre premier quiz !',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.leaderboard,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: AppConstants.smallPadding),
              const Text(
                'Classement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          const Center(
            child: Column(
              children: [
                Icon(
                  Icons.leaderboard,
                  size: 60,
                  color: Colors.white54,
                ),
                SizedBox(height: AppConstants.smallPadding),
                Text(
                  'Aucun classement disponible',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Jouez pour apparaître dans le classement !',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: AppConstants.smallPadding),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Text(
              'Changer de langue',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ...Language.values.map((language) => ListTile(
            leading: Icon(
              Icons.flag,
              color: language == currentLanguage ? Colors.blue : Colors.grey,
            ),
            title: Text(language.displayName),
            trailing: language == currentLanguage
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
            onTap: () {
              onLanguageChanged(language);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: AppConstants.defaultPadding),
        ],
      ),
    );
  }
}
