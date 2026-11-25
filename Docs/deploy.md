# Déploiement Android (APK)

## 1. Signer en mode release (obligatoire pour le Play Store)

Par défaut, Flutter signe l’APK/AAB avec la **clé de debug**. Google Play (et les autres stores) refusent ce type de fichier : il faut signer avec une **clé de release**.

### Étape 1 : Créer un keystore (une seule fois)

Un keystore est un fichier (ex. `upload-keystore.jks`) qui contient ta clé de signature. **Conserve-le précieusement** : sans lui, tu ne pourras plus mettre à jour l’app sur le Play Store.

À la racine du projet (ou dans un dossier dédié), exécuter :

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Windows : si `keytool` n’est pas reconnu**, il faut utiliser le chemin complet vers `keytool.exe`. Il est fourni avec le JDK. Si tu as **Android Studio**, utilise le JBR fourni (remplace la version si besoin) :

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Si le JDK est ailleurs (ex. `C:\Program Files\Java\jdk-21\bin\keytool.exe`), remplace par ce chemin. Tu peux aussi ajouter le dossier `bin` du JDK à la variable d’environnement **PATH** pour que `keytool` soit reconnu partout.

- On te demandera un **mot de passe** pour le keystore et pour la clé (alias). **Note-les** dans un endroit sûr.
- Réponds aux questions (nom, organisation, etc.). Pour un usage perso, tu peux mettre ce que tu veux.
- Ne commite **jamais** ce fichier `.jks` dans Git (ajoute `*.jks` et `key.properties` dans `.gitignore`).

### Étape 2 : Créer le fichier `key.properties`

À la **racine du projet Android** : `android/key.properties` (créer le fichier s’il n’existe pas).

Contenu (à adapter avec tes vrais chemins et mots de passe) :

```properties
storePassword=TON_MOT_DE_PASSE_KEYSTORE
keyPassword=TON_MOT_DE_PASSE_CLE
keyAlias=upload
storeFile=../upload-keystore.jks
```

- `storeFile` : chemin vers le fichier `.jks` **par rapport au dossier `android/`**. Si le keystore est à la racine du projet, mettre `../upload-keystore.jks`. S’il est dans `android/`, mettre `upload-keystore.jks`. (Gradle lit ce chemin depuis le dossier `android/`.)
- `keyAlias` : le même alias que celui utilisé dans la commande `keytool` (ici `upload`).
- **Ne jamais commiter** `key.properties` dans Git (ajoute `android/key.properties` dans `.gitignore`).

### Étape 3 : Gradle utilise déjà `key.properties`

Le fichier `android/app/build.gradle.kts` est configuré pour lire `android/key.properties` s’il existe. Dès que ce fichier (et le keystore) sont en place, `flutter build apk` et `flutter build appbundle` signent en **release**. Si `key.properties` est absent, le build release utilise encore la clé debug (pour pouvoir tester sans configurer la signature).

### Résumé

| Élément | À faire |
|--------|---------|
| Keystore `.jks` | Créer une fois avec `keytool`, ne jamais le perdre, ne pas le commiter. |
| `key.properties` | Créer dans `android/` avec les mots de passe et le chemin du keystore, ne pas commiter. |
| `build.gradle.kts` | Configurer pour lire `key.properties` et l’utiliser en release. |
| `.gitignore` | Ajouter `*.jks`, `android/key.properties` (et éventuellement le chemin vers le keystore). |

Ensuite, quand tu lances `flutter build appbundle`, le AAB généré sera signé en **release** et accepté par le Play Store.

---

## 2. Créer l’APK / AAB Android

Cela produit un APK par architecture (arm64-v8a, armeabi-v7a, x86_64) dans le même dossier.

À la racine du projet :

```bash
flutter build apk
```

Pour une version finale pour le Play Store (App Bundle) :

```bash
flutter build appbundle --release # Version 
```

**Versionnement (obligatoire à chaque nouvel upload)**
Dans `pubspec.yaml`, la ligne `version: 1.0.0+2` signifie :
- **1.0.0** = version affichée (versionName), tu peux la changer comme tu veux (ex. 1.0.1, 1.1.0).
- **+2** = numéro de build (versionCode) : le Play Store exige qu’il **augmente à chaque upload** (2, 3, 4…). Si tu as déjà publié la 1, mets au moins +2, puis +3 pour la prochaine, etc.
