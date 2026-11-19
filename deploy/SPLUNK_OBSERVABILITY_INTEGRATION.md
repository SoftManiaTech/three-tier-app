# Splunk Observability Cloud & OpenTelemetry Integration Guide

Comprehensive architecture, configuration, testing, and troubleshooting documentation for onboarding the **Three-Tier Product Application** into **Splunk Observability Cloud** using the **Splunk OpenTelemetry Collector**.

---

## 1. Architecture & Telemetry Pipeline

```
┌────────────────────────────────────────────────────────┐
│                   TIER 1: FRONTEND                     │
│  - Single-page application (HTML5/CSS3/Vanilla JS)     │
│  - Generates W3C traceparent headers (Trace ID)        │
│  - Captures UI actions & window errors                 │
│  - Dispatches client logs via POST /api/logs           │
└───────────────────────────┬────────────────────────────┘
                            │ HTTP (fetch with traceparent)
                            ▼
┌────────────────────────────────────────────────────────┐
│                   TIER 2: BACKEND                      │
│  - Flask Application (Python 3)                        │
│  - OpenTelemetry SDK & Auto-instrumentation            │
│  - TraceContextFilter: Binds trace_id & span_id to logs│
│  - LoggerProvider & OTLP LoggingHandler                │
│  - Serves static frontend from root (/)                │
└───────────────────────────┬────────────────────────────┘
                            │ SQL Queries & Audit Events
                            ▼
┌────────────────────────────────────────────────────────┐
│                   TIER 3: DATABASE                     │
│  - MySQL 8.0+ Primary Driver                           │
│  - Resilient SQLite Local Fallback (with seed data)    │
│  - DB Query Audit Logging (counts, latency, mutations) │
└───────────────────────────┬────────────────────────────┘
                            │ OTLP / HTTP (Port 4318)
                            ▼
┌────────────────────────────────────────────────────────┐
│          SPLUNK OPENTELEMETRY COLLECTOR (WINDOWS)      │
│  - Service: splunk-otel-collector (PID active)         │
│  - Receivers: OTLP HTTP (4318), OTLP gRPC (4317)       │
│  - Processors: memory_limiter, batch, resourcedetection│
│  - Exporters: otlp_http (APM), signalfx, splunk_hec    │
│  - Health Endpoint: http://127.0.0.1:13133/            │
│  - Internal Prometheus Metrics: http://127.0.0.1:8888/ │
└───────────────────────────┬────────────────────────────┘
                            │ Cloud Ingestion (Realm: au0)
                            ▼
┌────────────────────────────────────────────────────────┐
│               SPLUNK OBSERVABILITY CLOUD               │
│  - APM (Traces): https://app.au0.observability.../apm  │
│  - Metric Explorer: http.server.*, product.operations  │
│  - Log Observer Connect: Queries Splunk Platform Index │
└────────────────────────────────────────────────────────┘
```

---

## 2. Telemetry Implementation Details

### A. Frontend Distributed Tracing (`frontend/index.html`)
- **W3C `traceparent` Generation**: Each client fetch request creates a standard W3C header (`00-<trace_id>-<span_id>-01`).
- **Interactive UI Badge**: Displays the active `Trace ID` in the hero banner with a one-click copy button.
- **Client Log Shipping**: Dispatches client-side actions and errors to `POST /api/logs`:
  - Product added, updated, or deleted
  - Category filtered
  - Unhandled JavaScript runtime errors (`window.onerror`, `unhandledrejection`)

### B. Backend OpenTelemetry Instrumentation (`backend/telemetry.py`)
- **Tracing**: `TracerProvider` configured with `BatchSpanProcessor` and `OTLPSpanExporter` pointing to `/v1/traces`.
- **Metrics**: `MeterProvider` configured with `PeriodicExportingMetricReader` emitting:
  - `http.server.active_requests`
  - `http.server.duration_*`
  - `product.operations.total` (business counter grouped by `operation` and `status`)
- **Logging**: `LoggerProvider` configured with `BatchLogRecordProcessor` and `OTLPLogExporter` pointing to `/v1/logs`.
- **Trace-to-Log Correlation (`TraceContextFilter`)**: Automatically injects `trace_id` and `span_id` into every log record emitted by:
  - `app.logger` (HTTP request logs: method, path, status, duration)
  - `myapp.audit` (Database query events, row counts, entity mutations)
  - `frontend.audit` (Client browser events forwarded via `/api/logs`)

### C. Database Layer & Resilient Fallback (`backend/db.py`)
- Automatically probes MySQL (`127.0.0.1:3306`) with non-blocking socket verification.
- If MySQL is running, connects directly using `mysql-connector-python`.
- If MySQL is offline, automatically activates a local SQLite database (`backend/fallback.db`) seeded with sample products, ensuring complete zero-downtime operation and realistic CRUD query logging.

---

## 3. Configuration Reference

### Application Environment (`backend/.env`)

```ini
# Database Settings
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=appdb
DB_USER=appuser
DB_PASSWORD=admin123

# Server Settings
PORT=5000

# OpenTelemetry Configuration
OTEL_ENABLED=true
OTEL_SERVICE_NAME=three-tier-product-api
OTEL_SERVICE_VERSION=1.0.0
OTEL_ENVIRONMENT=production

# Local OpenTelemetry Collector Endpoint
OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318
```

### Windows OpenTelemetry Collector (`agent_config.yaml`)
Located at: `C:\ProgramData\Splunk\OpenTelemetry Collector\agent_config.yaml`

```yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318
      grpc:
        endpoint: 0.0.0.0:4317

processors:
  memory_limiter:
    check_interval: 1s
    limit_percentage: 75
    spike_limit_percentage: 20
  batch:
  resource_detection:

exporters:
  # Traces -> Splunk APM
  otlp_http:
    traces_endpoint: "${SPLUNK_INGEST_URL}/v2/trace/otlp"
    headers:
      "X-SF-Token": "${SPLUNK_ACCESS_TOKEN}"

  # Metrics -> Splunk Infrastructure / Metric Explorer
  signalfx:
    api_url: "${SPLUNK_API_URL}"
    ingest_url: "${SPLUNK_INGEST_URL}"
    sync_host_metadata: true

  # Logs -> Splunk Platform HEC
  splunk_hec:
    endpoint: "${SPLUNK_HEC_URL}"
    token: "${SPLUNK_HEC_TOKEN}"
    source: "otel"
    sourcetype: "otel"

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch, resource_detection]
      exporters: [otlp_http]
    metrics:
      receivers: [host_metrics, otlp]
      processors: [memory_limiter, batch, resource_detection]
      exporters: [signalfx]
    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch, resource_detection]
      exporters: [splunk_hec]
```

---

## 4. Navigating Splunk Observability Cloud

### Portal URL
👉 **`https://app.au0.observability.splunkcloud.com`** *(Realm: `au0`)*

### A. Metric Explorer
- **Navigation**: Left Navigation Menu → **Dashboards** → **Metric Explorer**
- **Filter**: Set `sf_service = three-tier-product-api`
- **Active Metrics**:
  - `http.server.active_requests` (Gauge)
  - `http.server.duration_bucket`, `count`, `max`, `min`, `sum` (Counter / Gauge)
  - `product.operations.total` (Custom Business Counter)
- **Tip**: Do not combine conflicting service filters with `AND` (e.g. `sf_service = app-a AND sf_service = app-b`), which produces 0 results.

### B. APM (Application Performance Monitoring)
- **Navigation**: Left Navigation Menu → **APM**
- **Service Selection**: Search or select **`three-tier-product-api`**
- **Environment**: `production`
- **Time Window**: Ensure the time window covers your test period (e.g., **`-4h`** or **`Today`**; default is `-15m`).
- **Traces**: Inspect operations:
  - `POST /api/products` (Product creation)
  - `GET /api/products` (Catalog retrieval)
  - `GET /api/categories` (Category list)
  - `POST /api/logs` (Frontend log forwarding)
  - `DELETE /api/products/<int:id>` (Product deletion)

### C. Understanding Log Observer & "Logs Connections"
- When opening **Log Observer**, the console displays:
  > *"Logs Connections: Query across your Splunk platform indexes without writing SPL. No integrations found."*
- **Why this happens**: Splunk Observability Cloud does not have internal storage for raw logs; it relies on **Log Observer Connect** to query an external **Splunk Enterprise** or **Splunk Cloud Platform** index.
- **Resolution**: An organization administrator must configure a connection under **"Add a new connection"** pointing to your company's Splunk Enterprise or Splunk Cloud Platform instance with valid HEC credentials.

---

## 5. Running & Verifying the Application Locally

### Step 1: Start the Backend Application
```powershell
cd backend
python app.py
```
*The server starts on `http://127.0.0.1:5000` and serves both the API and the frontend.*

### Step 2: Open the Frontend
Visit `http://127.0.0.1:5000/` in your browser.
1. Add a new product (e.g., *"Wireless Mechanical Keyboard"*).
2. Filter by category (e.g., *"Electronics"*).
3. Delete or update a product.

### Step 3: Verify Collector Ingestion via Internal Metrics
Query the collector's Prometheus metric port from PowerShell:
```powershell
python -c "import urllib.request; data = urllib.request.urlopen('http://127.0.0.1:8888/metrics').read().decode('utf-8'); print('\n'.join([l for l in data.splitlines() if 'sent_spans' in l or 'accepted_spans' in l]))"
```
**Expected Output:**
```text
otelcol_exporter_sent_spans{exporter="otlp_http",server_address="ingest.au0.observability.splunkcloud.com",url_path="/v2/trace/otlp"} 30
otelcol_receiver_accepted_spans{receiver="otlp",transport="http"} 30
```

### Step 4: Verify Collector Healthcheck
```powershell
curl http://127.0.0.1:13133/
```
**Expected Output:**
```json
{"status":"Server available","upSince":"...","uptime":"..."}
```

---

## 6. Troubleshooting Checklist

| Issue | Cause | Solution |
|---|---|---|
| **No server metrics in APM (-15m)** | Time window is too narrow and test occurred earlier | Change time picker to **`-4h`** or **`Today`**, or trigger fresh requests to `http://localhost:5000`. |
| **"No integrations found" in Logs** | Splunk Observability Cloud has no Log Observer Connect configured | Configure a connection to Splunk Enterprise / Splunk Cloud Platform in Observability Settings. |
| **404 on HEC endpoint** | `SPLUNK_HEC_URL` set to Observability Cloud ingest instead of Splunk Platform HEC | Update `SPLUNK_HEC_URL` to your Splunk Platform HEC URL (`https://<stack>.splunkcloud.com:8088/services/collector`). |
| **Port 5000 already in use** | An earlier process instance is running | Run `Get-NetTCPConnection -LocalPort 5000` and stop the old process PID. |
| **MySQL offline** | MySQL service not running on port 3306 | The app automatically uses the built-in SQLite fallback (`fallback.db`) with zero downtime. |
