import 'dart:io';

/// Script de validation des fichiers de contenu du quiz (Format & Cohérence)
/// Utilisation: dart scripts/validate_content.dart
void main() {
  final contentDir = Directory('assets/content');
  if (!contentDir.existsSync()) {
    print('❌ Erreur: Dossier assets/content introuvable.');
    exit(1);
  }

  final files = contentDir.listSync().where((f) => f.path.endsWith('.txt')).toList();
  if (files.isEmpty) {
    print('⚠️ Aucun fichier .txt trouvé dans assets/content.');
    return;
  }

  print('🔍 Démarrage de la validation (Format & Cohérence)...\n');

  bool allValid = true;
  final Map<String, Set<String>> idsByFile = {};
  
  // Liste exhaustive des catégories acceptées dans les 3 langues
  final validCategories = {
    // Français
    'histoire', 'geographie', 'cinema', 'cinéma', 'musique', 'sports', 'sport', 'sciences', 'science', 'divers',
    // Anglais
    'history', 'geography', 'film', 'movies', 'music', 'misc', 'miscellaneous', 'other',
    // Espagnol
    'historia', 'geografia', 'cine', 'peliculas', 'musica', 'deportes', 'deporte', 'ciencias', 'ciencia', 'otros', 'otro', 'diverso',
    // Autres/Anciens
    'general', 'art', 'arte', 'mathematiques', 'mathematics', 'matematicas'
  };

  for (final file in files) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    print('📄 Analyse de $fileName...');
    
    final lines = File(file.path).readAsLinesSync();
    final ids = <String>{};
    idsByFile[fileName] = ids;
    
    int errorCount = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final lineNumber = i + 1;
      final parts = _parseWithQuotes(line);

      // 1. Structure
      if (parts.length != 10) {
        print('  ❌ Ligne $lineNumber: Structure invalide (${parts.length}/10 parties). Vérifiez les ":"');
        errorCount++;
        continue;
      }

      final id = parts[0].trim();
      final question = parts[1];
      final repCorrect = parts[6].trim();
      final category = parts[7].trim().toLowerCase();
      final difficulty = parts[9].trim();

      // 2. IDs
      if (ids.contains(id)) {
        print('  ❌ Ligne $lineNumber: ID en doublon ($id)');
        errorCount++;
      }
      ids.add(id);

      // 3. Format des textes (Guillemets)
      if (!_isQuoted(question)) print('  ⚠️ Ligne $lineNumber: Question non entourée de guillemets (")');
      if (!_isQuoted(parts[2])) print('  ⚠️ Ligne $lineNumber: Réponse 1 non entourée de guillemets (")');
      if (!_isQuoted(parts[8])) print('  ⚠️ Ligne $lineNumber: Note non entourée de guillemets (")');

      // 4. Index de réponse
      if (!RegExp(r'^rep[1-4]$').hasMatch(repCorrect)) {
        print('  ❌ Ligne $lineNumber: Index réponse invalide ($repCorrect), attendu: rep1, rep2, rep3 ou rep4');
        errorCount++;
      }

      // 5. Catégorie
      if (!validCategories.contains(category)) {
        print('  ❌ Ligne $lineNumber: Catégorie non reconnue ($category)');
        errorCount++;
      }

      // 6. Difficulté
      if (!RegExp(r'^[1-3]$').hasMatch(difficulty)) {
        print('  ❌ Ligne $lineNumber: Difficulté invalide ($difficulty), attendu: 1, 2 ou 3');
        errorCount++;
      }
    }

    if (errorCount == 0) {
      print('  ✅ $fileName : Format valide (${lines.length} lignes)\n');
    } else {
      print('  ❌ $fileName : $errorCount erreur(s) de format\n');
      allValid = false;
    }
  }

  // Vérification de la cohérence entre les fichiers
  print('📊 Vérification de la cohérence entre les fichiers de langue...');
  final fileList = idsByFile.keys.toList();
  for (int i = 0; i < fileList.length; i++) {
    for (int j = i + 1; j < fileList.length; j++) {
      final f1 = fileList[i];
      final f2 = fileList[j];
      final ids1 = idsByFile[f1]!;
      final ids2 = idsByFile[f2]!;

      final diff1 = ids1.difference(ids2);
      final diff2 = ids2.difference(ids1);

      if (diff1.isNotEmpty || diff2.isNotEmpty) {
        print('  ⚠️ Incohérence entre $f1 et $f2 :');
        if (diff1.isNotEmpty) print('    - IDs présents dans $f1 mais pas dans $f2: ${diff1.join(', ')}');
        if (diff2.isNotEmpty) print('    - IDs présents dans $f2 mais pas dans $f1: ${diff2.join(', ')}');
        allValid = false;
      }
    }
  }

  if (allValid) {
    print('\n🎉 Succès : Tous les fichiers sont correctement formatés et cohérents entre eux !');
    exit(0);
  } else {
    print('\n🛠️ Des erreurs ont été détectées. Veuillez vérifier votre contenu.');
    exit(1);
  }
}

List<String> _parseWithQuotes(String data) {
  final List<String> parts = [];
  final StringBuffer current = StringBuffer();
  bool inQuotes = false;
  for (int i = 0; i < data.length; i++) {
    if (data[i] == '"') inQuotes = !inQuotes;
    if (data[i] == ':' && !inQuotes) {
      parts.add(current.toString());
      current.clear();
    } else {
      current.write(data[i]);
    }
  }
  if (current.isNotEmpty) parts.add(current.toString());
  return parts;
}

bool _isQuoted(String str) {
  final s = str.trim();
  return s.startsWith('"') && s.endsWith('"');
}
