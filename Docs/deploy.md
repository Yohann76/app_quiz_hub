# Déploiement Android (APK)

## 1. Configurer les variables

Mettez les bonnes valeurs Supabase dans **les deux** endroits suivants (pour le dev local et pour le build release).

### .env ou .env.local

À la racine du projet, créez ou éditez `.env.local` (ou `.env`) à partir de `.env.example` :

```
SUPABASE_URL=https://votre-projet.supabase.co
SUPABASE_ANON_KEY=votre_cle_anon_publique
```

### config.json

Dans `assets/`, créez ou éditez `config.json` à partir de `assets/config.json.example` :

```json
{
  "supabase_url": "https://votre-projet.supabase.co",
  "supabase_anon_key": "votre_cle_anon_publique"
}
```

Les clés se trouvent dans **Supabase Dashboard → Settings → API** (URL du projet + clé anon publique).

---

## 2. Créer l’APK Android

À la racine du projet :

```bash
flutter build apk
```

L’APK est généré dans :  
`build/app/outputs/flutter-apk/app-release.apk`

Pour une version optimisée (plus petit) :

```bash
flutter build apk --split-per-abi
```

Cela produit un APK par architecture (arm64-v8a, armeabi-v7a, x86_64) dans le même dossier.
