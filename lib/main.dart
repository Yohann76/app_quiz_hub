import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/config/supabase_config.dart';
import 'features/onboarding/language_selection_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/quiz/home_screen.dart';
import 'features/quiz/quiz_screen.dart';
import 'features/profile/profile_screen.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/user_service.dart';
import 'shared/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // config.json (assets) = utilisé sur toutes les plateformes, y compris Android/APK
  // (les .env ne sont pas inclus dans l'APK, donc sans ça écran blanc sur téléphone)
  await SupabaseConfig.loadConfig();
  try {
    await dotenv.load(fileName: ".env.local");
  } catch (_) {
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {}
  }
  
  // Initialiser Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    if (kDebugMode) {
      print('✅ Supabase initialisé avec succès');
    }
  } catch (e) {
    // Gérer l'erreur d'initialisation Supabase
    // L'application peut continuer sans Supabase pour le développement local
    if (kDebugMode) {
      print('❌ Erreur lors de l\'initialisation Supabase: $e');
      print('L\'application continue sans Supabase. Configurez vos clés pour activer Supabase.');
    }
  }
  
  runApp(const QuizHubApp());
}

class QuizHubApp extends StatelessWidget {
  const QuizHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryBlue,
          primary: AppConstants.primaryBlue,
          secondary: AppConstants.primaryOrange,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: AppConstants.backgroundLight,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppConstants.primaryBlue,
          titleTextStyle: TextStyle(
            color: AppConstants.primaryBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.largePadding,
              vertical: AppConstants.defaultPadding,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/language': (context) => const LanguageSelectionScreen(),
        '/quiz': (context) => const QuizScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.longAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _checkFirstLaunch();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstLaunch() async {
    try {
      // Attendre un peu pour l'animation
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;

      final authService = AuthService();
      
      if (kDebugMode) {
        print('🔍 Vérification de l\'authentification...');
        print('Utilisateur connecté: ${authService.isAuthenticated}');
        if (authService.currentUser != null) {
          print('User ID: ${authService.currentUser!.id}');
          print('Email: ${authService.currentUser!.email}');
        }
      }
      
      // Vérifier si l'utilisateur est connecté
      if (!authService.isAuthenticated) {
        // Pas connecté : aller à l'authentification
        if (kDebugMode) {
          print('➡️ Redirection vers /auth (non authentifié)');
        }
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/auth');
        }
        return;
      }

      // Utilisateur connecté : vérifier si le profil est complet
      if (kDebugMode) {
        print('🔍 Vérification du profil utilisateur...');
      }
      
      final prefs = await SharedPreferences.getInstance();
      final userService = UserService(
        authService: authService,
        databaseService: DatabaseService(),
        prefs: prefs,
      );

      final isComplete = await userService.isProfileComplete();
      
      if (kDebugMode) {
        print('Profil complet: $isComplete');
      }
      
      if (mounted) {
        if (isComplete) {
          // Profil complet : aller à l'écran principal
          if (kDebugMode) {
            print('➡️ Redirection vers /home (profil complet)');
          }
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Profil incomplet : aller à l'onboarding
          if (kDebugMode) {
            print('➡️ Redirection vers /onboarding (profil incomplet)');
          }
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Erreur lors de la vérification: $e');
        print('Stack trace: $stackTrace');
      }
      if (mounted) {
        // En cas d'erreur, aller à l'authentification
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstants.primaryBlue,
              AppConstants.lightBlue,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo animé
                      Container(
                        padding: const EdgeInsets.all(AppConstants.largePadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.largePadding),
                      
                      // Nom de l'app
                      Text(
                        AppConstants.appName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.smallPadding),
                      
                      // Sous-titre
                      Text(
                        'DÉFIEZ VOTRE ESPRIT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 2,
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.largePadding * 3),
                      
                      // Indicateur de chargement
                      const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
