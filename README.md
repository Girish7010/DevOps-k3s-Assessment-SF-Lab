# DevOps Engineer Assessment - GitOps k3s & Observability

This repository contains an automated, production-grade DevOps environment that provisions a local Kubernetes cluster, a full observability suite, and a sample API, entirely managed via **GitOps**.

The primary goal of this repository is to demonstrate how to architect a modern, fully-automated deployment pipeline that requires **zero manual intervention** after the initial bootstrap.

## Architecture Highlights
- **Cluster**: local simulated `k3s` via `k3d`.
- **GitOps**: **ArgoCD** implements the "App of Apps" pattern, ensuring the cluster state reflects this Git repository exactly.
- **Observability**: **LGTM** Stack (Loki, Grafana, Tempo, Prometheus).
- **Sample App**: A **Python/FastAPI** application instrumented with **OpenTelemetry**, continuously pounded by a simulated traffic generator.

## Getting Started

Everything you need to run, verify, and understand the environment is detailed in the `docs` folder:

1. [Bootstrap Guide](docs/bootstrap.md) - **Start here**. Learn how to automatically spin up the entire cluster with a single command and access all GUIs.
2. [Observability Stack](docs/observability.md) - Learn how metrics, traces, and logs are collected and linked in Grafana.
3. [API Documentation](docs/api.md) - Details on the instrumented sample application.
