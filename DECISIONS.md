# Architectural Decisions Log (DECISIONS.md)

## 001: Three-Tier Architecture Layout
- **Date**: 2026-10-27
- **Context**: Standard enterprise pattern separating Presentation (Web), Application (API), and Data (MySQL).
- **Decision**: Frontend served via Apache HTTP Server, Backend on Flask/Gunicorn, Data stored in MySQL.
- **Consequences**: Enables independent scaling, firewall isolation between tiers, and modular deployment.

---

## 002: Full-Stack Observability with OpenTelemetry (OTel)
- **Date**: 2026-11-17
- **Status**: Approved
- **Context**: Need to onboard the three-tier application onto an observability portal (e.g., Grafana, SigNoz, Datadog, Dynatrace, New Relic) for end-to-end tracing, metrics, and error diagnostics across Web, API, and DB tiers.
- **Decision**:
  1. Use **OpenTelemetry (OTel)** as the vendor-neutral standard for traces and metrics via OTLP (OpenTelemetry Protocol).
  2. Implement an **Explicit Telemetry Module** (`backend/telemetry.py`) rather than CLI auto-wrapping (`opentelemetry-instrument`) to ensure deterministic behavior under Gunicorn pre-fork worker models on RHEL and allow graceful fallback when the collector is offline.
  3. Instrument Flask API routes, MySQL queries, and custom business operations counters.
  4. Implement **W3C `traceparent` context propagation** in the frontend client to link browser user actions directly to backend traces.
  5. Adhere to Zero Hardcoded Variables (SSOT): All telemetry service names, endpoints, and toggles are managed through environment variables (`OTEL_ENABLED`, `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`).
- **Consequences**:
  - The application is decoupled from any specific observability vendor; points to any standard OTel receiver via `OTEL_EXPORTER_OTLP_ENDPOINT`.
  - Non-blocking: If the collector is offline or `OTEL_ENABLED=false`, the application operates with zero performance degradation or crash risk.
