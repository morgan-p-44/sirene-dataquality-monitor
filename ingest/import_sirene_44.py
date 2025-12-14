import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

DATABASE_URL = os.environ["DATABASE_URL"]
CSV_PATH = os.environ.get("SIRENE_44_CSV", "data/processed/sirene_44.csv")
TABLE_NAME = os.environ.get("TABLE_NAME", "sirene_etab_44")

# colonnes = celles que tu as listées avec pandas (mêmes noms, mais en minuscules si besoin)
COLUMNS = [
    "siren","nic","siret","statutdiffusionetablissement","datecreationetablissement",
    "trancheeffectifsetablissement","anneeeffectifsetablissement",
    "activiteprincipaleregistremetiersetablissement","datederniertraitementetablissement",
    "etablissementsiege","nombreperiodeetablissement","complementadresseetablissement",
    "numerovoieetablissement","indicerepetitionetablissement","derniernumerovoieetablissement",
    "indicerepetitionderniernumerovoieetablissement","typevoieetablissement","libellevoieetablissement",
    "codepostaletablissement","libellecommuneetablissement","libellecommuneetrangeretablissement",
    "distributionspecialeetablissement","codecommuneetablissement","codecedexetablissement",
    "libellecedexetablissement","codepaysetrangeretablissement","libellepaysetrangeretablissement",
    "identifiantadresseetablissement","coordonneelambertabscisseetablissement",
    "coordonneelambertordonneeetablissement","complementadresse2etablissement",
    "numerovoie2etablissement","indicerepetition2etablissement","typevoie2etablissement",
    "libellevoie2etablissement","codepostal2etablissement","libellecommune2etablissement",
    "libellecommuneetranger2etablissement","distributionspeciale2etablissement","codecommune2etablissement",
    "codecedex2etablissement","libellecedex2etablissement","codepaysetranger2etablissement",
    "libellepaysetranger2etablissement","datedebut","etatadministratifetablissement",
    "enseigne1etablissement","enseigne2etablissement","enseigne3etablissement",
    "denominationusuelleetablissement","activiteprincipaleetablissement",
    "nomenclatureactiviteprincipaleetablissement","caractereemployeuretablissement"
]

def main():
    if not os.path.exists(CSV_PATH):
        raise FileNotFoundError(f"CSV introuvable: {CSV_PATH}")

    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = True

    with conn.cursor() as cur:
        # 1) table en TEXT
        cols_sql = ",\n  ".join([f"{c} text" for c in COLUMNS])
        cur.execute(f'create table if not exists public.{TABLE_NAME} (\n  {cols_sql}\n);')

        # 2) import COPY (on saute l'en-tête)
        copy_sql = f"""
        copy public.{TABLE_NAME} ({", ".join(COLUMNS)})
        from stdin with (format csv, header true, delimiter ',', quote '"');
        """

        with open(CSV_PATH, "r", encoding="utf-8") as f:
            cur.copy_expert(copy_sql, f)

        # 3) vérif
        cur.execute(f"select count(*) from public.{TABLE_NAME};")
        count = cur.fetchone()[0]
        print(f"✅ Import terminé. Lignes en base: {count}")

    conn.close()

if __name__ == "__main__":
    main()

