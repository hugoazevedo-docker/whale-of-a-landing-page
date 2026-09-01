# syntax=docker/dockerfile:1

# ---- build stage -----------------------------------------------------------
# The -dev variant has apt/bash and runs as root, so it can install packages.
FROM dhi.io/python:3.12-debian13-dev AS build

WORKDIR /app

COPY requirements.txt .
RUN python3 -m pip install --no-cache-dir --no-compile \
    --target=/usr/lib/python3.12/site-packages -r requirements.txt

COPY app.py .
COPY templates/ templates/
COPY static/ static/

# ---- runtime stage ----------------------------------------------------------
# The non-dev variant has no shell or package manager and runs as UID 65532
# (nonroot) by default, so only artifacts built above are copied in.
FROM dhi.io/python:3.12-debian13 AS runtime

WORKDIR /app

COPY --from=build /usr/lib/python3.12/site-packages /usr/lib/python3.12/site-packages
COPY --from=build /app /app

EXPOSE 8000

CMD ["python3", "-m", "gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "app:app"]
