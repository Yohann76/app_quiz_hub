import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/category_normalizer.dart';
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
        // Ne pas filtrer par langue pour avoir toutes les stats
        stats = await quizService.calculateUserStats(language: null);
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
      builder: (bottomSheetContext) => _LanguageSelectorBottomSheet(
        currentLanguage: _currentLanguage,
        onLanguageChanged: (language) async {
          if (bottomSheetContext.mounted) {
            Navigator.pop(bottomSheetContext);
          }
          if (mounted) {
            await _saveLanguage(language);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundLight,
      appBar: AppBar(
        title: const Text('MON PROFIL', style: TextStyle(letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.language_rounded),
            onPressed: _showLanguageSelector,
            tooltip: 'Changer de langue',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Column(
                children: [
                  // En-tête du profil
                  _ProfileHeader(userProfile: _userProfile),
                  
                  const SizedBox(height: AppConstants.largePadding * 1.5),
                  
                  // Statistiques globales
                  _GlobalStatsCard(stats: _userStats),
                  
                  const SizedBox(height: AppConstants.largePadding),
                  
                  // Classement
                  _LeaderboardCard(userProfile: _userProfile),
                  
                  const SizedBox(height: AppConstants.largePadding),
                  
                  // Graphique en forme d'araignée par catégorie
                  _CategoryRadarChartCard(stats: _userStats),
                  
                  const SizedBox(height: AppConstants.largePadding),
                  
                  // Points par catégorie
                  _CategoryStatsCard(stats: _userStats),
                  
                  const SizedBox(height: AppConstants.largePadding * 2),
                  
                  // Bouton de déconnexion
                  const _LogoutButton(),
                  
                  const SizedBox(height: AppConstants.largePadding),
                ],
              ),
            ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserProfile? userProfile;

  const _ProfileHeader({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppConstants.primaryBlue, width: 3),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: AppConstants.primaryBlue.withOpacity(0.1),
            child: const Icon(Icons.person_rounded, size: 60, color: AppConstants.primaryBlue),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          userProfile?.username ?? 'Utilisateur',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
            letterSpacing: 1,
          ),
        ),
        if (userProfile?.email != null)
          Text(
            userProfile!.email!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
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
    final totalScore = stats?['total_score'] as int? ?? 0;

    return Container(
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
          const Text(
            'STATISTIQUES',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppConstants.primaryBlue,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppConstants.largePadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.check_circle_outline_rounded,
                value: totalCorrect.toString(),
                label: 'Correctes',
                color: Colors.green,
              ),
              _StatItem(
                icon: Icons.bolt_rounded,
                value: '${averageScore.toStringAsFixed(0)}%',
                label: 'Précision',
                color: AppConstants.primaryOrange,
              ),
              _StatItem(
                icon: Icons.stars_rounded,
                value: totalScore.toString(),
                label: 'Score',
                color: AppConstants.primaryBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatefulWidget {
  final UserProfile? userProfile;

  const _LeaderboardCard({this.userProfile});

  @override
  State<_LeaderboardCard> createState() => _LeaderboardCardState();
}

class _LeaderboardCardState extends State<_LeaderboardCard> {
  Map<String, dynamic>? _rankingData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  Future<void> _loadRanking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      
      if (!authService.isAuthenticated) return;

      final languageService = LanguageService(prefs);
      final quizService = QuizService(
        languageService: languageService,
        databaseService: DatabaseService(),
        authService: authService,
        prefs: prefs,
      );

      final ranking = await quizService.getUserRanking();
      
      if (mounted) {
        setState(() {
          _rankingData = ranking;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Text(
            'CLASSEMENT',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppConstants.primaryBlue,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppConstants.largePadding),
          if (_isLoading)
            const Center(child: LinearProgressIndicator())
          else if (_rankingData == null || _rankingData!['total_players'] == 0)
            const Center(child: Text('Aucun classement', style: TextStyle(color: Colors.grey)))
          else
            _buildRankingContent(),
        ],
      ),
    );
  }

  Widget _buildRankingContent() {
    final position = _rankingData!['position'] as int? ?? 0;
    final totalPlayers = _rankingData!['total_players'] as int? ?? 0;
    final isTop10 = _rankingData!['is_top_10_percent'] as bool? ?? false;
    final isTop20 = _rankingData!['is_top_20_percent'] as bool? ?? false;
    final isTop50 = _rankingData!['is_top_50_percent'] as bool? ?? false;

    Color badgeColor = Colors.grey;
    String badgeText = 'Joueur';
    if (isTop10) { badgeColor = AppConstants.primaryOrange; badgeText = 'Top 10%'; }
    else if (isTop20) { badgeColor = AppConstants.darkOrange; badgeText = 'Top 20%'; }
    else if (isTop50) { badgeColor = AppConstants.primaryBlue; badgeText = 'Top 50%'; }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$position / $totalPlayers',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
            ),
            Text('Rang actuel', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: badgeColor.withOpacity(0.5)),
          ),
          child: Text(
            badgeText,
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _CategoryRadarChartCard extends StatelessWidget {
  final Map<String, dynamic>? stats;

  const _CategoryRadarChartCard({this.stats});

  @override
  Widget build(BuildContext context) {
    final totalByCategory = stats?['total_by_category'] as Map<String, dynamic>? ?? {};
    final correctByCategory = stats?['total_correct_by_category'] as Map<String, dynamic>? ?? {};
    final categories = totalByCategory.keys.toList();
    
    return Container(
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
          const Text(
            'PERFORMANCE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppConstants.primaryBlue,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppConstants.largePadding),
          if (categories.length < 3)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Jouez plus pour voir le graphique', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            SizedBox(
              height: 250,
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      fillColor: AppConstants.primaryBlue.withOpacity(0.2),
                      borderColor: AppConstants.primaryBlue,
                      entryRadius: 3,
                      dataEntries: categories.map((c) {
                        final total = totalByCategory[c] as int;
                        final correct = correctByCategory[c] as int? ?? 0;
                        return RadarEntry(value: total > 0 ? (correct / total * 100) : 0);
                      }).toList(),
                    ),
                  ],
                  radarBorderData: const BorderSide(color: Colors.transparent),
                  tickBorderData: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  gridBorderData: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  tickCount: 3,
                  ticksTextStyle: const TextStyle(color: Colors.transparent),
                  getTitle: (index, angle) => RadarChartTitle(
                    text: CategoryNormalizer.getDisplayName(categories[index]),
                    angle: angle,
                  ),
                ),
              ),
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
    final categories = totalByCategory.keys.toList();

    return Container(
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
          const Text(
            'DÉTAILS PAR CATÉGORIE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppConstants.primaryBlue,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppConstants.largePadding),
          if (categories.isEmpty)
            const Center(child: Text('Aucune donnée', style: TextStyle(color: Colors.grey)))
          else
            ...categories.map((cat) {
              final total = totalByCategory[cat] as int;
              final correct = correctByCategory[cat] as int? ?? 0;
              final progress = total > 0 ? correct / total : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(CategoryNormalizer.getDisplayName(cat), style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('$correct/$total', style: const TextStyle(color: AppConstants.primaryBlue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[100],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress > 0.7 ? Colors.green : (progress > 0.4 ? AppConstants.primaryOrange : AppConstants.primaryBlue),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _showLogoutDialog(context),
      icon: const Icon(Icons.logout_rounded, color: Colors.red),
      label: const Text(
        'SE DÉCONNECTER',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion'),
        content: const Text('Souhaitez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ANNULER', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DÉCONNEXION'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    try {
      await AuthService().signOut();
      if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _LanguageSelectorBottomSheet extends StatelessWidget {
  final Language? currentLanguage;
  final Function(Language) onLanguageChanged;

  const _LanguageSelectorBottomSheet({required this.currentLanguage, required this.onLanguageChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('CHOISIR UNE LANGUE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppConstants.primaryBlue, letterSpacing: 1)),
          ),
          ...Language.values.map((lang) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            leading: Text(lang.displayName.substring(0, 2).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
            title: Text(lang.displayName, style: TextStyle(fontWeight: lang == currentLanguage ? FontWeight.bold : FontWeight.normal)),
            trailing: lang == currentLanguage ? const Icon(Icons.check_circle_rounded, color: AppConstants.primaryBlue) : null,
            onTap: () => onLanguageChanged(lang),
          )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
