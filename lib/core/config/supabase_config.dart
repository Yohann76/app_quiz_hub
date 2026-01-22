import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration Supabase
/// 
/// Solution hybride qui fonctionne sur Web et Android :
/// - Web : charge depuis assets/config.json
/// - Android : charge depuis .env.local ou .env
/// 
/// Pour obtenir vos clés Supabase :
/// 1. Allez sur https://supabase.com/dashboard
/// 2. Sélectionnez votre projet (app_quizz_hub)
/// 3. Allez dans Settings > API
/// 4. Copiez l'URL du projet et la clé anon (publique)
/// 
/// Configuration :
/// - Pour Android : Créez un fichier .env.local avec SUPABASE_URL et SUPABASE_ANON_KEY
/// - Pour Web : Créez un fichier assets/config.json à partir de assets/config.json.example
class SupabaseConfig {
  static Map<String, dynamic>? _webConfig;
  static bool _webConfigLoaded = false;

  /// Charger la configuration depuis config.json (pour le web)
  static Future<void> loadWebConfig() async {
    if (kIsWeb && !_webConfigLoaded) {
      try {
        final String jsonString = await rootBundle.loadString('assets/config.json');
        _webConfig = json.decode(jsonString) as Map<String, dynamic>;
        _webConfigLoaded = true;
      } catch (e) {
        if (kDebugMode) {
          print('Avertissement: Impossible de charger assets/config.json: $e');
        }
        _webConfig = null;
        _webConfigLoaded = true;
      }
    }
  }

  /// URL de votre projet Supabase
  static String get supabaseUrl {
    // Sur le web, charger depuis config.json
    if (kIsWeb) {
      if (_webConfig != null) {
        final url = _webConfig!['supabase_url'] as String?;
        if (url != null && url.isNotEmpty && url != 'YOUR_SUPABASE_URL') {
          return url;
        }
      }
      throw Exception(
        'SUPABASE_URL n\'est pas défini dans assets/config.json\n'
        'Créez assets/config.json à partir de assets/config.json.example et remplissez les valeurs.'
      );
    }
    
    // Sur Android/iOS/Desktop, charger depuis .env
    final url = dotenv.env['SUPABASE_URL'];
    if (url != null && url.isNotEmpty && url != 'YOUR_SUPABASE_URL') {
      return url;
    }
    
    throw Exception(
      'SUPABASE_URL n\'est pas défini dans le fichier .env.local ou .env\n'
      'Créez un fichier .env.local avec SUPABASE_URL=votre_url_supabase'
    );
  }

  /// Clé publique (anon) de votre projet Supabase
  static String get supabaseAnonKey {
    // Sur le web, charger depuis config.json
    if (kIsWeb) {
      if (_webConfig != null) {
        final key = _webConfig!['supabase_anon_key'] as String?;
        if (key != null && key.isNotEmpty && key != 'YOUR_SUPABASE_ANON_KEY') {
          return key;
        }
      }
      throw Exception(
        'SUPABASE_ANON_KEY n\'est pas défini dans assets/config.json\n'
        'Créez assets/config.json à partir de assets/config.json.example et remplissez les valeurs.'
      );
    }
    
    // Sur Android/iOS/Desktop, charger depuis .env
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key != null && key.isNotEmpty && key != 'YOUR_SUPABASE_ANON_KEY') {
      return key;
    }
    
    throw Exception(
      'SUPABASE_ANON_KEY n\'est pas défini dans le fichier .env.local ou .env\n'
      'Créez un fichier .env.local avec SUPABASE_ANON_KEY=votre_cle_anon'
    );
  }
}

