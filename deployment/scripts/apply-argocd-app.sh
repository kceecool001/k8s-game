#!/usr/bin/env bash
set -euo pipefail

# Simple script to apply ArgoCD Application resource

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argo-cd}"
# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Default to deployment/argo-cd/apps-argo.yaml relative to script location
APP_FILE="${APP_FILE:-$SCRIPT_DIR/../argo-cd/apps-argo.yaml}"

echo "Applying ArgoCD Application..."
echo "========================================="

# Check if ArgoCD is running
echo "Checking if ArgoCD is ready..."
if ! kubectl get namespace "$ARGOCD_NAMESPACE" &>/dev/null; then
    echo "Error: Namespace '$ARGOCD_NAMESPACE' not found. ArgoCD may not be installed."
    exit 1
fi

# Wait for ArgoCD server to be ready (optional but recommended)
if kubectl get deployment argocd-server -n "$ARGOCD_NAMESPACE" &>/dev/null; then
    echo "Waiting for ArgoCD server to be ready..."
    kubectl wait --for=condition=available deployment/argocd-server -n "$ARGOCD_NAMESPACE" --timeout=120s || {
        echo "Warning: ArgoCD server may not be fully ready, but continuing..."
    }
fi

# Check if file exists
if [ ! -f "$APP_FILE" ]; then
    echo "Error: Application file '$APP_FILE' not found"
    exit 1
fi

# Apply the Application
echo ""
echo "Applying Application from: $APP_FILE"
kubectl apply -f "$APP_FILE"

# Wait a moment for the Application to be processed
sleep 2

# Check Application status
echo ""
echo "Checking Application status..."
if kubectl get application apps -n "$ARGOCD_NAMESPACE" &>/dev/null; then
    echo ""
    echo "✓ ArgoCD Application applied successfully!"
    echo ""
    echo "Application Status:"
    kubectl get application apps -n "$ARGOCD_NAMESPACE" -o custom-columns=NAME:.metadata.name,STATUS:.status.sync.status,HEALTH:.status.health.status,REVISION:.status.sync.revision
    echo ""
    echo "To check detailed status:"
    echo "  kubectl get application apps -n $ARGOCD_NAMESPACE -o yaml"
    echo ""
    echo "Or view in ArgoCD UI:"
    echo "  https://argocd.eks.tomakady.com"
else
    echo "Warning: Application resource not found after applying. Check for errors above."
    exit 1
fi

echo "========================================="