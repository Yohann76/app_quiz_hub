class UserStats {
  final String userId;
  final Map<String, CategoryStats> categoryStats;
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final DateTime lastQuizDate;

  const UserStats({
    required this.userId,
    required this.categoryStats,
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.lastQuizDate,
  });

  double get overallAccuracy {
    if (totalQuestionsAnswered == 0) return 0.0;
    return (totalCorrectAnswers / totalQuestionsAnswered) * 100;
  }

  int get totalQuestionsInCategory {
    return categoryStats.values.fold(0, (sum, stats) => sum + stats.questionsAnswered);
  }

  UserStats copyWith({
    String? userId,
    Map<String, CategoryStats>? categoryStats,
    int? totalQuestionsAnswered,
    int? totalCorrectAnswers,
    DateTime? lastQuizDate,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      categoryStats: categoryStats ?? this.categoryStats,
      totalQuestionsAnswered: totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
      lastQuizDate: lastQuizDate ?? this.lastQuizDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'categoryStats': categoryStats.map((key, value) => MapEntry(key, value.toJson())),
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'totalCorrectAnswers': totalCorrectAnswers,
      'lastQuizDate': lastQuizDate.toIso8601String(),
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['userId'],
      categoryStats: (json['categoryStats'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, CategoryStats.fromJson(value)),
      ),
      totalQuestionsAnswered: json['totalQuestionsAnswered'] ?? 0,
      totalCorrectAnswers: json['totalCorrectAnswers'] ?? 0,
      lastQuizDate: DateTime.parse(json['lastQuizDate'] ?? DateTime.now().toIso8601String()),
    );
  }

  factory UserStats.initial(String userId) {
    return UserStats(
      userId: userId,
      categoryStats: {},
      totalQuestionsAnswered: 0,
      totalCorrectAnswers: 0,
      lastQuizDate: DateTime.now(),
    );
  }
}

class CategoryStats {
  final String category;
  final int questionsAnswered;
  final int correctAnswers;
  final DateTime lastAnswered;

  const CategoryStats({
    required this.category,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.lastAnswered,
  });

  double get accuracy {
    if (questionsAnswered == 0) return 0.0;
    return (correctAnswers / questionsAnswered) * 100;
  }

  CategoryStats copyWith({
    String? category,
    int? questionsAnswered,
    int? correctAnswers,
    DateTime? lastAnswered,
  }) {
    return CategoryStats(
      category: category ?? this.category,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      lastAnswered: lastAnswered ?? this.lastAnswered,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'questionsAnswered': questionsAnswered,
      'correctAnswers': correctAnswers,
      'lastAnswered': lastAnswered.toIso8601String(),
    };
  }

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      category: json['category'],
      questionsAnswered: json['questionsAnswered'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      lastAnswered: DateTime.parse(json['lastAnswered'] ?? DateTime.now().toIso8601String()),
    );
  }

  factory CategoryStats.initial(String category) {
    return CategoryStats(
      category: category,
      questionsAnswered: 0,
      correctAnswers: 0,
      lastAnswered: DateTime.now(),
    );
  }
}
