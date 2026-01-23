import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/language.dart';
import '../../shared/services/language_service.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/user_service.dart';
import '../../shared/services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Language? _currentLanguage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  /// Charger la langue depuis Supabase (priorité) ou depuis le cache local
  Future<void> _loadCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      
      // Si l'utilisateur est connecté, charger depuis Supabase
      if (authService.isAuthenticated) {
        try {
          final userService = UserService(
            authService: authService,
            databaseService: DatabaseService(),
            prefs: prefs,
          );
          
          final profile = await userService.getCurrentProfile();
          if (profile?.language != null) {
            if (mounted) {
              setState(() {
                _currentLanguage = profile!.language;
                _isLoading = false;
              });
            }
            return;
          }
        } catch (e) {
          // Si erreur Supabase, fallback sur cache local
          print('Erreur lors du chargement depuis Supabase: $e');
        }
      }
      
      // Fallback : charger depuis le cache local (SharedPreferences)
      final languageService = LanguageService(prefs);
      final language = await languageService.getCurrentLanguage();
      
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

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageSelector,
            tooltip: 'Changer de langue',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: 'Profil',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFf093fb),
              Color(0xFFf5576c),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                           MediaQuery.of(context).padding.top - 
                           kToolbarHeight - 
                           MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // En-tête avec la langue actuelle
                    Container(
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
                          Icon(
                            Icons.language,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: AppConstants.smallPadding),
                          Text(
                            'Langue actuelle: ${_currentLanguage?.displayName ?? "Non définie"}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.largePadding),
                    
                    // Option principale - Démarrer un Quiz
                    Expanded(
                      child: Center(
                        child: _StartQuizOption(
                          onTap: () => Navigator.pushNamed(context, '/quiz'),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.largePadding),
                    
                    // Statistiques rapides
                    Container(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Icons.check_circle,
                            value: '0',
                            label: 'Correctes',
                            color: Colors.green,
                          ),
                          _StatItem(
                            icon: Icons.quiz,
                            value: '0',
                            label: 'Total',
                            color: Colors.blue,
                          ),
                          _StatItem(
                            icon: Icons.trending_up,
                            value: '0%',
                            label: 'Précision',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
          
          // Sauvegarder dans Supabase et cache local
          await _saveLanguage(language);
        },
      ),
    );
  }

  /// Sauvegarder la langue dans Supabase (si connecté) et dans le cache local
  Future<void> _saveLanguage(Language language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      
      // Si l'utilisateur est connecté, sauvegarder dans Supabase
      if (authService.isAuthenticated) {
        try {
          final userService = UserService(
            authService: authService,
            databaseService: DatabaseService(),
            prefs: prefs,
          );
          
          await userService.updateLanguage(language);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Langue sauvegardée avec succès'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        } catch (e) {
          // Si erreur Supabase, sauvegarder quand même dans le cache local
          print('Erreur lors de la sauvegarde dans Supabase: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Langue sauvegardée localement (erreur Supabase: $e)'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
      
      // Sauvegarder dans le cache local (SharedPreferences)
      final languageService = LanguageService(prefs);
      await languageService.setLanguage(language);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Langue sauvegardée localement'),
            backgroundColor: Colors.blue,
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

class _StartQuizOption extends StatelessWidget {
  final VoidCallback onTap;

  const _StartQuizOption({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
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
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_filled_rounded,
                  size: 72,
                  color: Colors.white,
                ),
                SizedBox(width: 20),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DÉMARRER',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Prêt pour le défi ?',
                      style: TextStyle(
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
