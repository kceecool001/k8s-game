#!/usr/bin/env bash
set -euo pipefail

# Simple script to connect private GitHub repo to ArgoCD

# Load from .env file if it exists (in project root or deployment directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPLOYMENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
elif [ -f "$DEPLOYMENT_DIR/.env" ]; then
    source "$DEPLOYMENT_DIR/.env"
fi

# ============================================
# CONFIGURE YOUR DETAILS HERE
# ============================================
REPO_URL="${REPO_URL:-https://github.com/tomakady/k8s-test.git}"
GITHUB_USER="${GITHUB_USER:-tomakady}"
# GITHUB_PAT should be set in .env file or will be prompted
GITHUB_PAT="${GITHUB_PAT:-}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argo-cd}"
# ============================================

# Generate secret name from repo URL
SECRET_NAME="repo-https-$(echo "$REPO_URL" | sed 's|https://||' | sed 's|/|.|g' | sed 's|\.git$||')"

echo "Connecting GitHub repository to ArgoCD..."
echo "Repository: $REPO_URL"
echo "========================================="

# Check if PAT is set, otherwise prompt
if [ -z "$GITHUB_PAT" ] || [ "$GITHUB_PAT" = "ghp_YOUR_TOKEN_HERE" ]; then
	echo ""
	echo "Enter your GitHub Personal Access Token (PAT):"
	read -s GITHUB_PAT
	echo ""
fi

if [ -z "$GITHUB_PAT" ]; then
	echo "Error: GitHub PAT is required"
	exit 1
fi

# Delete existing secret if it exists
kubectl delete secret "$SECRET_NAME" -n "$ARGOCD_NAMESPACE" 2>/dev/null || true

# Create the repository secret
# For GitHub PATs, use the token as both username and password (GitHub HTTPS requirement)
kubectl create secret generic "$SECRET_NAME" \
	--from-literal=type=git \
	--from-literal=url="$REPO_URL" \
	--from-literal=username="${GITHUB_PAT:-$GITHUB_USER}" \
	--from-literal=password="$GITHUB_PAT" \
	-n "$ARGOCD_NAMESPACE"

# Label it so ArgoCD recognizes it
kubectl label secret "$SECRET_NAME" \
	argocd.argoproj.io/secret-type=repository \
	-n "$ARGOCD_NAMESPACE" \
	--overwrite

# Restart repo-server to pick up new credentials
echo ""
echo "Restarting ArgoCD repo-server to pick up new credentials..."
kubectl rollout restart deployment argocd-repo-server -n "$ARGOCD_NAMESPACE" 2>/dev/null || echo "  (repo-server may not exist yet, continuing...)"

echo ""
echo "✓ Repository secret created successfully!"
echo ""
echo "Secret name: $SECRET_NAME"
echo "Namespace: $ARGOCD_NAMESPACE"
echo ""
echo "ArgoCD should now be able to access your repository."
echo "Check your Application status with:"
echo "  kubectl get application -n argo-cd apps"