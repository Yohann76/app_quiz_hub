# Supabase 

Option in supabase : 

- Les utilisateurs devront confirmer leur adresse électronique avant de se connecter pour la première fois. (desactivate on https://supabase.com/dashboard/project/)

- Utiliser les migrations : Créez une migration : npx supabase migration new create_users_table. Éditez le fichier SQL généré dans supabase/migrations/. Testez localement (supabase db reset), pushez en prod (supabase db push).