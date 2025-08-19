# Configuration Firebase pour Quiz Hub

## 🔥 Étapes de configuration

### 1. Créer un projet Firebase

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquer sur "Créer un projet"
3. Donner un nom au projet (ex: "quiz-hub-app")
4. Suivre les étapes de configuration

### 2. Ajouter l'application Android

1. Dans la console Firebase, cliquer sur l'icône Android
2. Entrer le package name : `com.example.app_quiz_hub`
3. Télécharger le fichier `google-services.json`
4. Placer le fichier dans `android/app/`

### 3. Ajouter l'application iOS

1. Dans la console Firebase, cliquer sur l'icône iOS
2. Entrer le bundle ID : `com.example.appQuizHub`
3. Télécharger le fichier `GoogleService-Info.plist`
4. Placer le fichier dans `ios/Runner/`

### 4. Configuration des règles Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Utilisateurs peuvent lire/écrire leurs propres données
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Statistiques utilisateur
    match /user_stats/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Historique des quiz
    match /quiz_history/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 5. Configuration des règles d'authentification

- Activer l'authentification par email/mot de passe
- Activer l'authentification anonyme (optionnel)
- Configurer les paramètres de sécurité

### 6. Variables d'environnement

Créer un fichier `.env` à la racine du projet :

```env
FIREBASE_API_KEY=your_api_key_here
FIREBASE_PROJECT_ID=your_project_id_here
FIREBASE_MESSAGING_SENDER_ID=your_sender_id_here
FIREBASE_APP_ID=your_app_id_here
```

## 📱 Intégration dans le code

### Initialisation Firebase

```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const QuizHubApp());
}
```

### Configuration des services

```dart
// Service d'authentification
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Méthodes d'authentification...
}

// Service de base de données
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Méthodes de base de données...
}
```

## 🚀 Déploiement

### Android

1. Configurer la signature de l'APK
2. Tester sur un appareil physique
3. Publier sur Google Play Store

### iOS

1. Configurer les certificats de développement
2. Tester sur un appareil physique
3. Publier sur App Store

## 📊 Monitoring et Analytics

- Activer Firebase Analytics
- Configurer Crashlytics
- Surveiller les performances

## 🔒 Sécurité

- Vérifier les règles Firestore
- Configurer l'authentification
- Limiter les accès aux données sensibles
- Implémenter la validation côté serveur

## 📚 Ressources

- [Documentation Firebase](https://firebase.google.com/docs)
- [FlutterFire](https://firebase.flutter.dev/)
- [Exemples d'intégration](https://github.com/FirebaseExtended/flutterfire)
