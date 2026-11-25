import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/answer_record.dart';

/// Réponses du joueur, enregistrées sur le téléphone (aucun serveur).
class AnswerStorage {
  AnswerStorage(this._prefs);

  final SharedPreferences _prefs;

  /// Toutes les réponses enregistrées, de la plus ancienne à la plus récente.
  List<AnswerRecord> loadAll() {
    final stored = _prefs.getStringList(AppConstants.answersKey) ?? const [];
    return stored
        .map((entry) => AnswerRecord.fromJson(
            jsonDecode(entry) as Map<String, dynamic>))
        .toList();
  }

  /// Enregistre [answer] ; remplace la réponse déjà donnée à la même question
  /// dans la même langue.
  Future<void> save(AnswerRecord answer) async {
    final answers = loadAll()
      ..removeWhere((other) =>
          other.questionId == answer.questionId &&
          other.languageCode == answer.languageCode)
      ..add(answer);

    final isSaved = await _prefs.setStringList(
      AppConstants.answersKey,
      answers.map((a) => jsonEncode(a.toJson())).toList(),
    );
    if (!isSaved) {
      throw Exception('Écriture impossible sur le téléphone');
    }
  }
}
