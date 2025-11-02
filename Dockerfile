# Usa una imagen base de Python oficial
FROM python:3.10-slim

# Establece el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copia los archivos de requerimientos e instala las dependencias
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copia tu aplicación Streamlit al contenedor
COPY main_index.py .

# Exponer el puerto que usará Cloud Run
EXPOSE 8080

# Configuración por defecto para ejecución local y Cloud Run
ENV PORT=8080
ENV STREAMLIT_SERVER_HEADLESS=true

# Comando para correr la aplicación Streamlit cuando se inicie el contenedor
CMD ["sh", "-c", "streamlit run main_index.py --server.address 0.0.0.0 --server.port ${PORT:-8080} --server.enableCORS false --server.enableXsrfProtection false"]