# Déploiement Android (APK)

## 1. Configurer les variables

Mettez les bonnes valeurs Supabase dans **les deux** endroits suivants (pour le dev local et pour le build release).

### .env ou .env.local

À la racine du projet, créez ou éditez `.env.local` (ou `.env`) à partir de `.env.example` :

```
SUPABASE_URL=https://votre-projet.supabase.co
SUPABASE_ANON_KEY=votre_cle_anon_publique
```

### config.json (obligatoire pour l’APK)

Sur téléphone, l’app ne voit pas vos fichiers `.env` (ils ne sont pas dans l’APK). Elle lit **uniquement** `assets/config.json`. Sans ce fichier rempli, l’app reste sur un écran blanc après le splash.

Dans `assets/`, créez ou éditez `config.json` à partir de `assets/config.json.example` :

```json
{
  "supabase_url": "https://votre-projet.supabase.co",
  "supabase_anon_key": "votre_cle_anon_publique"
}
```

Les clés se trouvent dans **Supabase Dashboard → Settings → API** (URL du projet + clé anon publique).

---

## 2. Signer en mode release (obligatoire pour le Play Store)

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

## 3. Créer l’APK / AAB Android

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



## Vérifier que la BDD est à jour sur le schéma de prod

Avant de publier l’APK, il faut s’assurer que la base Supabase **de prod** a bien toutes les migrations appliquées (tables, RLS, fonctions).

### Prérequis

- [Supabase CLI](https://supabase.com/docs/guides/cli) installée : `npm install -g supabase` (ou utiliser `npx supabase`).
- Projet lié à votre projet Supabase **prod** (une seule fois).

### Étapes

**1. Lier le projet à la BDD de prod (une fois)**

À la racine du projet :

```bash
npx supabase link --project-ref vhxsjayrkhopqzntarof
```

`vhxsjayrkhopqzntarof` = l’identifiant dans l’URL de votre projet Supabase (ex. pour `https://wtkoltquvmwbyligkdhn.supabase.co` → `wtkoltquvmwbyligkdhn`).  
On vous demandera le mot de passe de la BDD (Settings → Database → Database password dans le dashboard Supabase).

**2. Voir quelles migrations sont appliquées (ou pas)**

```bash
npx supabase migration list
```

- Les migrations **locales** (dans `supabase/migrations/`) sont listées.
- Pour chaque migration, vous voyez si elle est appliquée sur la **remote** (prod) ou non.

**3. Appliquer les migrations manquantes sur prod**

```bash
npx supabase db push
```

Seules les migrations **pas encore appliquées** sur la BDD distante sont exécutées. Après ça, le schéma de prod est aligné avec vos fichiers dans `supabase/migrations/`.

**4. Vérification rapide dans le dashboard**

Supabase Dashboard → **Table Editor** : vérifier que les tables attendues existent (ex. `users`, `user_question_responses`).  
**SQL Editor** : vous pouvez exécuter `SELECT * FROM supabase_migrations.schema_migrations;` pour voir la liste des migrations appliquées.

---

En résumé : **`npx supabase link`** (une fois), puis **`npx supabase migration list`** pour vérifier, et **`npx supabase db push`** pour mettre la BDD de prod à jour.
