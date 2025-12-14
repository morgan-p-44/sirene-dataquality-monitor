# sirene-dataquality-monitor

Projet de **monitoring qualité de données** basé sur les données publiques **SIRENE (INSEE)**, limité aux **établissements du département 44 (Loire-Atlantique)**.

Le projet met en place un **pipeline reproductible** dans **Supabase (PostgreSQL)** avec :
- ingestion depuis CSV
- normalisation via vues SQL
- contrôles qualité formalisés
- historisation des imports
- suivi qualité par import

Stack 100 % gratuite, orientée **data engineering / analytics**.

---

## 🎯 Objectifs

- Importer les données SIRENE (INSEE)
- Filtrer le périmètre département 44
- Charger les données dans PostgreSQL (Supabase)
- Mettre en place un **monitoring qualité structuré**
- Préparer une base propre pour analyses et dashboards

---

## 🗂️ Structure du projet

sirene-dataquality-monitor/
├── data/
│ ├── raw/ # Données brutes INSEE (non versionnées)
│ └── processed/ # CSV filtré sirene_44.csv (non versionné)
├── ingest/
│ ├── filter_sirene_44.py
│ └── load_to_supabase.sh
├── sql/
│ ├── 001_view_v_sirene_44.sql
│ ├── 010_dq_checks.sql
│ ├── 020_view_v_sirene_44_analytics.sql
│ ├── 030_create_dq_results.sql
│ ├── 031_run_dq_rules.sql
│ ├── 040_create_import_runs.sql
│ └── 050_view_v_dq_by_import.sql
├── scripts/
│ └── run_pipeline.sh # Orchestration complète du pipeline
├── .env.example
├── .gitignore
└── README.md


---

## ⚙️ Prérequis

- Python 3.10+
- Client PostgreSQL (`psql`)
- Accès à une base PostgreSQL (Supabase)

Les dépendances Python sont listées dans `requirements.txt` (si utilisé).

---

## 📥 Données source

- **SIRENE – StockEtablissement**
- Source : INSEE / data.gouv.fr
- Format : CSV UTF-8 (~8,8 Go décompressé)

Fichier attendu :

data/raw/StockEtablissement_utf8.csv


Les données ne sont **pas versionnées**.

---

## 🔍 Filtrage département 44

Le script `ingest/filter_sirene_44.py` :
- lit le CSV SIRENE complet
- filtre sur `codePostalEtablissement LIKE '44%'`
- produit un CSV réduit

Sortie :

data/processed/sirene_44.csv


---

## 🗄️ Base de données

- Base PostgreSQL hébergée sur **Supabase**
- Table brute : `sirene_44` (colonnes TEXT, schéma issu du CSV)
- Transformations réalisées via **vues SQL**

---

## 🧼 Vue clean

Vue : `v_sirene_44`

- noms en `snake_case`
- chaînes vides converties en `NULL`
- usage SQL sans guillemets

Définition :

sql/001_view_v_sirene_44.sql


---

## 📊 Vue analytics

Vue : `v_sirene_44_analytics`

- typage logique
- indicateurs calculés (`is_actif`, validité SIRET, département)
- base prête pour BI / dashboards

Définition :

sql/020_view_v_sirene_44_analytics.sql


---

## 🧪 Data Quality

### Checks analytiques
Fichier :

sql/010_dq_checks.sql


Contrôles :
- volumétrie
- cohérence département
- complétude
- format & unicité SIRET
- répartition actifs / fermés

### Monitoring structuré
- Table : `dq_results`
- Règles exécutées via `sql/031_run_dq_rules.sql`
- Résultat : métrique, seuil, statut `OK / KO`, timestamp

---

## 🕒 Historisation des imports

Table :

sirene_import_runs


Chaque import enregistre :
- date d’import
- fichier source
- nombre de lignes

---

## 📈 Vue Data Quality par import

Vue :

v_dq_by_import


Cette vue associe chaque import à la **dernière exécution DQ connue**, avec :
- une ligne par règle
- un statut exploitable en BI

Définition :

sql/050_view_v_dq_by_import.sql


---

## ▶️ Exécution du pipeline complet

Un script unique permet de rejouer l’ensemble du pipeline :

```bash
bash scripts/run_pipeline.sh

Étapes incluses :

    filtrage CSV

    import Supabase

    vues SQL

    règles Data Quality

    historisation de l’import

🧠 Choix techniques

    PostgreSQL (Supabase) : gratuit, fiable, SQL natif

    COPY PostgreSQL : performant sur gros volumes

    Table brute + vues : séparation ingestion / logique métier

    Monitoring SQL versionné : explicite, traçable, outillé