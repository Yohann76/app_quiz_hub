-- ============================================
-- Migration: Suppression des tables non utilisées
-- ============================================
-- Date: 2025-01-22
-- Description: Supprime user_stats et quiz_history si elles existent (stats calculées
--              dynamiquement depuis user_question_responses). Sans erreur si les
--              tables n'ont jamais existé en prod.

-- Supprimer les politiques RLS seulement si les tables existent
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_stats') THEN
    DROP POLICY IF EXISTS "Users can read own stats" ON public.user_stats;
    DROP POLICY IF EXISTS "Users can update own stats" ON public.user_stats;
    DROP POLICY IF EXISTS "Users can insert own stats" ON public.user_stats;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'quiz_history') THEN
    DROP POLICY IF EXISTS "Users can read own quiz history" ON public.quiz_history;
    DROP POLICY IF EXISTS "Users can insert own quiz history" ON public.quiz_history;
  END IF;
END $$;

-- Supprimer les index (IF EXISTS suffit, pas de table requise)
DROP INDEX IF EXISTS public.idx_user_stats_user_id;
DROP INDEX IF EXISTS public.idx_quiz_history_user_id;
DROP INDEX IF EXISTS public.idx_quiz_history_created_at;

-- Supprimer les tables
DROP TABLE IF EXISTS public.user_stats;
DROP TABLE IF EXISTS public.quiz_history;

-- Note: Les statistiques sont maintenant calculées dynamiquement depuis
-- la table user_question_responses via QuizService.calculateUserStats()
