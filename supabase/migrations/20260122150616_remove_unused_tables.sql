-- ============================================
-- Migration: Suppression des tables non utilisées
-- ============================================
-- Date: 2025-01-22
-- Description: Supprime user_stats et quiz_history car les stats sont calculées
--              dynamiquement depuis user_question_responses

-- Supprimer les politiques RLS d'abord
DROP POLICY IF EXISTS "Users can read own stats" ON public.user_stats;
DROP POLICY IF EXISTS "Users can update own stats" ON public.user_stats;
DROP POLICY IF EXISTS "Users can insert own stats" ON public.user_stats;
DROP POLICY IF EXISTS "Users can read own quiz history" ON public.quiz_history;
DROP POLICY IF EXISTS "Users can insert own quiz history" ON public.quiz_history;

-- Supprimer les index
DROP INDEX IF EXISTS public.idx_user_stats_user_id;
DROP INDEX IF EXISTS public.idx_quiz_history_user_id;
DROP INDEX IF EXISTS public.idx_quiz_history_created_at;

-- Supprimer les tables
DROP TABLE IF EXISTS public.user_stats;
DROP TABLE IF EXISTS public.quiz_history;

-- Note: Les statistiques sont maintenant calculées dynamiquement depuis
-- la table user_question_responses via QuizService.calculateUserStats()

