# Observability Stack (LGTM)

This cluster implements the full centralized observability stack based on the **LGTM** (Loki, Grafana, Tempo, Prometheus/Mimir) pattern. Everything is installed via official community Helm charts managed by ArgoCD.

## Components

### 1. Prometheus
Deployed via the `kube-prometheus-stack` chart. It automatically scrapes applications that use the `prometheus.io/scrape: "true"` annotation or expose `ServiceMonitor` definitions.
- **Role**: Metrics aggregation.
- **Scrape Interval**: 15s

### 2. Grafana
Deployed alongside Prometheus via the `kube-prometheus-stack` chart.
- **Role**: The centralized visualization unified UI.
- **Preconfigured Data Sources**: It is automatically configured to use Prometheus, Loki, and Tempo via the ArgoCD Helm `values` overrides.

### 3. Loki & Promtail
Deployed via the `loki-stack` chart.
- **Promtail**: Runs as a DaemonSet to automatically tail logs from all Docker container stdout/stderr. No application-level configuration is needed for logging—just `print()` or use standard loggers.
- **Loki**: The storage backend indexer.
- **Role**: High volume, label-based log aggregation.

### 4. Tempo
Deployed via the `tempo` chart with OTLP receivers enabled.
- **Role**: Distributed tracing backend.
- **Ingestion**: Listens on `grpc` (port 4317) and `http` (port 4318) for OpenTelemetry-compatible trace spans. The Sample API sends all spans directly here.

## How It Fits Together (The Sample API)
1. **Metrics**: The FastAPI server exposes `/metrics` via the OpenTelemetry + Prometheus client. Prometheus scrapes this endpoint.
2. **Logs**: Python's `logging` module outputs structured logs to stdout. Promtail grabs these from the container runtime and forwards them to Loki.
3. **Traces**: We use `FastAPIInstrumentor` which natively wraps every request in an OpenTelemetry trace. The `BatchSpanProcessor` batches and pushes these spans directly to Tempo's OTLP endpoint.

## Viewing in Grafana
1. Open Grafana (`http://localhost:3000`)
2. Go to `Explore`.
3. To view logs: Select **Loki** as the source, and use the query `{app="sample-api"}`.
4. To view traces: Select **Tempo** as the source and search by trace ID or service name `sample-api`.
5. To view metrics: Select **Prometheus**, and use queries like `rate(api_requests_total[1m])`.
