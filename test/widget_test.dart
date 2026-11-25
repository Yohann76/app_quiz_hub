import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_quiz_hub/main.dart';

/// Laisse passer l'écran de démarrage (2 s) puis la transition.
Future<void> passSplash(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('le premier lancement demande le pseudo, sans connexion',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const QuizHubApp());
    await passSplash(tester);

    expect(find.text('Complétez votre profil'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
  });

  testWidgets('un profil enregistré ouvre directement l\'accueil',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'username': 'Alex', 'selected_language': 'fr'});

    await tester.pumpWidget(const QuizHubApp());
    await passSplash(tester);

    expect(find.text('DÉMARRER'), findsOneWidget);
  });
}
