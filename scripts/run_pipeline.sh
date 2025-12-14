#!/usr/bin/env bash
set -euo pipefail

echo "🚀 SIRENE 44 – Data Quality Pipeline"

echo "▶️ 1. Filtrage du CSV SIRENE (département 44)"
python ingest/filter_sirene_44.py

echo "▶️ 2. Import dans Supabase (TRUNCATE + COPY)"
bash ingest/load_to_supabase.sh

echo "▶️ 3. Création / mise à jour de la vue clean"
psql "$DATABASE_URL" -f sql/001_view_v_sirene_44.sql

echo "▶️ 4. Création / mise à jour de la vue analytics"
psql "$DATABASE_URL" -f sql/020_view_v_sirene_44_analytics.sql

echo "▶️ 5. Exécution des règles Data Quality"
psql "$DATABASE_URL" -f sql/031_run_dq_rules.sql

echo "▶️ 6. Enregistrement de l'import"
psql "$DATABASE_URL" -c "
insert into public.sirene_import_runs (source_file, row_count, comment)
select
  'sirene_44.csv',
  count(*),
  'pipeline run'
from public.sirene_44;
"

echo "✅ Pipeline terminé avec succès"

