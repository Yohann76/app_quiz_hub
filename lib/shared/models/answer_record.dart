/// Réponse donnée par le joueur à une question.
class AnswerRecord {
  const AnswerRecord({
    required this.questionId,
    required this.languageCode,
    required this.isCorrect,
    required this.selectedAnswerIndex,
    required this.category,
    required this.difficulty,
    required this.answeredAt,
  });

  final String questionId;
  final String languageCode;
  final bool isCorrect;
  final int selectedAnswerIndex;

  /// Catégorie normalisée (voir CategoryNormalizer).
  final String category;
  final int difficulty;
  final DateTime answeredAt;

  factory AnswerRecord.fromJson(Map<String, dynamic> json) {
    return AnswerRecord(
      questionId: json['question_id'] as String,
      languageCode: json['language'] as String,
      isCorrect: json['is_correct'] as bool,
      selectedAnswerIndex: json['selected_answer_index'] as int,
      category: json['category'] as String,
      difficulty: json['difficulty'] as int,
      answeredAt: DateTime.parse(json['answered_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'language': languageCode,
      'is_correct': isCorrect,
      'selected_answer_index': selectedAnswerIndex,
      'category': category,
      'difficulty': difficulty,
      'answered_at': answeredAt.toIso8601String(),
    };
  }
}
