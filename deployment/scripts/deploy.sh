#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

wait_for_certificate() {
    local cert_name="$1"
    local namespace="$2"
    for i in {1..60}; do
        if kubectl get certificate "$cert_name" -n "$namespace" &>/dev/null 2>&1; then
            local ready=$(kubectl get certificate "$cert_name" -n "$namespace" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
            [ "$ready" = "True" ] && echo "  ✓ Certificate ready" && return 0
        fi
        [ $i -eq 60 ] && echo "  ⚠ Certificate still issuing (will continue in background)" || sleep 10
    done
}

echo "========================================="
echo "Deploying Infrastructure"
echo "========================================="
echo ""

echo "Step 1: Deploying infrastructure..."
cd terraform && terraform apply --auto-approve && cd ..
CLUSTER_NAME=$(cd terraform && terraform output -raw cluster_name 2>/dev/null || echo "eks-2048")
REGION=$(cd terraform && terraform output -raw region 2>/dev/null || echo "eu-west-2")
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION" || echo "Warning: Failed to update kubeconfig, continuing..."

echo ""
echo "Step 2: Deploying platform services..."
HELMFILE_CMD=$(command -v helmfile 2>/dev/null || echo "helmfile")
$HELMFILE_CMD repos
helm repo update
$HELMFILE_CMD sync

echo ""
echo "Step 3: Setting up ArgoCD..."
./scripts/apply-argocd-app.sh

echo ""
echo "Step 4: Configuring repository and certificate..."
./scripts/connect-github-repo.sh
wait_for_certificate "argocd-server-tls" "argo-cd"

echo ""
echo "Step 5: Verifying deployment..."
./scripts/post-deploy-verify.sh
./scripts/get-argocd-password.sh

echo ""
echo "========================================="
echo "Deploy Complete"
echo "========================================="