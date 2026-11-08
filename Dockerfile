FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Correctifs de sécurité Debian (ex. zlib) appliqués au build
RUN apt-get update \
 && apt-get upgrade -y --no-install-recommends \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .

# Installe les dépendances puis retire pip/setuptools : inutiles à l'exécution
# (réduit la surface d'attaque ; pip embarque une vieille copie de setuptools)
RUN pip install --no-cache-dir -r requirements.txt \
 && pip uninstall -y pip setuptools \
 && rm -rf /usr/local/lib/python3.12/ensurepip

COPY . .

# Fichiers statiques collectés au build, servis par WhiteNoise (DEBUG=False)
RUN SECRET_KEY=build-only python manage.py collectstatic --noinput

EXPOSE 8000

# Serveur d'application de production (au lieu du serveur de développement runserver)
CMD ["gunicorn", "gestion_formation.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "2", "--timeout", "60", "--access-logfile", "-"]
