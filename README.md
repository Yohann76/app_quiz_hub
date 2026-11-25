# app_quiz_hub (World Quizz Hub)

## Technologies: 

- Dart: https://dart.dev/
- Flutter: https://flutter.dev/
- shared_preferences : stockage local sur le téléphone (aucun serveur, aucun compte)

Project: 

```
$ cd app_quiz_hub
``` 

## Données du joueur

Le pseudo, la langue et les réponses sont enregistrés uniquement sur le téléphone.
Désinstaller l'application ou effacer ses données les supprime.
Aucune configuration n'est nécessaire.

## Build app 

### Build android 

``` 
$ flutter run -d android   (need android studio)
``` 

### Build chrome  

``` 
$ flutter run -d chrome (http://localhost:55424/, http://localhost:61228/)
``` 

### Build Web server on linux 

```
flutter run -d web-server --web-port 3000
```

Web server on linux: http://51.178.80.14:55424/

## Manage flutter 

Choice version:

``` 
$ flutter run 
```

``` 
$ $flutter emulators 
$ flutter doctor
``` 

Install command line tool: (on Android Studio:  Settings → Appearance & Behavior → System Settings → Android SDK, SDK Tools & check Android SDK Command-line Tools (latest) )

``` 
$ flutter doctor --android-licenses
``` 

### Emulate with android: 

$ flutter emulators // Display emulators available (need android studio)
$ flutter emulators --launch Medium_Phone_API_36.0 // Run emulators
$ flutter devices // List device

$ flutter run -d android
$ flutter run -d emulator-5554

