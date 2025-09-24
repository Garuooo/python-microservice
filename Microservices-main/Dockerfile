# syntax=docker/dockerfile:1

FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies (if needed in future)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency manifests first for better build caching
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy application code
COPY app/ /app/app/
COPY run.py /app/run.py

# Accept version at build-time and expose it
ARG VERSION="v0.0.0"
ENV APP_VERSION=${VERSION}
LABEL org.opencontainers.image.version=${VERSION}

EXPOSE 5000

CMD ["python", "/app/run.py"]
