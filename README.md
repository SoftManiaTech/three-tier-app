# Three-Tier Application

A three-server product catalog and inventory management application deployed on RHEL.

## Architecture
- **Tier 1 (Presentation)**: HTML5, CSS3, JavaScript (Apache HTTP Server)
- **Tier 2 (Application)**: Python 3, Flask, Gunicorn WSGI
- **Tier 3 (Database)**: MySQL 8.0+
- **Observability (o11y)**: Full-Stack OpenTelemetry (OTel) for distributed tracing, metrics, and logs

## Project Structure
- `frontend/` - Single-page web application with W3C distributed tracing
- `backend/` - Flask REST API, central config, and OpenTelemetry instrumentation
- `database/` - MySQL schema, seed data, and migration guidelines
- `deploy/` - Deployment configurations and instructions for RHEL servers
- `DECISIONS.md` - Architecture Decision Records (ADRs)

---

## Observability & Onboarding to Your o11y Portal

The application is fully instrumented with **OpenTelemetry (OTel)**, the vendor-neutral standard for observability. It exports traces and metrics using the standard **OTLP/HTTP protocol**.

### What Is Instrumented
1. **Frontend Distributed Tracing**: Generates W3C `traceparent` headers (`00-<trace_id>-<span_id>-01`) on every API request. When viewing a trace in your portal, you can follow the request from the browser directly into backend routes and database queries.
2. **Backend API Tracing**: Automatically records root spans for all Flask routes (method, status code, latency, route attributes).
3. **Database Query Tracing**: Automatically records child spans for every MySQL SQL statement executed by `mysql-connector-python`.
4. **Business Operations Metric**: Emits `product.operations.total` counter annotated with operation type (`create`, `update`, `delete`) and status (`success`, `failure`).
5. **Non-blocking Resiliency**: If your o11y portal or collector is temporarily unreachable, the application logs a warning and continues serving requests with zero downtime.

---

### Step-by-Step Portal Onboarding

#### Step 1: Install Dependencies
```bash
cd backend
pip install -r requirements.txt
```

#### Step 2: Configure Environment Variables
Copy `.env.example` to `.env` in `backend/`:
```bash
cp .env.example .env
```

Configure your portal's OTLP receiver endpoint:
```ini
# Enable or disable OpenTelemetry
OTEL_ENABLED=true

# Service Name as it will appear in your o11y portal
OTEL_SERVICE_NAME=three-tier-product-api
OTEL_SERVICE_VERSION=1.0.0
OTEL_ENVIRONMENT=production

# OTLP HTTP receiver endpoint of your o11y portal or OTel Collector
OTEL_EXPORTER_OTLP_ENDPOINT=http://<your-o11y-collector-host>:4318
```

#### Step 3: Connecting to Common o11y Platforms

- **Local OpenTelemetry Collector**:
  ```ini
  OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318
  ```
- **SigNoz (Self-Hosted or Cloud)**:
  ```ini
  OTEL_EXPORTER_OTLP_ENDPOINT=http://<signoz-ip>:4318
  ```
- **Grafana (Tempo for Traces, Mimir for Metrics via Alloy / OTel Collector)**:
  ```ini
  OTEL_EXPORTER_OTLP_ENDPOINT=http://<grafana-alloy-ip>:4318
  ```
- **Datadog (via Datadog Agent with OTLP enabled)**:
  Ensure `otlp_config.receiver.protocols.http.endpoint: 0.0.0.0:4318` is enabled in `datadog.yaml`:
  ```ini
  OTEL_EXPORTER_OTLP_ENDPOINT=http://<datadog-agent-ip>:4318
  ```
- **Dynatrace / New Relic / Honeycomb**:
  Send to an OpenTelemetry Collector gateway on your network, or set the vendor's direct OTLP HTTP endpoint.

---

### Running the Application

#### Start Backend
```bash
cd backend
python app.py
```
Or via Gunicorn:
```bash
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

#### Start Frontend
Serve `frontend/index.html` via Apache HTTP Server on RHEL or any static HTTP server:
```bash
# Example test server:
python -m http.server 8080 --directory frontend
```

---

## Deployment
Deployment is performed to each RHEL server:
- Do not commit production credentials, private keys, or `.env` files to git.
- Set `OTEL_ENABLED=true` on the application server and verify network connectivity on port `4318` to your observability collector.
