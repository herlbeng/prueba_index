# Usa una imagen base de Python oficial
FROM python:3.10-slim

# Establece el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copia los archivos de requerimientos e instala las dependencias
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copia tu aplicación Streamlit al contenedor
COPY main_index.py .

# Exponer el puerto por defecto de Streamlit (8501)
EXPOSE 8501

# Definir la variable de entorno que necesita Streamlit
ENV STREAMLIT_SERVER_PORT=8501

# Comando para correr la aplicación Streamlit cuando se inicie el contenedor
CMD ["streamlit", "run", "main_index.py", "--server.port", "8501", "--server.enableCORS", "false", "--server.enableXsrfProtection", "false"]