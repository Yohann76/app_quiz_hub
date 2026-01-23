-- ============================================
-- Migration: Ajout de la fonction de classement
-- ============================================
-- Date: 2025-01-23
-- Description: Fonction SQL pour calculer le classement d'un utilisateur
--              basé sur son score moyen (pourcentage de bonnes réponses)

-- Fonction pour calculer le classement d'un utilisateur
CREATE OR REPLACE FUNCTION public.get_user_ranking(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_position INTEGER;
  v_total_players INTEGER;
  v_user_score NUMERIC;
  v_top_10_percent BOOLEAN;
  v_top_20_percent BOOLEAN;
  v_top_50_percent BOOLEAN;
BEGIN
  -- Calculer les statistiques pour tous les utilisateurs
  WITH user_stats AS (
    SELECT 
      user_id,
      COUNT(*) as total_responses,
      COUNT(*) FILTER (WHERE is_correct = true) as correct_responses,
      CASE 
        WHEN COUNT(*) > 0 THEN (COUNT(*) FILTER (WHERE is_correct = true)::NUMERIC / COUNT(*)::NUMERIC * 100)
        ELSE 0
      END as score
    FROM public.user_question_responses
    GROUP BY user_id
  ),
  ranked_users AS (
    SELECT 
      user_id,
      score,
      ROW_NUMBER() OVER (ORDER BY score DESC, total_responses DESC) as position
    FROM user_stats
  )
  SELECT 
    ru.position,
    (SELECT COUNT(*) FROM user_stats) as total,
    COALESCE(ru.score, 0) as score
  INTO v_position, v_total_players, v_user_score
  FROM ranked_users ru
  WHERE ru.user_id = p_user_id;

  -- Si l'utilisateur n'a pas de réponses, retourner des valeurs par défaut
  IF v_position IS NULL THEN
    SELECT COUNT(DISTINCT user_id) INTO v_total_players FROM public.user_question_responses;
    RETURN json_build_object(
      'position', 0,
      'total_players', COALESCE(v_total_players, 0),
      'score', 0.0,
      'is_top_10_percent', false,
      'is_top_20_percent', false,
      'is_top_50_percent', false
    );
  END IF;

  -- Calculer les seuils pour top 10%, 20%, 50%
  v_top_10_percent := v_position <= CEIL(v_total_players * 0.1);
  v_top_20_percent := v_position <= CEIL(v_total_players * 0.2);
  v_top_50_percent := v_position <= CEIL(v_total_players * 0.5);

  -- Retourner le résultat en JSON
  RETURN json_build_object(
    'position', v_position,
    'total_players', v_total_players,
    'score', ROUND(v_user_score::NUMERIC, 2),
    'is_top_10_percent', v_top_10_percent,
    'is_top_20_percent', v_top_20_percent,
    'is_top_50_percent', v_top_50_percent
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permettre l'exécution de la fonction pour les utilisateurs authentifiés
GRANT EXECUTE ON FUNCTION public.get_user_ranking(UUID) TO authenticated;

-- Note: SECURITY DEFINER permet à la fonction de contourner RLS
-- pour lire les statistiques agrégées de tous les utilisateurs,
-- tout en respectant la sécurité car seuls les utilisateurs authentifiés
-- peuvent appeler la fonction.

