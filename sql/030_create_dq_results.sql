-- sql/030_create_dq_results.sql
-- Table de résultats de data quality

create table if not exists public.dq_results (
  run_at timestamptz not null default now(),
  rule_code text not null,
  rule_label text not null,
  metric_value numeric,
  threshold numeric,
  status text not null,
  primary key (run_at, rule_code)
);

