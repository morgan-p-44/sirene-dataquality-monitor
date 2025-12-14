-- sql/031_run_dq_rules.sql
-- Exécution des règles qualité (SIRENE 44)

insert into public.dq_results (rule_code, rule_label, metric_value, threshold, status)

-- Règle 1 : % SIRET invalides < 1 %
select
  'SIRET_INVALID_RATE',
  'Taux de SIRET invalides < 1%',
  round(100.0 * avg((not is_siret_valid)::int), 2),
  1.0,
  case
    when round(100.0 * avg((not is_siret_valid)::int), 2) < 1.0 then 'OK'
    else 'KO'
  end
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

-- Règle 3 : % établissements actifs > 50 %
select
  'ACTIVE_RATE',
  'Taux établissements actifs > 50%',
  round(100.0 * avg(is_actif::int), 2),
  50.0,
  case
    when round(100.0 * avg(is_actif::int), 2) > 50.0 then 'OK'
    else 'KO'
  end
from public.v_sirene_44_analytics;

