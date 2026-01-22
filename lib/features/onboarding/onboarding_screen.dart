import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/language.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/user_service.dart';
import '../../shared/services/database_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  Language? _selectedLanguage;
  bool _isLoading = false;
  String? _errorMessage;

  late final UserService _userService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService();
    setState(() {
      _userService = UserService(
        authService: authService,
        databaseService: DatabaseService(),
        prefs: prefs,
      );
    });
    
    // Charger le profil actuel pour pré-remplir
    final profile = await _userService.getCurrentProfile();
    if (profile != null) {
      if (mounted) {
        setState(() {
          // Si le username vient de Google, on peut le pré-remplir mais permettre de le modifier
          if (profile.username != null && profile.username!.isNotEmpty) {
            _usernameController.text = profile.username!;
          }
          _selectedLanguage = profile.language;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLanguage == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner une langue';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Vérifier que l'utilisateur est toujours connecté
      final authService = AuthService();
      if (!authService.isAuthenticated) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }

      // Mettre à jour le username et la langue en une seule opération
      final username = _usernameController.text.trim();
      if (username.isEmpty) {
        throw Exception('Le pseudo est obligatoire');
      }

      // Obtenir le profil actuel ou créer un nouveau
      var profile = await _userService.getCurrentProfile();
      if (profile == null) {
        final user = authService.currentUser;
        if (user == null) {
          throw Exception('Aucun utilisateur connecté. Veuillez vous reconnecter.');
        }
        profile = UserProfile(
          id: user.id,
          email: user.email,
        );
      }

      // Mettre à jour le profil avec username et langue
      final updatedProfile = profile.copyWith(
        username: username,
        language: _selectedLanguage,
        updatedAt: DateTime.now(),
      );

      await _userService.saveProfile(updatedProfile);
      
      // Sauvegarder aussi la langue dans SharedPreferences pour compatibilité
      await _userService.updateLanguage(_selectedLanguage!);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_add,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    const Text(
                      'Complétez votre profil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    const Text(
                      'Choisissez votre pseudo et votre langue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: AppConstants.largePadding * 2),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.largePadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Pseudo *',
                                hintText: 'Entrez votre pseudo',
                                prefixIcon: Icon(Icons.person),
                                helperText: 'Ce pseudo sera visible par les autres joueurs',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer un pseudo';
                                }
                                if (value.trim().length < 3) {
                                  return 'Le pseudo doit contenir au moins 3 caractères';
                                }
                                if (value.trim().length > 20) {
                                  return 'Le pseudo ne doit pas dépasser 20 caractères';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppConstants.largePadding),
                            const Text(
                              'Langue *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppConstants.defaultPadding),
                            ...Language.values.map((language) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
                                  child: RadioListTile<Language>(
                                    title: Text(language.displayName),
                                    value: language,
                                    groupValue: _selectedLanguage,
                                    onChanged: (Language? value) {
                                      setState(() {
                                        _selectedLanguage = value;
                                        _errorMessage = null;
                                      });
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                    ),
                                  ),
                                )),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: AppConstants.defaultPadding),
                              Container(
                                padding: const EdgeInsets.all(AppConstants.smallPadding),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppConstants.defaultPadding),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _completeOnboarding,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Continuer'),
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
        ),
      ),
    );
  }
}

