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

## 2. Créer l’APK/.aab Android

Cela produit un APK par architecture (arm64-v8a, armeabi-v7a, x86_64) dans le même dossier.

À la racine du projet :

```bash
flutter build apk
```

Pour une version final demander pour relase google App bundles

```bash
flutter build appbundle --release # Version 
```



## 3. Vérifier que la BDD est à jour sur le schéma de prod

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
