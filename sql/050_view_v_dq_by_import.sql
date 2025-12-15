-- sql/050_view_v_dq_by_import.sql
-- Vue liant chaque import SIRENE à ses résultats qualité
-- 1 import -> 1 run DQ (le plus récent <= imported_at) -> 1 ligne par règle

create or replace view public.v_dq_by_import as
with last_dq_run as (
  select
    r.import_id,
    r.imported_at,
    r.source_file,
    r.row_count,
    (
      select max(d.run_at)
      from public.dq_results d
      where d.run_at <= r.imported_at
    ) as dq_run_at
  from public.sirene_import_runs r
)
select
  r.import_id,
  r.imported_at,
  r.source_file,
  r.row_count,
  d.rule_code,
  d.rule_label,
  d.metric_value,
  d.threshold,
  d.status,
  d.run_at as dq_run_at
from last_dq_run r
join public.dq_results d
  on d.run_at = r.dq_run_at;


