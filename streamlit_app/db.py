import os
import pandas as pd
import streamlit as st

from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()  # local only: lit un fichier .env si présent

@st.cache_resource
def get_engine():
    """
    Streamlit Cloud: DATABASE_URL est dans st.secrets
    Local: DATABASE_URL dans env ou .env
    """
    db_url = st.secrets.get("DATABASE_URL") or os.getenv("DATABASE_URL")

    if not db_url:
        raise RuntimeError(
            "DATABASE_URL manquant.\n"
            "- Streamlit Cloud: App Settings → Secrets → DATABASE_URL\n"
            "- Local: export DATABASE_URL=... ou fichier .env"
        )

    # pool_pre_ping évite des connexions cassées après sleep
    return create_engine(db_url, pool_pre_ping=True)

def read_df(query: str, params: dict | None = None) -> pd.DataFrame:
    engine = get_engine()
    with engine.connect() as conn:
        return pd.read_sql(text(query), conn, params=params or {})
