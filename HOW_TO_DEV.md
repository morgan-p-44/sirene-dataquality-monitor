# HOW_TO_DEV — Sirene Data Quality Monitor (runbook)

## 0) Pré-requis
- Python 3.x
- psql (PostgreSQL client)
- Accès Supabase (project + DB password)
- Fichier SIRENE brut : data/raw/StockEtablissement_utf8.csv (hors git)

## 1) Variables d'env
Créer `.env` (non versionné) :
- DATABASE_URL (admin, pour pipeline)
- SIRENE_44_CSV (chemin absolu vers data/processed/sirene_44.csv)

Optionnel :
- DATABASE_URL_READONLY (pooler + user dq_readonly.<project_ref>)

Charger :
```bash
set -a; source .env; set +a

## 2) Pipeline complet (admin)

bash scripts/run_pipeline.sh

Étapes :

    filtre CSV -> data/processed/sirene_44.csv

    TRUNCATE + COPY vers Supabase

    vues: v_sirene_44, v_sirene_44_analytics

    règles DQ -> dq_results

    import run -> sirene_import_runs

    vue monitoring -> v_dq_by_import

## 3) Exécuter une étape SQL à la main (admin)

psql "$DATABASE_URL" -f sql/050_view_v_dq_by_import.sql

## 4) Tester le user read-only (pooler)

Exporter une URL read-only :

export DATABASE_URL="postgresql://dq_readonly.<project_ref>:PASSWORD@aws-...pooler.supabase.com:5432/postgres"
psql "$DATABASE_URL" -c "select current_user;"
psql "$DATABASE_URL" -c "select count(*) from public.v_dq_by_import;"
psql "$DATABASE_URL" -c "truncate table public.sirene_44;"  # doit échouer

## 5) Lancer Streamlit (read-only)

pip install -r streamlit_app/requirements.txt
streamlit run streamlit_app/app.py

## 6) Points critiques / erreurs fréquentes

    Erreur socket /var/run/postgresql... => DATABASE_URL non chargé dans le terminal

    COPY timeout => SET statement_timeout=0 doit être dans la même session psql que \copy

    Doublons de règles => v_dq_by_import doit sélectionner un seul run DQ par import

    Direct connection non IPv4 => déploiement via pooler obligatoire si plateforme IPv4-only


