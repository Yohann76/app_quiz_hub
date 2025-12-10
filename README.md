# app_quiz_hub

## Technologies: 

- Dart: https://dart.dev/
- Flutter: https://flutter.dev/
- Supabase : https://supabase.com/

Project: 

```
$ cd app_quiz_hub
``` 

## Build app 

###  build android 

``` 
$ flutter run -d android   (need android studio)
``` 

### build chrome  

``` 
$ flutter run -d chrome (http://localhost:55424/, http://localhost:61228/)
``` 

### build Web server on linux 

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

