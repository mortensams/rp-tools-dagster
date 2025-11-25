# Dagster container image with SQL Server, dlt, and git sync support
# Based on: https://docs.dagster.io/deployment/oss/deployment-options/kubernetes/deploying-to-kubernetes

FROM python:3.11-slim

# Ensure logs are displayed immediately
ENV PYTHONUNBUFFERED=1

# Install system dependencies for SQL Server (ODBC), git, and general build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build essentials
    build-essential \
    gcc \
    g++ \
    # Git for git sync functionality
    git \
    openssh-client \
    # SQL Server ODBC driver dependencies
    curl \
    gnupg2 \
    apt-transport-https \
    unixodbc \
    unixodbc-dev \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# Install Microsoft ODBC Driver 18 for SQL Server
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && curl -fsSL https://packages.microsoft.com/config/debian/12/prod.list | tee /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for better layer caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code (if any exists)
COPY . .

# Expose port for Dagster gRPC and webserver
EXPOSE 80 4000

# Default command - can be overridden by Kubernetes/Helm
CMD ["dagster", "api", "grpc", "-h", "0.0.0.0", "-p", "4000"]
