# ---- base image ----
FROM python:3.11-slim

# Prevent .pyc files & buffer
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# System deps then Python deps
RUN apt-get update -y `
 && apt-get install --no-install-recommends -y gcc `
 && pip install --upgrade pip `
 && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy source
COPY . .

# Start with Gunicorn
CMD ["gunicorn", "-b", "0.0.0.0:5000", "app:app"]
