-- sql/050_view_v_dq_by_import.sql
-- Vue liant chaque import SIRENE à ses résultats qualité

create or replace view public.v_dq_by_import as
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

from public.sirene_import_runs r
join lateral (
  select *
  from public.dq_results d
  where d.run_at <= r.imported_at
  order by d.run_at desc
) d on true;

