-- ============================================
-- Migration initiale : Création du schéma de base
-- ============================================
-- Date: 2025-01-22
-- Description: Création des tables users, user_stats, quiz_history
--              avec leurs index et politiques RLS

-- Table des utilisateurs
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  username TEXT,
  language TEXT, -- Code de langue (fr, en, es)
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des statistiques utilisateur
CREATE TABLE IF NOT EXISTS public.user_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  total_quizzes INTEGER DEFAULT 0,
  total_correct_answers INTEGER DEFAULT 0,
  total_questions INTEGER DEFAULT 0,
  average_score DECIMAL(5,2) DEFAULT 0,
  best_score INTEGER DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Table de l'historique des quiz
CREATE TABLE IF NOT EXISTS public.quiz_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
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
CREATE INDEX IF NOT EXISTS idx_quiz_history_user_id ON public.quiz_history(user_id);
CREATE INDEX IF NOT EXISTS idx_quiz_history_created_at ON public.quiz_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_stats_user_id ON public.user_stats(user_id);

-- RLS (Row Level Security) - Activer la sécurité au niveau des lignes
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_history ENABLE ROW LEVEL SECURITY;

-- Supprimer les politiques existantes si elles existent (pour éviter les erreurs)
DROP POLICY IF EXISTS "Users can read own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can read own stats" ON public.user_stats;
DROP POLICY IF EXISTS "Users can update own stats" ON public.user_stats;
DROP POLICY IF EXISTS "Users can insert own stats" ON public.user_stats;
DROP POLICY IF EXISTS "Users can read own quiz history" ON public.quiz_history;
DROP POLICY IF EXISTS "Users can insert own quiz history" ON public.quiz_history;

-- Politique pour la table users
CREATE POLICY "Users can read own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- Politique pour la table user_stats
CREATE POLICY "Users can read own stats" ON public.user_stats
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own stats" ON public.user_stats
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own stats" ON public.user_stats
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politique pour la table quiz_history
CREATE POLICY "Users can read own quiz history" ON public.quiz_history
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own quiz history" ON public.quiz_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

