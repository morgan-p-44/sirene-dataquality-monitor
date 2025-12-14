-- sql/040_create_import_runs.sql
-- Historisation des imports SIRENE

create table if not exists public.sirene_import_runs (
  import_id bigserial primary key,
  imported_at timestamptz not null default now(),
  source_file text not null,
  row_count bigint not null,
  comment text
);

