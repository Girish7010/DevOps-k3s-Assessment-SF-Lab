# Sample API Documentation

The Sample API is a Python application built with the FastAPI framework. It exposes several HTTP endpoints and is fully instrumented for observability.

## Endpoints

- `GET /`
  A generic root handler to test latency and spans.
- `GET /health`
  Used by Kubernetes for liveness and readiness probes.
- `GET /metrics`
  Exposes OpenMetrics-compatible output for Prometheus to scrape.
- `GET /items/{item_id}`
  A mock resource fetching endpoint. Deliberately simulates latency (random sleep). Also simulates a 404 error if `item_id=0`.
- `POST /items`
  Creates a mock item.
- `GET /error`
  A dedicated endpoint to intentionally throw a `500 Internal Server Error` to test Application Logging and Trace exceptions.

## Traffic Generation
A secondary deployment (`traffic-generator`) runs continuously alongside the API in the cluster. It randomly picks endpoints to `curl` (via python `requests`), ensuring that the monitoring stack always has live data flowing through it.
