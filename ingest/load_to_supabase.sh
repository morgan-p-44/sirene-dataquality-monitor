#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  source "$ROOT_DIR/.env"
  set +a
fi

: "${DATABASE_URL:?DATABASE_URL manquant (vérifie .env)}"
: "${SIRENE_44_CSV:?SIRENE_44_CSV manquant (vérifie .env)}"

echo "🧹 Truncate table"
psql "$DATABASE_URL" -c "TRUNCATE TABLE public.sirene_44;"

echo "📥 Import CSV (statement_timeout=0 in same session)"
psql "$DATABASE_URL" <<SQL
SET statement_timeout = 0;
\\copy public.sirene_44 FROM '${SIRENE_44_CSV}' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
SQL

echo "✅ Vérification"
ROWS=$(psql "$DATABASE_URL" -t -A -c "SELECT COUNT(*) FROM public.sirene_44;")
echo "Rows: $ROWS"

if [ "${ROWS}" -eq 0 ]; then
  echo "❌ Import failed (0 rows). Not registering import run."
  exit 1
fi

echo "🧾 Register import run"
psql "$DATABASE_URL" -c "
insert into public.sirene_import_runs (source_file, row_count, comment)
values ('sirene_44.csv', ${ROWS}, 'reload');
"

echo "✅ Import completed"
