import pandas as pd
from pathlib import Path

IN_PATH = Path("data/raw/StockEtablissement_utf8.csv")
OUT_PATH = Path("data/processed/sirene_44.csv")

# Colonnes minimales utiles (tu pourras en ajouter ensuite)
USECOLS = [
    "siret",
    "siren",
    "nic",
    "denominationUniteLegale",
    "etatAdministratifEtablissement",
    "dateCreationEtablissement",
    "activitePrincipaleEtablissement",
    "libelleCommuneEtablissement",
    "codePostalEtablissement",
    "codeCommuneEtablissement",
    "codeDepartementEtablissement",
]

CHUNKSIZE = 100_000

def main():
    if not IN_PATH.exists():
        raise FileNotFoundError(f"Fichier introuvable: {IN_PATH}")

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    # On écrase si existant (re-run propre)
    if OUT_PATH.exists():
        OUT_PATH.unlink()

    wrote_header = False
    total_rows_out = 0

    for chunk in pd.read_csv(
        IN_PATH,
        sep=",",
        encoding="utf-8",
        dtype=str,
        usecols=lambda c: c in USECOLS,
        chunksize=CHUNKSIZE,
        low_memory=True,
    ):
        # Filtre département 44
        # (on cast en str et on gère NaN avec fillna)
        
        col = "codePostalEtablissement"

        if col not in chunk.columns:
            raise KeyError(f"Colonne manquante: {col}. Colonnes dispo: {list(chunk.columns)}")

        # Dept 44 = codes postaux qui commencent par "44"
        cp = chunk[col].fillna("").astype(str).str.strip()
        filtered = chunk[cp.str.startswith("44")]

        if not filtered.empty:
            filtered.to_csv(
                OUT_PATH,
                mode="a",
                index=False,
                header=not wrote_header,
                encoding="utf-8",
            )
            wrote_header = True
            total_rows_out += len(filtered)

    print(f"✅ Terminé. Lignes exportées (44): {total_rows_out}")
    print(f"📄 Fichier créé: {OUT_PATH}")

if __name__ == "__main__":
    main()

