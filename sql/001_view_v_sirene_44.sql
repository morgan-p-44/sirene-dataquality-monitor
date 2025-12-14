-- sql/001_view_v_sirene_44.sql
-- Vue "clean" : colonnes snake_case + normalisation (trim + empty -> NULL)
-- Source : public.sirene_44 (colonnes CSV avec majuscules / guillemets)

create or replace view public.v_sirene_44 as
select
  nullif(trim("siret"), '')                           as siret,
  nullif(trim("siren"), '')                           as siren,
  nullif(trim("nic"), '')                             as nic,
  nullif(trim("dateCreationEtablissement"), '')       as date_creation_etablissement,
  nullif(trim("etatAdministratifEtablissement"), '')  as etat_administratif_etablissement,
  nullif(trim("codePostalEtablissement"), '')         as code_postal_etablissement,
  nullif(trim("libelleCommuneEtablissement"), '')     as libelle_commune_etablissement,
  nullif(trim("codeCommuneEtablissement"), '')        as code_commune_etablissement,
  nullif(trim("activitePrincipaleEtablissement"), '') as activite_principale_etablissement
from public.sirene_44;

