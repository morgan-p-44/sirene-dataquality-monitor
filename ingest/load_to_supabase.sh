#!/usr/bin/env bash
set -euo pipefail

# charge .env depuis la racine du repo (même si on lance le script depuis ailleurs)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  source "$ROOT_DIR/.env"
  set +a
fi

: "${DATABASE_URL:?DATABASE_URL manquant (vérifie .env)}"


echo "🧹 Truncate table"
psql "$DATABASE_URL" -c "TRUNCATE TABLE public.sirene_44;"

echo "📥 Import CSV"
psql "$DATABASE_URL" -c "\
\copy public.sirene_44 \
FROM '${SIRENE_44_CSV}' \
WITH (
  FORMAT csv,
  HEADER true,
  DELIMITER ',',
  QUOTE '\"',
  ENCODING 'UTF8'
);"

echo "✅ Vérification"
psql "$DATABASE_URL" -c "SELECT COUNT(*) FROM public.sirene_44;"


