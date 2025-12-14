-- sql/010_dq_checks.sql
-- Data Quality checks – SIRENE établissements – Département 44
-- Source : public.v_sirene_44

------------------------------------------------------------
-- 1. Volumétrie globale
------------------------------------------------------------
select
  count(*) as total_rows
from public.v_sirene_44;

------------------------------------------------------------
-- 2. Cohérence département 44 (code postal)
------------------------------------------------------------
select
  count(*) as total,
  count(*) filter (where code_postal_etablissement like '44%') as cp_44,
  count(*) filter (where code_postal_etablissement is null) as cp_null,
  count(*) filter (
    where code_postal_etablissement is not null
      and code_postal_etablissement !~ '^[0-9]{5}$'
  ) as cp_bad_format
from public.v_sirene_44;

------------------------------------------------------------
-- 3. Cohérence département 44 (code commune INSEE)
------------------------------------------------------------
select
  count(*) as total,
  count(*) filter (where code_commune_etablissement like '44%') as commune_44,
  count(*) filter (where code_commune_etablissement is null) as commune_null
from public.v_sirene_44;

------------------------------------------------------------
-- 4. Complétude des champs clés
------------------------------------------------------------
select
  count(*) as total,
  count(*) filter (where siret is null) as siret_null,
  count(*) filter (where siren is null) as siren_null,
  count(*) filter (where etat_administratif_etablissement is null) as etat_admin_null,
  count(*) filter (where activite_principale_etablissement is null) as ape_null
from public.v_sirene_44;

------------------------------------------------------------
-- 5. Format SIRET (14 chiffres)
------------------------------------------------------------
select
  count(*) as total,
  count(*) filter (where siret ~ '^[0-9]{14}$') as siret_ok,
  count(*) filter (where siret is null) as siret_null,
  count(*) filter (
    where siret is not null
      and siret !~ '^[0-9]{14}$'
  ) as siret_bad
from public.v_sirene_44;

------------------------------------------------------------
-- 6. Unicité SIRET
------------------------------------------------------------
select
  count(*) as total_rows,
  count(distinct siret) as distinct_siret,
  count(*) - count(distinct siret) as duplicate_rows
from public.v_sirene_44;

------------------------------------------------------------
-- 7. Détails des doublons SIRET (investigation)
------------------------------------------------------------
select
  siret,
  count(*) as n
from public.v_sirene_44
where siret is not null
group by siret
having count(*) > 1
order by n desc
limit 50;

------------------------------------------------------------
-- 8. Répartition établissements actifs / fermés
------------------------------------------------------------
select
  etat_administratif_etablissement,
  count(*) as n
from public.v_sirene_44
group by etat_administratif_etablissement
order by n desc;

------------------------------------------------------------
-- 9. KPI taux d'établissements actifs
------------------------------------------------------------
select
  count(*) as total,
  count(*) filter (where etat_administratif_etablissement = 'A') as actifs,
  round(
    100.0 * count(*) filter (where etat_administratif_etablissement = 'A')
    / nullif(count(*), 0),
    2
  ) as pct_actifs
from public.v_sirene_44;


