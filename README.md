sirene-dataquality-monitor

Projet de monitoring de qualité de données basé sur les données publiques SIRENE (INSEE), limité aux établissements du département 44 (Loire-Atlantique).

Le projet met en place un pipeline data reproductible dans Supabase (PostgreSQL) avec :

ingestion de données CSV volumineuses (≈ 8,8 Go)

normalisation via vues SQL

règles de Data Quality formalisées

historisation des imports

suivi qualité par import

visualisation interactive via Streamlit

Stack 100 % gratuite, orientée Data Engineering / Analytics.

🎯 Objectifs

Importer les données SIRENE (INSEE)

Filtrer le périmètre département 44

Charger les données dans PostgreSQL (Supabase)

Mettre en place un monitoring qualité structuré

Suivre la qualité dans le temps

Exposer des résultats lisibles pour analyse et démonstration

🗂️ Structure du projet
sirene-dataquality-monitor/
├── data/
│   ├── raw/                      # Données brutes INSEE (non versionnées)
│   └── processed/                # CSV filtré sirene_44.csv (non versionné)
├── ingest/
│   ├── filter_sirene_44.py       # Filtrage département 44
│   └── load_to_supabase.sh       # Import PostgreSQL (TRUNCATE + COPY)
├── sql/
│   ├── 001_view_v_sirene_44.sql
│   ├── 010_dq_checks.sql
│   ├── 020_view_v_sirene_44_analytics.sql
│   ├── 030_create_dq_results.sql
│   ├── 031_run_dq_rules.sql
│   ├── 040_create_import_runs.sql
│   └── 050_view_v_dq_by_import.sql
├── scripts/
│   └── run_pipeline.sh           # Orchestration complète du pipeline
├── streamlit_app/
│   ├── app.py                    # Application Streamlit
│   └── requirements.txt
├── HOW_TO_DEV.md                 # Runbook développeur (non public)
├── .env.example
├── .gitignore
└── README.md

⚙️ Prérequis

Python 3.10+

Client PostgreSQL (psql)

Accès à une base PostgreSQL (Supabase)

Environnement Linux / WSL recommandé

🔐 Variables d’environnement

Créer un fichier .env (non versionné) à partir de .env.example :

DATABASE_URL=postgresql://<ADMIN_USER>:<PASSWORD>@<HOST>:5432/postgres
SIRENE_44_CSV=/chemin/absolu/data/processed/sirene_44.csv


Charger les variables :

set -a; source .env; set +a

📥 Données source

Jeu : SIRENE – StockEtablissement

Source : INSEE / data.gouv.fr

Format : CSV UTF-8

Taille : ~8,8 Go décompressé

Fichier attendu :

data/raw/StockEtablissement_utf8.csv


⚠️ Les données ne sont pas versionnées (voir .gitignore).

🔍 Filtrage département 44

Script :

ingest/filter_sirene_44.py


Fonctionnement :

lecture du CSV SIRENE complet

filtrage sur codePostalEtablissement LIKE '44%'

écriture d’un CSV réduit

Sortie :

data/processed/sirene_44.csv


≈ 676 000 lignes

🗄️ Base de données

PostgreSQL hébergé sur Supabase

Table brute : sirene_44

Colonnes en TEXT (schéma identique au CSV)

Import via COPY PostgreSQL (robuste sur gros volumes)

🧼 Vue clean

Vue : v_sirene_44

Objectifs :

noms de colonnes en snake_case

chaînes vides converties en NULL

SQL sans guillemets

base stable pour transformations

Définition :

sql/001_view_v_sirene_44.sql

📊 Vue analytics

Vue : v_sirene_44_analytics

Ajouts :

typage logique

indicateurs dérivés

flags qualité (validité SIRET, statut actif…)

Base prête pour :

règles Data Quality

analyses métier

dashboards

Définition :

sql/020_view_v_sirene_44_analytics.sql

🧪 Data Quality
Table de résultats

Table : dq_results

Contient :

code de règle

libellé

métrique calculée

seuil

statut (OK / KO)

timestamp d’exécution

Règles implémentées

ACTIVE_RATE_RECENT
Taux d’établissements actifs (créés après 2010) ≥ 50 %

CP_NULL_RATE
Taux de codes postaux NULL < 0,5 %

SIRET_INVALID_RATE
Taux de SIRET invalides < 1 %

Définition et exécution :

sql/031_run_dq_rules.sql

🕒 Historisation des imports

Table : sirene_import_runs

Chaque exécution du pipeline enregistre :

date d’import

fichier source

nombre de lignes

identifiant d’import (import_id)

📈 Vue Data Quality par import

Vue : v_dq_by_import

Fonction :

associe chaque import à sa dernière exécution DQ

une ligne par règle et par import

base unique pour BI et Streamlit

Définition :

sql/050_view_v_dq_by_import.sql

▶️ Exécution du pipeline complet

Un script unique permet de rejouer tout le pipeline :

bash scripts/run_pipeline.sh


Étapes incluses :

Filtrage CSV

Import Supabase (TRUNCATE + COPY)

Création / mise à jour des vues

Exécution des règles Data Quality

Historisation de l’import

📊 Application Streamlit

L’application Streamlit consomme exclusivement des vues SQL.

Fonctionnalités :

sélection d’un import

statut global OK / KO

détail par règle

filtre “KO uniquement”

Lancement local :

streamlit run streamlit_app/app.py

🔐 Sécurité

Rôle PostgreSQL dq_readonly

Accès lecture seule

Aucune table brute exposée

Connexion via Session Pooler Supabase (IPv4 compatible)

Utilisé pour Streamlit et accès public

📖 Documentation développeur

Un runbook interne est disponible :

HOW_TO_DEV.md


Il décrit :

setup local

gestion des rôles PostgreSQL

exécution pas à pas

points de vigilance / debug

➡️ Ce fichier n’est pas destiné au public
➡️ Il peut rester versionné ou non selon ton choix

🧠 Choix techniques

PostgreSQL (Supabase) : gratuit, robuste, SQL natif

COPY PostgreSQL : performant sur gros volumes

Table brute + vues : séparation ingestion / logique métier

Monitoring SQL versionné : explicite, traçable

Streamlit : simple, rapide, démonstratif

