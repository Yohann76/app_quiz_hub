import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/category_normalizer.dart';
import '../../shared/services/user_service.dart';
import '../../shared/services/answer_storage.dart';
import '../../shared/services/quiz_service.dart';
import '../../shared/services/language_service.dart';
import '../../shared/services/translation_service.dart';
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
      final profile = UserService(prefs).getCurrentProfile();
      final quizService = QuizService(
        languageService: LanguageService(prefs),
        answerStorage: AnswerStorage(prefs),
      );
      // Ne pas filtrer par langue pour avoir toutes les stats
      final stats = await quizService.calculateUserStats(language: null);
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _currentLanguage = profile.language;
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

  /// Sauvegarder la langue sur le téléphone
  Future<void> _saveLanguage(Language language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await UserService(prefs).updateLanguage(language);

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
    final t = TranslationService();
    final lang = _currentLanguage ?? Language.french;

    return Scaffold(
      backgroundColor: AppConstants.backgroundLight,
      appBar: AppBar(
        title: Text(t.translate('my_profile', lang), style: const TextStyle(letterSpacing: 2)),
        actions: [
          TextButton(
            onPressed: _showLanguageSelector,
            child: Text(
              lang.flag,
              style: const TextStyle(fontSize: 24),
            ),
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
                  _GlobalStatsCard(stats: _userStats, language: lang),
                  
                  const SizedBox(height: AppConstants.largePadding),
                  
                  // Graphique en forme d'araignée par catégorie
                  _CategoryRadarChartCard(stats: _userStats, language: lang),
                  
                  const SizedBox(height: AppConstants.largePadding),
                  
                  // Points par catégorie
                  _CategoryStatsCard(stats: _userStats, language: lang),
                  
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
      ],
    );
  }
}

class _GlobalStatsCard extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final Language language;

  const _GlobalStatsCard({this.stats, required this.language});

  @override
  Widget build(BuildContext context) {
    final t = TranslationService();
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
          Text(
            t.translate('statistiques', language),
            style: const TextStyle(
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
                label: t.translate('correct_answers', language),
                color: Colors.green,
              ),
              _StatItem(
                icon: Icons.bolt_rounded,
                value: '${averageScore.toStringAsFixed(0)}%',
                label: t.translate('precision', language),
                color: AppConstants.primaryOrange,
              ),
              _StatItem(
                icon: Icons.stars_rounded,
                value: totalScore.toString(),
                label: t.translate('score', language),
                color: AppConstants.primaryBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryRadarChartCard extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final Language language;

  const _CategoryRadarChartCard({this.stats, required this.language});

  @override
  Widget build(BuildContext context) {
    final t = TranslationService();
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
          Text(
            t.translate('performance', language),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppConstants.primaryBlue,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppConstants.largePadding),
          if (categories.length < 3)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(t.translate('play_more_graph', language), style: const TextStyle(color: Colors.grey)),
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
  final Language language;

  const _CategoryStatsCard({this.stats, required this.language});

  @override
  Widget build(BuildContext context) {
    final t = TranslationService();
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
          Text(
            t.translate('details_category', language),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppConstants.primaryBlue,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppConstants.largePadding),
          if (categories.isEmpty)
            Center(child: Text(t.translate('no_stats', language), style: const TextStyle(color: Colors.grey)))
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
