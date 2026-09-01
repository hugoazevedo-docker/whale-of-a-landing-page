# syntax=docker/dockerfile:1

# ---- build stage -----------------------------------------------------------
# The -dev variant has apt/bash and runs as root, so it can install packages.
FROM python:3.12-slim AS build

WORKDIR /app

COPY requirements.txt .
RUN python3 -m pip install --no-cache-dir --prefix=/install -r requirements.txt

COPY app.py .
COPY templates/ templates/
COPY static/ static/

# ---- runtime stage ----------------------------------------------------------
# The non-dev variant has no shell or package manager and runs as UID 65532
# (nonroot) by default, so only artifacts built above are copied in.
FROM dhi.io/python:3.12-debian13 AS runtime

WORKDIR /app

COPY --from=build /install /usr/local
COPY --from=build --chown=65532:65532 /app /app

ENV PYTHONPATH=/usr/local/lib/python3.12/site-packages

EXPOSE 8000

CMD ["python3", "-m", "gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "app:app"]