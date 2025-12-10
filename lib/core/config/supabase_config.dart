import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration Supabase
/// 
/// Les clés sont chargées depuis le fichier .env
/// Pour obtenir vos clés Supabase :
/// 1. Allez sur https://supabase.com/dashboard
/// 2. Sélectionnez votre projet (app_quizz_hub)
/// 3. Allez dans Settings > API
/// 4. Copiez l'URL du projet et la clé anon (publique)
/// 5. Créez un fichier .env à partir de .env.example et remplissez les valeurs
class SupabaseConfig {
  /// URL de votre projet Supabase
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty || url == 'YOUR_SUPABASE_URL') {
      throw Exception(
        'SUPABASE_URL n\'est pas défini dans le fichier .env\n'
        'Copiez .env.example en .env et remplissez les valeurs.'
      );
    }
    return url;
  }

  /// Clé publique (anon) de votre projet Supabase
  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty || key == 'YOUR_SUPABASE_ANON_KEY') {
      throw Exception(
        'SUPABASE_ANON_KEY n\'est pas défini dans le fichier .env\n'
        'Copiez .env.example en .env et remplissez les valeurs.'
      );
    }
    return key;
  }
}

