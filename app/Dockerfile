# Multi-stage build for smaller, more secure production images
# Stage 1: Builder - Install dependencies
FROM python:3.11-slim as builder

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
# Docker caches layers, so if requirements don't change, this layer is reused
COPY requirements.txt .

# Install dependencies to /install directory
# --no-cache-dir reduces image size by not storing pip cache
# --prefix=/install installs packages to a custom location for copying to final stage
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Production - Create minimal runtime image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy installed dependencies from builder stage
# This keeps the final image smaller by excluding build tools
COPY --from=builder /install /usr/local

# Copy application code
COPY main.py .

# Create a non-root user for security
# Running as root is a security risk; create 'appuser' with limited privileges
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port 8080 (Cloud Run default)
# This is documentation; Cloud Run automatically routes to this port
EXPOSE 8080

# Set environment variables
# These can be overridden at runtime
ENV PORT=8080
ENV VERSION=1.0.0
ENV ENVIRONMENT=production

# Health check for container orchestrators
# Cloud Run uses this to determine if the container is healthy
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

# Use Gunicorn as production WSGI server
# --bind 0.0.0.0:$PORT - Listen on all interfaces
# --workers 1 - Single worker is fine for Cloud Run (each instance handles one request)
# --threads 8 - Handle multiple concurrent requests within the worker
# --timeout 0 - Disable worker timeout (Cloud Run handles this)
# --access-logfile - - Log to stdout for Cloud Logging
CMD exec gunicorn --bind 0.0.0.0:$PORT --workers 1 --threads 8 --timeout 0 --access-logfile - --error-logfile - main:app
