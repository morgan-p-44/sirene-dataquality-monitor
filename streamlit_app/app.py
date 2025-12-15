import streamlit as st
import pandas as pd
from db import read_df

st.set_page_config(page_title="SIRENE 44 – DQ Monitor", layout="wide")
st.title("📊 SIRENE 44 – Data Quality Monitor")

# -----------------------------
# Helpers
# -----------------------------
def status_style(val: str) -> str:
    if val == "OK":
        return "background-color: #16a34a; color: white; font-weight: 700;"
    if val == "KO":
        return "background-color: #dc2626; color: white; font-weight: 700;"
    return ""

@st.cache_data(ttl=300)
def load_imports() -> pd.DataFrame:
    return read_df("""
        select import_id, imported_at, source_file, row_count
        from public.sirene_import_runs
        order by imported_at desc
    """)

@st.cache_data(ttl=300)
def load_dq_for_import(import_id: int) -> pd.DataFrame:
    return read_df("""
        select
          import_id, imported_at, source_file, row_count,
          rule_code, rule_label, metric_value, threshold, status, dq_run_at
        from public.v_dq_by_import
        where import_id = :import_id
        order by rule_code
    """, {"import_id": import_id})

@st.cache_data(ttl=300)
def load_rule_history(rule_code: str) -> pd.DataFrame:
    return read_df("""
        select
          imported_at::date as import_date,
          metric_value,
          threshold,
          status
        from public.v_dq_by_import
        where rule_code = :rule_code
        order by imported_at
    """, {"rule_code": rule_code})


# -----------------------------
# Data loading
# -----------------------------
imports = load_imports()

if imports.empty:
    st.warning("Aucun import trouvé dans `public.sirene_import_runs`.")
    st.stop()

# -----------------------------
# Sidebar controls
# -----------------------------
with st.sidebar:
    st.header("Sélection")

    options = [
        f"#{row.import_id} — {str(row.imported_at)[:19]} — {row.row_count} lignes"
        for row in imports.itertuples(index=False)
    ]
    selected = st.selectbox("Import", options, index=0)
    selected_import_id = int(selected.split("—")[0].strip().replace("#", ""))

    st.divider()
    show_ko_only = st.checkbox("Afficher uniquement les KO", value=False)

dq = load_dq_for_import(selected_import_id)

if dq.empty:
    st.warning("Aucun résultat DQ trouvé pour cet import (vérifie `dq_results` et `v_dq_by_import`).")
    st.stop()

# Optionnel: filtre KO only
dq_display = dq.copy()
if show_ko_only:
    dq_display = dq_display[dq_display["status"] == "KO"]

# -----------------------------
# KPIs
# -----------------------------
nb_rules_total = len(dq)
nb_ko_total = int((dq["status"] == "KO").sum())

imported_at = str(dq["imported_at"].iloc[0])[:19]
row_count = int(dq["row_count"].iloc[0]) if "row_count" in dq.columns else None

c1, c2, c3, c4, c5 = st.columns(5)
c1.metric("Import", f"#{selected_import_id}")
c2.metric("Imported at", imported_at)
if row_count is not None:
    c3.metric("Rows", f"{row_count:,}".replace(",", " "))
else:
    c3.metric("Rows", "n/a")
c4.metric("Rules", nb_rules_total)
c5.metric("KO", nb_ko_total)

# Badge global
if nb_ko_total == 0:
    st.success("✅ Qualité OK (aucune règle KO)")
else:
    st.error(f"❌ Qualité KO ({nb_ko_total} règle(s) KO)")

st.divider()

# -----------------------------
# Table (styled)
# -----------------------------
st.subheader("📋 Résultats par règle")

cols = ["rule_code", "rule_label", "metric_value", "threshold", "status"]
table_df = dq_display[cols].copy()

if table_df.empty and show_ko_only:
    st.info("Aucune règle KO pour cet import 🎉")
else:
    styled = table_df.style.applymap(status_style, subset=["status"])
    st.dataframe(styled, use_container_width=True)

st.divider()

# -----------------------------
# Rule history
# -----------------------------
st.subheader("📈 Historique d’une règle")

rule_choices = sorted(dq["rule_code"].dropna().unique().tolist())
rule = st.selectbox("Règle", rule_choices, index=0)

hist = load_rule_history(rule)

if hist.empty:
    st.info("Pas d’historique pour cette règle.")
else:
    # Courbe metric_value vs threshold
    chart_df = hist.set_index("import_date")[["metric_value", "threshold"]]
    st.line_chart(chart_df)

    # Table détaillée
    st.dataframe(hist, use_container_width=True)
