# OpenTelemetry (OTel) Collector Setup Guide for Ubuntu / WSL

This guide provides step-by-step instructions for installing, configuring, running, and verifying the **OpenTelemetry Collector Contrib** on an Ubuntu server running inside Windows Subsystem for Linux (WSL).

---

## 1. Prerequisites

1. Launch your Ubuntu distribution inside WSL:
   ```powershell
   wsl -d Ubuntu
   ```
2. Verify you have network access and `curl`/`wget` installed:
   ```bash
   sudo apt-get update && sudo apt-get install -y curl wget tar
   ```

---

## 2. Installation on Ubuntu / WSL

We recommend the **`otelcol-contrib`** distribution because it includes all standard receivers, processors, and exporters (including the `debug` exporter for terminal logging).

### Method A: Install via Official Debian Package (.deb) — Recommended

```bash
# 1. Set the latest stable version
OTEL_VERSION="0.165.0"

# 2. Download the .deb package
wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_linux_amd64.deb

# 3. Install the package
sudo dpkg -i otelcol-contrib_${OTEL_VERSION}_linux_amd64.deb

# 4. Verify installation
otelcol-contrib --version
```

### Method B: Install via Tarball Binary (No Root Package Manager)

```bash
OTEL_VERSION="0.165.0"
wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_linux_amd64.tar.gz
tar -xzf otelcol-contrib_${OTEL_VERSION}_linux_amd64.tar.gz
sudo mv otelcol-contrib /usr/local/bin/
otelcol-contrib --version
```

---

## 3. Configuration (`config.yaml`)

Create or update the configuration file at `/etc/otelcol-contrib/config.yaml`:

```bash
sudo mkdir -p /etc/otelcol-contrib
sudo nano /etc/otelcol-contrib/config.yaml
```

Paste the following configuration:

```yaml
# /etc/otelcol-contrib/config.yaml
receivers:
  otlp:
    protocols:
      http:
        # Listens on all interfaces on port 4318 (HTTP/JSON/Protobuf)
        endpoint: 0.0.0.0:4318
      grpc:
        # Listens on port 4317 (gRPC)
        endpoint: 0.0.0.0:4317

processors:
  # Batches traces and metrics for efficient processing
  batch:
    timeout: 1s
    send_batch_size: 64

  # Prevents out-of-memory errors by shedding load if RAM exceeds threshold
  memory_limiter:
    check_interval: 1s
    limit_percentage: 75
    spike_limit_percentage: 20

exporters:
  # Debug exporter prints all received traces, metrics, and logs in human-readable format
  debug:
    verbosity: detailed

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [debug]

    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [debug]

    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [debug]

  telemetry:
    logs:
      level: info
    metrics:
      level: none
```

---

## 4. Running the OpenTelemetry Collector

### Option 1: Running Interactively in Terminal (Best for First-Time Testing)
Run the binary directly to see live traces print to your terminal:
```bash
otelcol-contrib --config /etc/otelcol-contrib/config.yaml
```
You will see:
```text
info  otlpreceiver/otlp.go:197  Starting HTTP server  {"endpoint": "[::]:4318"}
info  service/service.go:256    Everything is ready. Begin running and processing data.
```

### Option 2: Running as a Background System Service (systemd)
If systemd is enabled in your WSL distribution:
```bash
# Enable and start the service
sudo systemctl enable otelcol-contrib
sudo systemctl start otelcol-contrib

# Check service status
sudo systemctl status otelcol-contrib

# Watch live incoming data logs
sudo journalctl -u otelcol-contrib -f
```

---

## 5. Connecting the Application to the WSL Collector

WSL2 automatically shares the `localhost` network with Windows.

1. In your `backend/.env` file:
   ```ini
   OTEL_ENABLED=true
   OTEL_SERVICE_NAME=three-tier-product-api
   OTEL_ENVIRONMENT=development
   OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318
   ```
2. If you are running across physical machines or custom WSL virtual switches, get your WSL IP:
   ```bash
   hostname -I | awk '{print $1}'
   ```
   And set:
   ```ini
   OTEL_EXPORTER_OTLP_ENDPOINT=http://<wsl-ip>:4318
   ```

---

## 6. Verification Steps: Proving Data Arrives

### Test 1: Healthcheck the OTLP Port
From Windows PowerShell or within WSL:
```bash
curl -X POST http://127.0.0.1:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{"resourceSpans":[]}'
```
**Expected Response**:
```json
{"partialSuccess":{}}
```
HTTP status `200 OK` confirms port 4318 is listening and actively receiving OTLP data.

### Test 2: Trigger an Application Request
Run a test request through your Flask API:
```bash
cd backend
python app.py
```
Open a second terminal or browser to `http://localhost:5000/api/products`.
In your WSL collector terminal or `journalctl -u otelcol-contrib -f`, you will immediately see:
```text
Trace ID: <32-hex-trace-id>
Span ID:  <16-hex-span-id>
Name:     GET /api/products
Status:   OK
Attributes:
  -> http.method: GET
  -> http.route: /api/products
  -> http.status_code: 200
```
This confirms that data is arriving end-to-end!

---

## 7. Splunk Observability Cloud Configuration

When forwarding telemetry from the OpenTelemetry Collector directly to **Splunk Observability Cloud**, the following details are required:

| Parameter | Description | Example Value |
|---|---|---|
| `SPLUNK_REALM` | The Splunk region/realm hosting your account | `au0`, `us0`, `us1`, `eu0` |
| `SPLUNK_HEC_TOKEN` | HTTP Event Collector token for log ingestion | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `SPLUNK_ACCESS_TOKEN` | Splunk Observability Org Access token for traces/metrics | `xxxxxxxxxxxxxxxxxxxxxx` |
| `SPLUNK_HEC_URL` | HEC log ingestion endpoint URL | `https://ingest.<SPLUNK_REALM>.observability.splunkcloud.com/v1/log` |

### Production Splunk `config.yaml` (WSL / Ubuntu)

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
    timeout: 1s
    send_batch_size: 64
  resourcedetection:
    detectors: [system]

exporters:
  # 1. Logs exporter to Splunk Observability Cloud
  splunk_hec:
    token: "${SPLUNK_HEC_TOKEN}"
    endpoint: "https://ingest.${SPLUNK_REALM}.observability.splunkcloud.com/v1/log"
    source: "otel"
    sourcetype: "otel"
    profiling_data_enabled: false

  # 2. Traces exporter to Splunk Observability Cloud
  otlp_http/splunk:
    endpoint: "https://ingest.${SPLUNK_REALM}.observability.splunkcloud.com/v2/trace/otlp"
    headers:
      "X-SF-Token": "${SPLUNK_ACCESS_TOKEN}"

  # 3. Optional local debug output in terminal
  debug:
    verbosity: basic

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch, resourcedetection]
      exporters: [otlp_http/splunk, debug]

    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch, resourcedetection]
      exporters: [splunk_hec, debug]
```

