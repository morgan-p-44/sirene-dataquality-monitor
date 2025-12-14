# sirene-dataquality-monitor
sirene-dataquality-monitor

# Sirene Data Quality Monitor

Ce projet permet d'extraire, filtrer et charger les données **SIRENE – établissements du département 44 (Loire-Atlantique)** dans une base **Supabase PostgreSQL**, de manière **reproductible, fiable et documentée**.

---

## 🎯 Objectif

* Télécharger les données SIRENE officielles (INSEE)
* Filtrer uniquement le **département 44**
* Charger les données dans **Supabase PostgreSQL**
* Disposer d'une base propre pour analyses, data quality, dashboards

---

## 🗂️ Structure du projet

```
sirene-dataquality-monitor/
├── data/
│   ├── raw/            # Données brutes (CSV volumineux, ignoré par git)
│   └── processed/      # Données filtrées (sirene_44.csv)
├── ingest/
│   ├── filter_sirene_44.py     # Filtre département 44
│   ├── import_sirene_44.py     # (optionnel) import via Python
│   └── load_to_supabase.sh     # Import PostgreSQL via COPY (méthode retenue)
├── .env.example
├── .gitignore
└── README.md
```

---

## 📥 1. Données source (INSEE)

Télécharger depuis data.gouv.fr :

* **Jeu** : *Sirene – Fichier StockEtablissement*
* **Format** : CSV (UTF-8)
* **Fichier final** :

```
StockEtablissement_utf8.csv  (~8,8 Go)
```

Placer le fichier ici :

```
data/raw/StockEtablissement_utf8.csv
```

⚠️ Ce fichier est **volumineux** et doit rester hors Git (`.gitignore`).

---

## 🔍 2. Filtrage département 44

Script :

```
ingest/filter_sirene_44.py
```

Lancer :

```bash
python ingest/filter_sirene_44.py
```

Résultat :

```
data/processed/sirene_44.csv
```

Environ **676 000 lignes**.

---

## 🔐 3. Configuration Supabase

### Créer un projet Supabase

* Région par défaut
* Plan gratuit

### Récupérer la connexion PostgreSQL

Dans Supabase → **Connect** → Connection String :

* Type : `URI`
* Method : **Direct connection**

⚠️ Attention : IPv6 par défaut. Fonctionne sous WSL **après configuration DNS**.

---

## 🔧 4. Variables d'environnement

Créer le fichier `.env` (non versionné) :

```bash
cp .env.example .env
```

Exemple `.env` :

```env
DATABASE_URL=postgresql://postgres:PASSWORD@db.xxxxx.supabase.co:5432/postgres
SIRENE_44_CSV=/home/USER/Repos/sirene-dataquality-monitor/data/processed/sirene_44.csv
```

Charger les variables :

```bash
set -a; source .env; set +a
```

Tester la connexion :

```bash
psql "$DATABASE_URL" -c "select now();"
```

---

## 🏗️ 5. Création automatique de la table

⚠️ Étape **clé** : la table doit correspondre **exactement** aux colonnes CSV.

Commande à exécuter **telle quelle** :

```bash
psql "$DATABASE_URL" -c "$(python - <<'PY'
import pandas as pd
cols = pd.read_csv('data/processed/sirene_44.csv', nrows=1).columns.tolist()
sql = 'DROP TABLE IF EXISTS public.sirene_44; CREATE TABLE public.sirene_44 ('
sql += ','.join([f'\"{c}\" text' for c in cols])
sql += ');'
print(sql)
PY
)"
```

Cette commande :

* lit les colonnes du CSV
* supprime la table si elle existe
* recrée la table avec le bon schéma

---

## 📤 6. Import des données dans Supabase

Script utilisé (méthode retenue) :

```
ingest/load_to_supabase.sh
```

Rendre exécutable :

```bash
chmod +x ingest/load_to_supabase.sh
```

Lancer l'import :

```bash
bash ingest/load_to_supabase.sh
```

Sortie attendue :

```
✂️ Truncate table
📥 Import CSV
COPY 676473
✅ Vérification
```

---

## ✅ 7. Vérification finale

```bash
psql "$DATABASE_URL" -c "SELECT COUNT(*) FROM public.sirene_44;"
```

Résultat attendu :

```
676473
```

---

## 🧠 Choix techniques

* **COPY PostgreSQL** préféré à pandas/ORM :

  * plus rapide
  * plus fiable sur gros volumes
  * reproductible
* Table en `TEXT` volontairement :

  * pas de blocage à l'import
  * typage possible ultérieurement

---

## 🔁 Rejouer l'import

À tout moment :

```bash
bash ingest/load_to_supabase.sh
```

La table est **vidée puis rechargée** (mode `TRUNCATE`).

---

## 📌 Prochaines étapes possibles

* Index (codePostal, siret)
* Data quality checks
* Dashboards (Metabase / Streamlit)
* Historisation

---

✅ **Pipeline validé et reproductible**


1. filter_sirene_44.py   → crée un CSV filtré (44 uniquement)
2. import_sirene_44.py   → charge ce CSV dans Supabase

## Pipeline d'ingestion

1. Télécharger le fichier SIRENE StockEtablissement (CSV UTF-8)
2. Le placer dans `data/raw/`
3. Filtrer le département 44 :
   ```bash
   python ingest/filter_sirene_44.py

##########################################

# Sirene Data Quality Monitor (Dépt 44)

Objectif : télécharger le fichier SIRENE “StockEtablissement”, filtrer les établissements du **département 44** puis importer le résultat dans **Supabase Postgres** pour analyses/qualité.

---

## 0) Pré-requis

- Linux / WSL (Ubuntu) + Python 3
- `psql` installé (client PostgreSQL)

### Installer psql (Ubuntu/WSL)
```bash
sudo apt update
sudo apt install -y postgresql-client
psql --version
