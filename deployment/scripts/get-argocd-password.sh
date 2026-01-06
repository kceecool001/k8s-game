#!/usr/bin/env bash
set -euo pipefail

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argo-cd}"
SECRET_NAME="${SECRET_NAME:-argocd-initial-admin-secret}"

echo "Retrieving ArgoCD admin password..."
echo "========================================="

if ! kubectl get secret "$SECRET_NAME" -n "$ARGOCD_NAMESPACE" &>/dev/null; then
	echo "Error: Secret '$SECRET_NAME' not found in namespace '$ARGOCD_NAMESPACE'"
	exit 1
fi

# For Windows, base64 -d might not work, so use base64 --decode or PowerShell
if command -v base64 &>/dev/null; then
	PASSWORD=$(kubectl -n "$ARGOCD_NAMESPACE" get secret "$SECRET_NAME" -o jsonpath="{.data.password}" | base64 --decode)
else
	# Fallback: use kubectl's built-in base64 decode
	PASSWORD=$(kubectl -n "$ARGOCD_NAMESPACE" get secret "$SECRET_NAME" -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || kubectl -n "$ARGOCD_NAMESPACE" get secret "$SECRET_NAME" -o json | jq -r '.data.password' | base64 -d)
fi

echo ""
echo "ArgoCD Admin Credentials:"
echo "  Username: admin"
echo "  Password: $PASSWORD"
echo ""
echo "========================================="
