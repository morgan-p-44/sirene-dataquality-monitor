# sirene-dataquality-monitor

Projet de **monitoring de la qualité des données** basé sur les données publiques **SIRENE (INSEE)**, limité aux établissements du **département 44 – Loire-Atlantique**.

L’objectif est de mettre en place un **pipeline data reproductible**, 100 % gratuit, orienté **Data Engineering / Analytics**, avec stockage PostgreSQL (Supabase) et visualisation via Streamlit.

---

## Fonctionnalités

- Ingestion de **CSV volumineux** (~8,8 Go)
- Filtrage géographique (département 44)
- Chargement robuste via **COPY PostgreSQL**
- Normalisation des données via **vues SQL**
- Règles de **Data Quality** formalisées et versionnées
- Historisation des imports
- Suivi de la qualité **dans le temps**
- Visualisation interactive via **Streamlit**

---

## Objectifs

- Importer les données SIRENE (INSEE)
- Filtrer le périmètre au département 44
- Charger les données dans PostgreSQL (Supabase)
- Mettre en place un monitoring qualité structuré
- Suivre la qualité des données dans le temps
- Exposer des résultats lisibles pour analyse et démonstration

---

## Structure du projet

```
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
├─ .github/
│  └─ workflows/
│     └─ keep-alive.yml
├── HOW_TO_DEV.md                 # Runbook développeur (non public)
├── .env.example
├── .gitignore
└── README.md
```

---

## Prérequis

- Python **3.10+**
- Client PostgreSQL (`psql`)
- Accès à une base PostgreSQL (Supabase)
- Environnement **Linux / WSL recommandé**

---

## Variables d’environnement

Créer un fichier `.env` (non versionné) à partir de `.env.example` :

```
DATABASE_URL=postgresql://<ADMIN_USER>:<PASSWORD>@<HOST>:5432/postgres
SIRENE_44_CSV=/chemin/absolu/data/processed/sirene_44.csv
```

Charger les variables :

```
set -a; source .env; set +a
```

---

## Données source

- **Jeu** : SIRENE – StockEtablissement
- **Source** : INSEE / data.gouv.fr
- **Format** : CSV UTF-8
- **Taille** : ~8,8 Go décompressé

Fichier attendu :

```
data/raw/StockEtablissement_utf8.csv
```

Les données ne sont **pas versionnées** (voir `.gitignore`).

---

## Pipeline de traitement

### Filtrage département 44

- Lecture du CSV SIRENE complet
- Filtrage sur `codePostalEtablissement LIKE '44%'`
- Écriture d’un CSV réduit (~676 000 lignes)

Script :
```
ingest/filter_sirene_44.py
```

---

### Base de données

- PostgreSQL hébergé sur **Supabase**
- Table brute : `sirene_44`
- Colonnes en **TEXT** (schéma identique au CSV)
- Import via **COPY PostgreSQL**

---

### Modélisation SQL

**Vue clean – `v_sirene_44`**

- Normalisation des noms de colonnes (`snake_case`)
- Chaînes vides converties en `NULL`
- Base stable pour transformations

**Vue analytics – `v_sirene_44_analytics`**

- Typage logique
- Indicateurs dérivés
- Flags métier et qualité

---

## Data Quality

### Règles implémentées

- **ACTIVE_RATE_RECENT**  
  Taux d’établissements actifs (créés après 2010) ≥ 50 %

- **CP_NULL_RATE**  
  Taux de codes postaux NULL < 0,5 %

- **SIRET_INVALID_RATE**  
  Taux de SIRET invalides < 1 %

Les résultats sont stockés dans la table `dq_results` et historisés par import.

---

## Historisation

Chaque exécution du pipeline enregistre :

- Date d’import
- Fichier source
- Nombre de lignes
- Identifiant d’import

Cela permet un suivi **temporel** de la qualité des données.

---

## Application Streamlit

- Basée uniquement sur des **vues SQL**
- Sélection d’un import
- Statut global `OK / KO`
- Détail par règle

Lancement local :

```
streamlit run streamlit_app/app.py
```

---

## Sécurité

- Rôle PostgreSQL en **lecture seule**
- Aucune table brute exposée
- Accès via Session Pooler Supabase

---

## Roadmap / Améliorations

- Ajout de nouvelles règles Data Quality (fraîcheur, cohérence inter-champs)
- Paramétrisation des seuils par environnement (stockage des seuils dans une table dq_rule_config ou dans des variables)
- Orchestration via Airflow (planification hebdo et gestion des dépendances : filtrage → import → vues → DQ → historisation)
- Export des résultats DQ (export automatique en CSV après execution / exposition d'un endpoint FastAPI)
- Ajout de tests automatisés sur les règles SQL ?
- Déploiement Streamlit public pour portfolio

---

## Choix techniques

- **PostgreSQL (Supabase)** : gratuit, robuste, SQL natif
- **COPY PostgreSQL** : performant sur gros volumes
- **Table brute + vues** : séparation ingestion / logique métier
- **Monitoring SQL versionné** : explicite et traçable
- **Streamlit** : simple, rapide, démonstratif

