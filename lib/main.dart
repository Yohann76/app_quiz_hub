import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/config/supabase_config.dart';
import 'features/onboarding/language_selection_screen.dart';
import 'features/quiz/home_screen.dart';
import 'features/quiz/quiz_screen.dart';
import 'features/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Charger la configuration selon la plateforme
  if (kIsWeb) {
    // Sur le web, charger depuis config.json dans les assets
    await SupabaseConfig.loadWebConfig();
  } else {
    // Sur Android/iOS/Desktop, charger depuis .env.local ou .env
    try {
      await dotenv.load(fileName: ".env.local");
    } catch (_) {
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        // Si aucun fichier n'existe, on continue quand même
        // Les erreurs seront gérées par SupabaseConfig si les valeurs sont manquantes
        if (kDebugMode) {
          print('Avertissement: Fichier .env non trouvé. Assurez-vous de créer .env.local avec vos clés Supabase.');
        }
      }
    }
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.smallPadding,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
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
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool(AppConstants.isFirstLaunchKey) ?? true;
      
      // Attendre un peu pour l'animation
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        if (isFirstLaunch) {
          // Première fois : aller à la sélection de langue
          Navigator.of(context).pushReplacementNamed('/language');
        } else {
          // Pas la première fois : aller à l'écran principal
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/language');
      }
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
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(80),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.quiz,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.largePadding),
                      
                      // Nom de l'app
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.smallPadding),
                      
                      // Sous-titre
                      Text(
                        'Votre hub de quiz de culture générale',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.largePadding * 2),
                      
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
