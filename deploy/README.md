# Deployment Documentation

This directory contains deployment guides, configurations, and observability setup instructions for the Three-Tier Application.

## Documentation Index

- **[OTEL_COLLECTOR_UBUNTU_WSL.md](OTEL_COLLECTOR_UBUNTU_WSL.md)**: Complete step-by-step installation, configuration (`config.yaml`), and verification guide for running the **OpenTelemetry Collector Contrib** on Ubuntu / WSL.
- **Three-Tier Multi-Server Architecture**:
  - **Tier 1 (Presentation)**: Apache HTTP Server serving `frontend/index.html`.
  - **Tier 2 (Application)**: Gunicorn WSGI running Python Flask (`backend/app.py`).
  - **Tier 3 (Database)**: MySQL 8.0 server (`database/schema.sql`).
  - **Observability**: OpenTelemetry Collector gateway forwarding traces, metrics, and logs to your monitoring portal.
