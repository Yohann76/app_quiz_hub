# Supabase 

Link: https://supabase.com/

account supabase: with github

## Organization: 

- AlgoYo Organization
- Personal 
- free 

## Project in supabase: 

- Organization: AlgoYo Organization
- project name: app_quizz_hub
- database password: a41* (this password is a mock data)
- region: Europe

## Prérequis

- Un compte Supabase (https://supabase.com/)
- Un projet créé dans Supabase
- Les clés API de votre projet

### Configurer les clés dans l'application

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=votre_cle_anon_ici
```

### Migration: 

```
npx supabase login # login project to supabase
npx supabase migration new nom_de_la_migration # create migration
npx supabase db reset # Réinitialiser la base locale et appliquer toutes les migrations
npx supabase migration up # Appliquer uniquement les nouvelles migrations
npx supabase link --project-ref wtkoltquvmwbyligkdhn # # Lier votre projet local à Supabase (première fois uniquement)
npx supabase db push # npx supabase db push
npx supabase migration list # # Voir les migrations appliquées
```

## Ressources

- [Documentation Supabase](https://supabase.com/docs)
- [Supabase Flutter](https://supabase.com/docs/reference/dart/introduction)
- [Guide d'authentification](https://supabase.com/docs/guides/auth)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- **[Workflow des Migrations](./migrations_workflow.md)** - Guide complet sur les migrations versionnées

