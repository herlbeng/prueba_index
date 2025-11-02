import streamlit as st
from google.cloud import bigquery
import pandas as pd

# ----------------- CONFIGURACIÓN Y CLIENTE BQ -----------------

# Inicializa el cliente de BigQuery
# Cloud Run usará automáticamente las credenciales de la Cuenta de Servicio (IAM)
@st.cache_resource
def get_bq_client():
    return bigquery.Client()

# Carga los datos del índice y los almacena en caché (10 minutos)
@st.cache_data(ttl=600) 
def load_index_data():
    client = get_bq_client()
    
    # Consulta que une el índice de trabajos con las categorías
    query = """
    SELECT
        t1.work_name,
        t1.short_description,
        t1.image_preview_url,
        t1.work_url, 
        t2.category_name,
        t1.created_date
    FROM
        `platform-partners-des.settings.works_index` AS t1
    INNER JOIN
        `platform-partners-des.settings.works_categories` AS t2
    ON
        t1.category = t2.category_id
    WHERE
        t1.status = 'ACTIVE' AND t1.is_latest = TRUE
    ORDER BY
        t1.created_date DESC
    """
    
    try:
        query_job = client.query(query)
        return query_job.to_dataframe()
    except Exception as e:
        st.error(f"Error al cargar datos de BigQuery: {e}")
        return pd.DataFrame() 

# ----------------- DISEÑO DE LA PÁGINA STREAMLIT -----------------

st.set_page_config(
    layout="wide", 
    page_title="DS Internal Works Index", 
    menu_items={'About': 'Portal interno para trabajos de Ciencia de Datos.'}
)

st.title("🔬 Catálogo Interno de Trabajos de Data Science")
st.markdown("Consulta y accede a las últimas aplicaciones de **Streamlit** desarrolladas en el equipo.")

index_df = load_index_data()

if not index_df.empty:
    for index, row in index_df.iterrows():
        col1, col2 = st.columns([1, 4]) # Una columna para imagen, otra para texto
        
        with col1:
            # Muestra la imagen, si existe
            if row['image_preview_url']:
                st.image(row['image_preview_url'], width=150)
            
        with col2:
            st.header(f"{row['work_name']}")
            # Formateamos la fecha para que se vea más limpia
            date_str = row['created_date'].strftime('%Y-%m-%d') if pd.notna(row['created_date']) else 'Fecha desconocida'
            st.caption(f"Categoría: **{row['category_name']}** | Publicado: {date_str}")
            st.markdown(f"{row['short_description']}")
            
            # Botón/Enlace de redirección (usando el campo work_url de BQ)
            if row['work_url']:
                st.link_button("Ir al Servicio Cloud Run 🚀", row['work_url'])
            else:
                st.info("URL no disponible.")
                
        st.divider()
else:
    st.warning("No se encontraron trabajos 'ACTIVOS' o 'LATEST' en el índice.")