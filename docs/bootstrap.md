# Bootstrap Guide

This document describes how to provision the core k3s cluster (via `k3d`), install ArgoCD, and synchronize the entire platform using GitOps.

## Pre-requisites
- Docker (must be running)
- `curl`, `bash`, `sudo` (for downloading binaries)
- (Optional but recommended) `make` to use the Makefile shortcuts.

## Step-by-Step Setup

### 1. Run the Bootstrap Script
The `bootstrap.sh` script automates the entire process:
1. Installs `k3d` and `kubectl` if they are not already installed.
2. Spins up a local `k3d` cluster (acting as an on-premise k3s environment).
3. Builds the Docker images for the Sample API and the Traffic Generator locally.
4. Sideloads these images into the k3s cluster so it doesn't need to pull from a public registry.
5. Installs ArgoCD.
6. Applies the **Root Application** to ArgoCD, starting the GitOps synchronization process.

To run it:
```bash
./bootstrap.sh
```

### 2. Verify GitOps Synchronization
By the time the script finishes, ArgoCD will start creating everything in the cluster automatically based on the manifests in the `argo/` and `apps/` folders of this repository.

To watch the pods coming online:
```bash
kubectl get pods -A -w
```
It may take 5-10 minutes for the full LGTM stack to download and initialize.

### 3. Accessing the GUIs

#### ArgoCD
1. Port-forward the ArgoCD UI:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
2. Open your browser to `https://localhost:8080`
3. **Username**: `admin`
4. **Password**: Retrieve the initial password via:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

#### Grafana (Observability)
1. Port-forward Grafana:
   ```bash
   kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80
   ```
2. Open your browser to `http://localhost:3000`
3. **Username**: `admin`
4. **Password**: `admin`

#### Sample API
The cluster has ports 80 and 443 mapped to your localhost. However, since we haven't configured an Ingress, you can access the API directly by port-forwarding:
```bash
kubectl port-forward svc/sample-api -n sample-api 8000:80
```
Then visit `http://localhost:8000/docs` to view the interactive API playground.

## Teardown
To cleanly destroy the k3d cluster when you're done:
```bash
make clean
```
