# HOW_TO_DEV — Sirene Data Quality Monitor

Runbook développeur pour installer, exécuter et diagnostiquer le pipeline **sirene-dataquality-monitor**.

Ce document est destiné à un usage **technique / interne**.

---

## Prérequis

- Python **3.x**
- Client PostgreSQL (`psql`)
- Accès Supabase (projet + mot de passe DB)
- Fichier SIRENE brut (hors git) :

```
data/raw/StockEtablissement_utf8.csv
```

---

## Variables d’environnement

Créer un fichier `.env` (non versionné) à partir de `.env.example` :

```
DATABASE_URL=postgresql://<ADMIN_USER>:<PASSWORD>@<HOST>:5432/postgres
SIRENE_44_CSV=/chemin/absolu/data/processed/sirene_44.csv
```

Variables optionnelles :

```
DATABASE_URL_READONLY=postgresql://dq_readonly.<project_ref>:<PASSWORD>@<POOLER_HOST>:5432/postgres
```

Charger les variables dans le shell :

```
set -a; source .env; set +a
```

---

## Exécution du pipeline complet (admin)

Commande unique :

```
bash scripts/run_pipeline.sh
```

### Étapes exécutées

1. Filtrage du CSV SIRENE (département 44)
2. Écriture du fichier `data/processed/sirene_44.csv`
3. Import PostgreSQL via `TRUNCATE + COPY`
4. Création / mise à jour des vues :
   - `v_sirene_44`
   - `v_sirene_44_analytics`
5. Exécution des règles Data Quality → `dq_results`
6. Enregistrement de l’import → `sirene_import_runs`
7. Vue de monitoring finale → `v_dq_by_import`

---

## Exécution manuelle d’une étape SQL (admin)

Utile pour debug ou développement ciblé.

Exemple :

```
psql "$DATABASE_URL" -f sql/050_view_v_dq_by_import.sql
```

---

## Vérification du rôle read-only (pooler)

Objectif : valider que l’utilisateur `dq_readonly` n’a **aucun droit en écriture**.

Définir temporairement la connexion :

```
export DATABASE_URL="postgresql://dq_readonly.<project_ref>:PASSWORD@aws-...pooler.supabase.com:5432/postgres"
```

Tests attendus :

```
psql "$DATABASE_URL" -c "select current_user;"
psql "$DATABASE_URL" -c "select count(*) from public.v_dq_by_import;"
psql "$DATABASE_URL" -c "truncate table public.sirene_44;"  # doit échouer
```

---

## Lancement de Streamlit (read-only)

Installer les dépendances :

```
pip install -r streamlit_app/requirements.txt
```

Lancer l’application :

```
streamlit run streamlit_app/app.py
```

L’application consomme uniquement des **vues SQL** accessibles en lecture seule.

---

## Points critiques / erreurs fréquentes

### Problème de connexion PostgreSQL

- Erreur : `socket /var/run/postgresql...`
- Cause : variables d’environnement non chargées
- Solution : vérifier `DATABASE_URL` dans le shell courant

---

### Timeout lors du COPY

- Erreur : timeout PostgreSQL pendant l’import
- Cause : `statement_timeout` trop faible
- Solution :

```
SET statement_timeout = 0;
```

Doit être exécuté **dans la même session psql** que le `\copy`.

---

### Doublons dans le monitoring DQ

- Symptôme : règles dupliquées dans `v_dq_by_import`
- Cause : plusieurs exécutions DQ associées au même import
- Solution : la vue doit sélectionner **un seul run DQ par import**

---

### Problème IPv4 / connexion directe

- Certaines plateformes bloquent IPv6
- Solution : utiliser obligatoirement le **Session Pooler Supabase**

---

## Bonnes pratiques

- Ne jamais exposer les tables brutes
- Toujours tester le rôle `dq_readonly`
- Privilégier les vues pour toute consommation applicative
- Rejouer le pipeline complet après modification SQL structurante

