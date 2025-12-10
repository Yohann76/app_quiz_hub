# Configuration Supabase pour Quiz Hub

## 📋 Prérequis

- Un compte Supabase (https://supabase.com/)
- Un projet créé dans Supabase
- Les clés API de votre projet

## 🔧 Configuration

### 1. Obtenir les clés Supabase

1. Connectez-vous à [Supabase Dashboard](https://supabase.com/dashboard)
2. Sélectionnez votre projet : **app_quizz_hub**
3. Allez dans **Settings** > **API**
4. Copiez :
   - **Project URL** (ex: `https://xxxxx.supabase.co`)
   - **anon public** key

### 2. Configurer les clés dans l'application

1. Copiez le fichier `.env.example` en `.env` :
   ```bash
   cp .env.example .env
   ```

2. Ouvrez le fichier `.env` et remplacez les valeurs :
   ```env
   SUPABASE_URL=https://xxxxx.supabase.co
   SUPABASE_ANON_KEY=votre_cle_anon_ici
   ```

3. Le fichier `.env` est automatiquement ignoré par Git (déjà dans `.gitignore`)

⚠️ **Important** : Ne commitez jamais le fichier `.env` ! Seul `.env.example` doit être versionné.

### 3. Configuration de l'authentification GitHub

1. Dans Supabase Dashboard, allez dans **Authentication** > **Providers**
2. Activez **GitHub**
3. Configurez :
   - **Client ID** : obtenu depuis GitHub OAuth App
   - **Client Secret** : obtenu depuis GitHub OAuth App
   - **Redirect URL** : `io.supabase.quizhub://login-callback`

### 4. Créer les tables dans Supabase

Exécutez ces requêtes SQL dans l'éditeur SQL de Supabase :

```sql
-- Table des utilisateurs
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  username TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des statistiques utilisateur
CREATE TABLE IF NOT EXISTS user_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  total_quizzes INTEGER DEFAULT 0,
  total_correct_answers INTEGER DEFAULT 0,
  total_questions INTEGER DEFAULT 0,
  average_score DECIMAL(5,2) DEFAULT 0,
  best_score INTEGER DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Table de l'historique des quiz
CREATE TABLE IF NOT EXISTS quiz_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  quiz_type TEXT,
  category TEXT,
  difficulty INTEGER,
  score INTEGER,
  total_questions INTEGER,
  correct_answers INTEGER,
  time_taken INTEGER, -- en secondes
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_quiz_history_user_id ON quiz_history(user_id);
CREATE INDEX IF NOT EXISTS idx_quiz_history_created_at ON quiz_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_stats_user_id ON user_stats(user_id);

-- RLS (Row Level Security) - Politique pour permettre aux utilisateurs de lire/écrire leurs propres données
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_history ENABLE ROW LEVEL SECURITY;

-- Politique pour la table users
CREATE POLICY "Users can read own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Politique pour la table user_stats
CREATE POLICY "Users can read own stats" ON user_stats
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own stats" ON user_stats
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own stats" ON user_stats
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politique pour la table quiz_history
CREATE POLICY "Users can read own quiz history" ON quiz_history
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own quiz history" ON quiz_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

## 🚀 Utilisation

### Authentification

```dart
import 'package:app_quiz_hub/shared/services/auth_service.dart';

final authService = AuthService();

// Connexion avec email
await authService.signInWithEmail(
  email: 'user@example.com',
  password: 'password123',
);

// Connexion avec GitHub
await authService.signInWithGitHub();

// Déconnexion
await authService.signOut();
```

### Base de données

```dart
import 'package:app_quiz_hub/shared/services/database_service.dart';

final dbService = DatabaseService();

// Sauvegarder les statistiques
await dbService.saveUserStats(
  userId: 'user-id',
  stats: {
    'total_quizzes': 10,
    'average_score': 85.5,
  },
);

// Récupérer l'historique
final history = await dbService.getQuizHistory('user-id');
```

## 📚 Ressources

- [Documentation Supabase](https://supabase.com/docs)
- [Supabase Flutter](https://supabase.com/docs/reference/dart/introduction)
- [Guide d'authentification](https://supabase.com/docs/guides/auth)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

