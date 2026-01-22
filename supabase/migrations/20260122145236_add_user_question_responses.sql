-- ============================================
-- Migration: Ajout de la table user_question_responses
-- ============================================
-- Date: 2025-01-22
-- Description: Table pour tracker les réponses individuelles aux questions

-- Table pour tracker les réponses aux questions
CREATE TABLE IF NOT EXISTS public.user_question_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  question_id TEXT NOT NULL, -- ID de la question depuis les fichiers
  language TEXT NOT NULL, -- Code de langue (fr, en, es)
  is_correct BOOLEAN NOT NULL,
  selected_answer_index INTEGER NOT NULL,
  category TEXT,
  difficulty INTEGER,
  answered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, question_id, language) -- Un utilisateur ne peut répondre qu'une fois à une question dans une langue
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_user_question_responses_user_id ON public.user_question_responses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_question_responses_question_id ON public.user_question_responses(question_id);
CREATE INDEX IF NOT EXISTS idx_user_question_responses_language ON public.user_question_responses(language);

-- RLS (Row Level Security)
ALTER TABLE public.user_question_responses ENABLE ROW LEVEL SECURITY;

-- Supprimer les politiques existantes si elles existent
DROP POLICY IF EXISTS "Users can read own question responses" ON public.user_question_responses;
DROP POLICY IF EXISTS "Users can insert own question responses" ON public.user_question_responses;
DROP POLICY IF EXISTS "Users can update own question responses" ON public.user_question_responses;

-- Politique pour la table user_question_responses
CREATE POLICY "Users can read own question responses" ON public.user_question_responses
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own question responses" ON public.user_question_responses
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own question responses" ON public.user_question_responses
  FOR UPDATE USING (auth.uid() = user_id);

