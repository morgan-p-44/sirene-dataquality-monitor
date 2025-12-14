-- sql/020_view_v_sirene_44_analytics.sql
-- Vue analytics typée à partir de v_sirene_44

create or replace view public.v_sirene_44_analytics as
select
  -- Identifiants
  siret,
  siren,
  nic,

  -- Dates
  case
    when date_creation_etablissement ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
    then date_creation_etablissement::date
    else null
  end as date_creation_etablissement,

  -- Statut administratif
  etat_administratif_etablissement,
  case
    when etat_administratif_etablissement = 'A' then true
    when etat_administratif_etablissement = 'F' then false
    else null
  end as is_actif,

  -- Localisation
  code_postal_etablissement,
  substring(code_postal_etablissement from 1 for 2) as departement,
  code_commune_etablissement,
  libelle_commune_etablissement,

  -- Activité
  activite_principale_etablissement,

  -- Qualité calculée
  case
    when siret ~ '^[0-9]{14}$' then true
    else false
  end as is_siret_valid

from public.v_sirene_44;

