#!/bin/bash
set -eo pipefail

REPO_URL=${1:-"https://github.com/Girish7010/DevOps-k3s-Assessment-SF-Lab.git"}
CLUSTER_NAME="devops-cluster"

echo "================================================="
echo "Bootstrapping DevOps Environment"
echo "Repository: $REPO_URL"
echo "================================================="

# 1. Install prerequisites if missing
if ! command -v k3d &> /dev/null; then
    echo "[!] k3d not found. Installing..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

if ! command -v kubectl &> /dev/null; then
    echo "[!] kubectl not found. Installing..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
fi

# 2. Setup k3d cluster
if k3d cluster list | grep -q "^$CLUSTER_NAME"; then
    echo "[-] k3d cluster '$CLUSTER_NAME' already exists. Skipping creation."
else
    echo "[+] Creating k3d cluster '$CLUSTER_NAME'..."
    # Map port 80 and 443 to localhost for easy ingress access
    k3d cluster create $CLUSTER_NAME \
        -p "80:80@loadbalancer" \
        -p "443:443@loadbalancer" \
        --agents 1
fi

kubectl cluster-info

# 3. Setup ArgoCD
echo "[+] Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "[-] Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=300s
kubectl wait --for=condition=Available deployment/argocd-repo-server -n argocd --timeout=300s
kubectl wait --for=condition=Available deployment/argocd-applicationset-controller -n argocd --timeout=300s
kubectl wait --for=condition=Available deployment/argocd-dex-server -n argocd --timeout=300s

# 4. Apply Root Application (GitOps Entrypoint)
echo "[+] Applying GitOps Root Application..."

# Substitute the repository url in the root application yaml temporarily
cat argo/root-application.yaml | sed "s|__REPO_URL__|$REPO_URL|g" | kubectl apply -f -

echo "================================================="
echo "Bootstrap Complete!"
echo "ArgoCD will now sync the cluster state from Git."
echo ""
echo "To access ArgoCD UI:"
echo "1. Port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "2. Open https://localhost:8080"
echo "3. User: admin"
echo "4. Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "================================================="
