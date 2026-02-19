FROM python:3.11-slim

WORKDIR /code

# Kopiere die Abhängigkeiten und installiere sie
COPY ./requirements.txt /code/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# Kopiere den Code
COPY . /code/app

# Starte FastAPI
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]