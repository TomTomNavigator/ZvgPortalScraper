FROM python:3.13-slim-bookworm

# app.py calls locale.setlocale(LC_ALL, "de_DE"), so the German locale must
# exist in the image. Uncomment both the bare "de_DE" (ISO-8859-1) variant
# resolved by that call and the UTF-8 variant used by LANG/LC_ALL below.
RUN apt-get update \
    && apt-get install -y --no-install-recommends locales \
    && sed -i 's/^# *de_DE ISO-8859-1/de_DE ISO-8859-1/; s/^# *de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=de_DE.UTF-8 \
    LC_ALL=de_DE.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    RAW_DATA_DIRECTORY=/data/raw

WORKDIR /app

# Install runtime deps first so the layer is cached when only source changes.
COPY requirements.txt ./
RUN pip install -r requirements.txt

# Copy only the application package; everything else is excluded via .dockerignore.
COPY zvg_portal ./zvg_portal

# Run as an unprivileged user and own the data volume.
RUN useradd --create-home --uid 1000 scraper \
    && mkdir -p /data/raw \
    && chown -R scraper:scraper /data/raw /app

USER scraper

VOLUME ["/data/raw"]

ENTRYPOINT ["python", "-m", "zvg_portal.app"]
