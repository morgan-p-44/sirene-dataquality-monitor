-- sql/031_run_dq_rules.sql
-- Exécution des règles qualité (SIRENE 44)

insert into public.dq_results (rule_code, rule_label, metric_value, threshold, status)

-- Règle 1 : % SIRET invalides < 1 %
select
  'SIRET_INVALID_RATE' as rule_code,
  'Taux de SIRET invalides < 1%' as rule_label,
  round(100.0 * avg((not is_siret_valid)::int), 2) as metric_value,
  1.0 as threshold,
  case
    when round(100.0 * avg((not is_siret_valid)::int), 2) < 1.0 then 'OK'
    else 'KO'
  end as status
from public.v_sirene_44_analytics

union all

-- Règle 2 : % code postal NULL < 0.5 %
select
  'CP_NULL_RATE',
  'Taux de code postal NULL < 0.5%',
  round(100.0 * avg((code_postal_etablissement is null)::int), 2),
  0.5,
  case
    when round(100.0 * avg((code_postal_etablissement is null)::int), 2) < 0.5 then 'OK'
    else 'KO'
  end
from public.v_sirene_44_analytics

union all

-- Règle 3 : % établissements actifs (créés >= 2010) > 50 %
select
  'ACTIVE_RATE_RECENT',
  'Taux établissements actifs (créés après 2010) > 50%',
  round(
    100.0 * avg((etat_administratif_etablissement = 'A')::int),
    2
  ),
  50.0,
  case
    when round(100.0 * avg((etat_administratif_etablissement = 'A')::int), 2) >= 50.0 then 'OK'
    else 'KO'
  end
from public.v_sirene_44_analytics
where date_creation_etablissement >= date '2010-01-01';
