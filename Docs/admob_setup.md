# AdMob (interstitiels)

L’app affiche une **pub plein écran (interstitiel)** toutes les **15 questions** (voir `AppConstants.questionsBetweenAds`).

## Les pubs ne s’affichent pas sur l’APK ?

1. **Nouvelle app / nouvelle unité** : AdMob peut mettre **24 à 48 h** avant de servir des pubs. Vérifiez dans AdMob que l’app et l’unité sont « Actives ».
2. **Pas de remplissage (NO_FILL)** : Si aucun annonceur ne cible votre app, aucune pub n’est affichée. Normal au début.
3. **Vérifier les logs** : branchez le téléphone en USB, lancez `adb logcat | findstr AdMob` (ou cherchez « AdMob »). Vous verrez « interstitiel chargé » ou « échec chargement code=3 » (3 = no fill).

## En développement (actuel)

- **IDs de test** Google sont utilisés (Android + iOS).
- Les pubs de test s’affichent sans compte AdMob.

## Passer en production

1. **Créer un compte et une app** sur [AdMob](https://admob.google.com).
2. **Récupérer l’App ID** (ex. `ca-app-pub-1234567890123456~1234567890`) et l’**unité interstitielle** (ex. `ca-app-pub-1234567890123456/1234567890`).
3. **Remplacer les IDs** :
   - **Android**  
     - `android/app/src/main/AndroidManifest.xml` : `com.google.android.gms.ads.APPLICATION_ID`  
     - `lib/core/constants/app_constants.dart` : `admobInterstitialAndroid`
   - **iOS**  
     - `ios/Runner/Info.plist` : `GADApplicationIdentifier`  
     - `lib/core/constants/app_constants.dart` : `admobInterstitialIOS`
4. **Ne jamais** utiliser vos vrais IDs pendant les tests, sous peine de risque de suspension AdMob.

## Fréquence des pubs

- Modifier **`AppConstants.questionsBetweenAds`** dans `lib/core/constants/app_constants.dart` (ex. 10, 20).
- Plus tard : si l’utilisateur a un abonnement (ex. 3 €/mois), ne pas appeler `AdMobService().showInterstitial()` dans le quiz.
