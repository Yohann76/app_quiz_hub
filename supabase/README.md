# Migrations Supabase

Ce dossier contient les migrations de base de données versionnées pour le projet.

## Structure

```
supabase/
├── config.toml          # Configuration Supabase locale
├── migrations/          # Migrations versionnées (dans Git)
│   └── YYYYMMDDHHMMSS_nom_migration.sql
└── README.md           # Ce fichier
```

## Migrations disponibles

- `20260122141342_create_initial_schema.sql` - Schéma initial (tables users, user_stats, quiz_history)

## Commandes utiles

```bash
# Créer une nouvelle migration
npx supabase migration new nom_de_la_migration

# Appliquer les migrations localement
npx supabase db reset

# Pousser les migrations vers Supabase
npx supabase db push

# Voir l'état des migrations
npx supabase migration list
```

## Documentation complète

Voir `Docs/migrations_workflow.md` pour le guide complet sur les migrations.

