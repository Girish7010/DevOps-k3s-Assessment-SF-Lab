#!/bin/bash
set -eo pipefail

CLUSTER_NAME="devops-cluster"

echo "================================================="
echo "Bootstrapping DevOps Environment"
echo "================================================="

export PATH=$HOME/.local/bin:$PATH
mkdir -p $HOME/.local/bin

# 1. Install k3d
if ! command -v k3d &> /dev/null; then
    echo "[+] Installing k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# 2. Install kubectl
if ! command -v kubectl &> /dev/null; then
    echo "[+] Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl $HOME/.local/bin/kubectl
fi

# 3. Create cluster
if k3d cluster list | grep -q "^$CLUSTER_NAME"; then
    echo "[-] Cluster exists. Skipping..."
else
    echo "[+] Creating k3d cluster..."
    k3d cluster create $CLUSTER_NAME \
        -p "80:80@loadbalancer" \
        -p "443:443@loadbalancer" \
        --agents 1
fi

# 4. Configure kubeconfig (🔥 CRITICAL)
echo "[+] Setting kubeconfig..."
export KUBECONFIG=$(k3d kubeconfig write $CLUSTER_NAME)

# Persist it
echo "export KUBECONFIG=$(k3d kubeconfig write $CLUSTER_NAME)" >> ~/.bashrc

# Verify cluster
kubectl get nodes

# 5. Build images
echo "[+] Building images..."
make api-docker
make traffic-docker

# 6. Install ArgoCD
echo "[+] Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "[+] Waiting for ArgoCD..."
kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=300s

# 7. Apply GitOps root app
kubectl apply -f argo/root-application.yaml

echo "================================================="
echo "✅ Bootstrap Complete!"
echo "================================================="