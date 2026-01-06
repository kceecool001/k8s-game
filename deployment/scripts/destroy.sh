#!/usr/bin/env bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Change to the deployment directory (parent of scripts)
cd "$SCRIPT_DIR/.." || exit 1

echo "========================================="
echo "Destroying Infrastructure"
echo "========================================="
echo ""

# Step 1: Destroy Helmfile releases first (removes Kubernetes resources and AWS resources like load balancers)
echo "Step 1: Destroying Helmfile releases..."
echo "This removes Kubernetes resources and their AWS resources (load balancers, etc.)"

# Check if the cluster is reachable before trying to destroy Helmfile releases
if kubectl cluster-info &>/dev/null 2>&1; then
  echo "Cluster is reachable. Destroying Helmfile releases..."
  # Use the working helmfile from user's bin directory if available, otherwise use PATH
  HELMFILE_CMD=$(command -v /c/Users/tomak/bin/helmfile.exe 2>/dev/null || command -v helmfile 2>/dev/null || echo "helmfile")
  set +e  # Temporarily disable exit on error for helmfile destroy
  $HELMFILE_CMD destroy
  HELMFILE_EXIT=$?
  set -e  # Re-enable exit on error
  if [ $HELMFILE_EXIT -ne 0 ]; then
    echo "Warning: helmfile destroy failed (exit code $HELMFILE_EXIT). Continuing with Terraform destroy..."
  fi
else
  echo "Cluster is not reachable (may already be destroyed). Skipping Helmfile destroy."
fi

echo ""
echo "Step 2: Destroying Terraform infrastructure..."
cd terraform && terraform destroy --auto-approve && cd ..

echo ""
echo "========================================="
echo "Destroy Complete"
echo "========================================="
echo ""
echo "Note: If you have ArgoCD Applications, you may need to delete them manually:"
echo "  kubectl delete application -n argo-cd --all"
echo ""
