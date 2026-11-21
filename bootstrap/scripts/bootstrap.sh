#!/usr/bin/env bash
# One-time bootstrap script for a single-node k3s + Argo CD + ESO + Tailscale homelab.
# Review each step before running! Requires sudo for k3s installation.
set -euo pipefail

echo "==> Step 1: Installing k3s (without bundled Traefik since Tailscale Operator handles Ingress)"
if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik --write-kubeconfig-mode=644" sh -
else
  echo "k3s is already installed, skipping."
fi

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "==> Step 2: Waiting for Kubernetes node to be Ready"
kubectl wait --for=condition=Ready node --all --timeout=120s

echo "==> Step 3: Creating namespaces"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace external-secrets --dry-run=client -o yaml | kubectl apply -f -

echo "==> Step 4: Creating bootstrap AWS SSM credential secret for External Secrets Operator"
if ! kubectl get secret aws-ssm-credentials -n external-secrets >/dev/null 2>&1; then
  read -rsp "Enter AWS_ACCESS_KEY_ID for homelab-eso-reader: " AWS_ACCESS_KEY_ID
  echo ""
  read -rsp "Enter AWS_SECRET_ACCESS_KEY for homelab-eso-reader: " AWS_SECRET_ACCESS_KEY
  echo ""

  kubectl create secret generic aws-ssm-credentials \
    --namespace external-secrets \
    --from-literal=access-key-id="${AWS_ACCESS_KEY_ID}" \
    --from-literal=secret-access-key="${AWS_SECRET_ACCESS_KEY}"
else
  echo "Secret external-secrets/aws-ssm-credentials already exists, skipping."
fi

echo "==> Step 5: Installing Argo CD"
kubectl apply -k "$(dirname "$0")/../argocd"
kubectl rollout status deployment/argocd-server -n argocd --timeout=180s

echo "==> Step 6: Applying root App-of-Apps manifests"
kubectl apply -f "$(dirname "$0")/../argocd/root-app.yaml"

echo ""
echo "==> Bootstrap complete!"
echo "Initial Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo ""
echo "Once Tailscale Operator finishes syncing, access Argo CD at:"
echo "  https://argocd.<your-tailnet>.ts.net"
