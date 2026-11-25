import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_quiz_hub/shared/models/language.dart';
import 'package:app_quiz_hub/shared/services/answer_storage.dart';
import 'package:app_quiz_hub/shared/services/language_service.dart';
import 'package:app_quiz_hub/shared/services/quiz_service.dart';

Future<QuizService> createService() async {
  final prefs = await SharedPreferences.getInstance();
  return QuizService(
    languageService: LanguageService(prefs),
    answerStorage: AnswerStorage(prefs),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('les statistiques sont vides sans réponse', () async {
    final stats = await (await createService()).calculateUserStats();

    expect(stats['total_questions'], 0);
    expect(stats['total_score'], 0);
    expect(stats['average_score'], 0.0);
  });

  test('les réponses sont comptées et la question suivante proposée', () async {
    final service = await createService();
    final first = (await service.getLastUnansweredQuestion(Language.french))!;
    await service.saveAnswer(
      question: first,
      language: Language.french,
      selectedAnswerIndex: first.correctResponseIndex,
    );
    final second = (await service.getLastUnansweredQuestion(Language.french))!;
    await service.saveAnswer(
      question: second,
      language: Language.french,
      selectedAnswerIndex: (second.correctResponseIndex + 1) % 4,
    );

    expect(second.id, isNot(first.id));
    final stats = await service.calculateUserStats();
    expect(stats['unique_questions_answered'], 2);
    expect(stats['total_correct_answers'], 1);
    expect(stats['total_score'], QuizService.pointsPerCorrectAnswer);
    expect(stats['average_score'], 50.0);
  });

  test('une question répondue le reste dans les autres langues', () async {
    final service = await createService();
    final french = (await service.getLastUnansweredQuestion(Language.french))!;
    await service.saveAnswer(
        question: french, language: Language.french, selectedAnswerIndex: 0);

    final english = await service.getLastUnansweredQuestion(Language.english);

    expect(english!.id, isNot(french.id));
  });

  test('répondre à nouveau remplace la réponse', () async {
    final service = await createService();
    final question = (await service.getLastUnansweredQuestion(Language.french))!;
    for (var i = 0; i < 2; i++) {
      await service.saveAnswer(
        question: question,
        language: Language.french,
        selectedAnswerIndex: question.correctResponseIndex,
      );
    }

    final stats = await service.calculateUserStats();

    expect(stats['total_questions'], 1);
  });
}
