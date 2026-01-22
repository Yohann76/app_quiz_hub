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
    final parts = data.split(':');
    // Format: id:"question":"rep1":"rep2":"rep3":"rep4":repX:category:"note":difficulty
    // Soit 10 parties au total
    if (parts.length < 10) {
      throw FormatException('Format de question invalide: $data (${parts.length} parties au lieu de 10)');
    }

    return Question(
      id: parts[0].trim(),
      questionText: parts[1].trim().replaceAll('"', ''),
      responses: [
        parts[2].trim().replaceAll('"', ''),
        parts[3].trim().replaceAll('"', ''),
        parts[4].trim().replaceAll('"', ''),
        parts[5].trim().replaceAll('"', ''),
      ],
      correctResponseIndex: _parseCorrectResponse(parts[6]),
      category: parts[7].trim().replaceAll('"', ''),
      note: parts[8].trim().replaceAll('"', ''),
      difficulty: int.tryParse(parts[9].trim()) ?? 1,
    );
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
