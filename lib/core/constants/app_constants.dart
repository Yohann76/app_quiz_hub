import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'Quiz Hub';
  static const String appVersion = '1.0.0';
  
  // Supabase Tables
  static const String usersTable = 'users';
  static const String userQuestionResponsesTable = 'user_question_responses'; // Table principale pour les stats
  
  // Note: user_stats et quiz_history ont été supprimées car les stats sont calculées
  // dynamiquement depuis user_question_responses via QuizService.calculateUserStats()
  
  // Shared Preferences Keys
  static const String selectedLanguageKey = 'selected_language';
  static const String userIdKey = 'user_id';
  static const String isFirstLaunchKey = 'is_first_launch';
  
  // Quiz Settings
  static const int questionsPerQuiz = 10;
  static const int maxDifficulty = 5;
  static const Duration questionTimeLimit = Duration(seconds: 30);
  
  // UI Colors
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF7BAAF7);
  static const Color primaryOrange = Color(0xFFF5A623);
  static const Color darkOrange = Color(0xFFD67E17);
  static const Color backgroundLight = Color(0xFFF8FAFC);

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 24.0; // Plus arrondi pour un look moderne
  static const double cardElevation = 0.0; // Shadows manuelles pour plus de contrôle
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);
  
  // Error Messages
  static const String networkErrorMessage = 'Erreur de connexion. Vérifiez votre connexion internet.';
  static const String generalErrorMessage = 'Une erreur s\'est produite. Veuillez réessayer.';
  static const String invalidQuestionFormatMessage = 'Format de question invalide.';
  
  // Success Messages
  static const String languageChangedMessage = 'Langue changée avec succès !';
  static const String quizCompletedMessage = 'Quiz terminé ! Félicitations !';
  
  // Default Values
  static const String defaultCategory = 'general';
  static const int defaultDifficulty = 1;
}
