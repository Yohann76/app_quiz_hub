import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration Supabase
///
/// Pour l'APK sur téléphone : tout vient de assets/config.json (inclus dans l'app).
/// Les fichiers .env ne sont pas embarqués dans l'APK, donc on charge config.json
/// sur toutes les plateformes en priorité.
///
/// Ordre : 1) config.json (assets)  2) .env en secours (dev local)
class SupabaseConfig {
  static Map<String, dynamic>? _assetConfig;
  static bool _assetConfigLoaded = false;

  /// Charge config.json depuis les assets (toutes plateformes, y compris Android).
  static Future<void> loadConfig() async {
    if (_assetConfigLoaded) return;
    _assetConfigLoaded = true;
    try {
      final String jsonString = await rootBundle.loadString('assets/config.json');
      _assetConfig = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Avertissement: Impossible de charger assets/config.json: $e');
      }
      _assetConfig = null;
    }
  }

  static String? _urlFromAssetConfig() {
    if (_assetConfig == null) return null;
    final v = _assetConfig!['supabase_url'] as String?;
    return (v != null && v.isNotEmpty && v != 'YOUR_SUPABASE_URL') ? v : null;
  }

  static String? _anonKeyFromAssetConfig() {
    if (_assetConfig == null) return null;
    final v = _assetConfig!['supabase_anon_key'] as String?;
    return (v != null && v.isNotEmpty && v != 'YOUR_SUPABASE_ANON_KEY') ? v : null;
  }

  static String? _urlFromEnv() {
    final v = dotenv.env['SUPABASE_URL'];
    if (v == null || v.isEmpty || v == 'YOUR_SUPABASE_URL') return null;
    return v;
  }

  static String? _anonKeyFromEnv() {
    final v = dotenv.env['SUPABASE_ANON_KEY'];
    if (v == null || v.isEmpty || v == 'YOUR_SUPABASE_ANON_KEY') return null;
    return v;
  }

  static String get supabaseUrl {
    final v = _urlFromAssetConfig() ?? _urlFromEnv();
    if (v != null) return v;
    throw Exception(
      'SUPABASE_URL non configuré. Remplissez assets/config.json (obligatoire pour l\'APK).'
    );
  }

  static String get supabaseAnonKey {
    final v = _anonKeyFromAssetConfig() ?? _anonKeyFromEnv();
    if (v != null) return v;
    throw Exception(
      'SUPABASE_ANON_KEY non configuré. Remplissez assets/config.json (obligatoire pour l\'APK).'
    );
  }
}
