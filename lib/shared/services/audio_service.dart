import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service pour gérer les effets sonores du quiz
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  /// Jouer le son de réussite
  Future<void> playSuccess() async {
    try {
      await _player.stop(); // Arrêter le son précédent si nécessaire
      await _player.play(AssetSource('audio/correct.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lecture son succès: $e');
      }
    }
  }

  /// Jouer le son d'échec
  Future<void> playError() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/incorrect.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lecture son erreur: $e');
      }
    }
  }

  void dispose() {
    _player.dispose();
  }
}

