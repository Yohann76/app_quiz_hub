class Question {
  final String id;
  final String questionText;
  final List<String> responses;
  final int correctResponseIndex;
  final String category;
  final String note;
  final int difficulty;

  const Question({
    required this.id,
    required this.questionText,
    required this.responses,
    required this.correctResponseIndex,
    required this.category,
    required this.note,
    required this.difficulty,
  });

  factory Question.fromString(String data) {
    // Format: id:"question":"rep1":"rep2":"rep3":"rep4":repX:category:"note":difficulty
    // Parser qui respecte les guillemets (ne split pas à l'intérieur des guillemets)
    final parts = _parseWithQuotes(data);
    
    if (parts.length < 10) {
      throw FormatException('Format de question invalide: $data (${parts.length} parties au lieu de 10)');
    }

    return Question(
      id: parts[0].trim(),
      questionText: _removeQuotes(parts[1]),
      responses: [
        _removeQuotes(parts[2]),
        _removeQuotes(parts[3]),
        _removeQuotes(parts[4]),
        _removeQuotes(parts[5]),
      ],
      correctResponseIndex: _parseCorrectResponse(parts[6]),
      category: _removeQuotes(parts[7]),
      note: _removeQuotes(parts[8]),
      difficulty: int.tryParse(parts[9].trim()) ?? 1,
    );
  }

  /// Parser qui respecte les guillemets (ne split pas à l'intérieur des guillemets)
  static List<String> _parseWithQuotes(String data) {
    final List<String> parts = [];
    final StringBuffer current = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < data.length; i++) {
      final char = data[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
        current.write(char);
      } else if (char == ':' && !inQuotes) {
        // On est en dehors des guillemets, on peut splitter
        parts.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    
    // Ajouter la dernière partie
    if (current.isNotEmpty) {
      parts.add(current.toString());
    }
    
    return parts;
  }

  /// Retirer les guillemets d'une chaîne
  static String _removeQuotes(String str) {
    return str.trim().replaceAll('"', '');
  }

  static int _parseCorrectResponse(String response) {
    if (response.startsWith('rep')) {
      final index = int.tryParse(response.substring(3)) ?? 1;
      return index - 1; // Convertir en index 0-based
    }
    return 0;
  }

  bool isCorrect(int selectedIndex) {
    return selectedIndex == correctResponseIndex;
  }

  String get correctResponse => responses[correctResponseIndex];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'responses': responses,
      'correctResponseIndex': correctResponseIndex,
      'category': category,
      'note': note,
      'difficulty': difficulty,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      questionText: json['questionText'],
      responses: List<String>.from(json['responses']),
      correctResponseIndex: json['correctResponseIndex'],
      category: json['category'],
      note: json['note'],
      difficulty: json['difficulty'],
    );
  }

  @override
  String toString() {
    return 'Question(id: $id, question: $questionText, category: $category, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
