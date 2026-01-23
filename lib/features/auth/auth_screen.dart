import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/user_service.dart';
import '../../shared/services/database_service.dart';
import '../../shared/services/language_service.dart';
import '../../shared/services/translation_service.dart';
import '../../shared/models/language.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  Language _currentLanguage = Language.french;
  String? _errorMessage;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _loadLanguage();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = await LanguageService(prefs).getCurrentLanguage();
    if (mounted) {
      setState(() {
        _currentLanguage = lang;
      });
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
          setState(() {
            _currentLanguage = language;
          });
          final prefs = await SharedPreferences.getInstance();
          await LanguageService(prefs).setLanguage(language);
        },
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        // Connexion
        await _authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Inscription
        await _authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (!_authService.isAuthenticated) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Un email de confirmation a été envoyé. Veuillez vérifier votre boîte mail.',
                ),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 5),
              ),
            );
            return;
          }
        }
      }

      if (!_authService.isAuthenticated) {
        throw Exception('Erreur d\'authentification. Veuillez réessayer.');
      }

      final prefs = await SharedPreferences.getInstance();
      final userService = UserService(
        authService: _authService,
        databaseService: DatabaseService(),
        prefs: prefs,
      );
      
      final isComplete = await userService.isProfileComplete();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (isComplete) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
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
    final t = TranslationService();
    final lang = _currentLanguage;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppConstants.primaryBlue, AppConstants.lightBlue],
              ),
            ),
          ),
          
          // Language selector button
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: _showLanguageSelector,
              child: Text(
                lang.flag,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.largePadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppConstants.largePadding),
                    Text(
                      t.translate('app_name', lang),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Auth Card
                    Container(
                      padding: const EdgeInsets.all(AppConstants.largePadding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isLogin ? t.translate('welcome_back', lang) : t.translate('create_account', lang),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryBlue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: t.translate('email', lang),
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
                                if (!value.contains('@')) return 'Email invalide';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: t.translate('password', lang),
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Veuillez entrer votre mot de passe';
                                if (value.length < 6) return 'Au moins 6 caractères';
                                return null;
                              },
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryOrange,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? t.translate('login', lang) : t.translate('signup', lang),
                                      style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _isLoading ? null : () => setState(() {
                                _isLogin = !_isLogin;
                                _errorMessage = null;
                              }),
                              child: Text(
                                _isLogin ? t.translate('no_account', lang) : t.translate('already_account', lang),
                                style: const TextStyle(color: AppConstants.primaryBlue),
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
        ],
      ),
    );
  }
}

class _LanguageSelectorBottomSheet extends StatelessWidget {
  final Language currentLanguage;
  final Function(Language) onLanguageChanged;

  const _LanguageSelectorBottomSheet({
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = TranslationService();
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
              t.translate('choose_language', currentLanguage),
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
            leading: Text(language.flag, style: const TextStyle(fontSize: 24)),
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
