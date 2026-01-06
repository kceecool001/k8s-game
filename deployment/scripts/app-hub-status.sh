#!/usr/bin/env bash
set -euo pipefail

# Script to verify app-hub deployment status and configuration

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

APP_NAME="the-app-hub"
APP_NAMESPACE="apps"
ARGOCD_NAMESPACE="argo-cd"

log() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }

echo "=========================================="
echo "App-Hub Deployment Verification"
echo "=========================================="
echo ""

# 1. Check ArgoCD Application status
echo "1. Checking ArgoCD Application status..."
if kubectl get application apps -n "$ARGOCD_NAMESPACE" &>/dev/null; then
    SYNC_STATUS=$(kubectl get application apps -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.sync.status}')
    HEALTH_STATUS=$(kubectl get application apps -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.health.status}')
    REVISION=$(kubectl get application apps -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.sync.revision}')
    
    [ "$SYNC_STATUS" = "Synced" ] && log "Sync Status: $SYNC_STATUS" || warn "Sync Status: $SYNC_STATUS"
    [ "$HEALTH_STATUS" = "Healthy" ] && log "Health Status: $HEALTH_STATUS" || warn "Health Status: $HEALTH_STATUS"
    echo "  Sync Revision: $REVISION"
else
    fail "ArgoCD Application 'apps' not found"
fi
echo ""

# 2. Check Pod status
echo "2. Checking Pod status..."
if kubectl get pods -n "$APP_NAMESPACE" -l app="$APP_NAME" &>/dev/null; then
    POD_COUNT=$(kubectl get pods -n "$APP_NAMESPACE" -l app="$APP_NAME" --no-headers | wc -l)
    READY_COUNT=$(kubectl get pods -n "$APP_NAMESPACE" -l app="$APP_NAME" --no-headers | grep -c "Running" || echo "0")
    
    if [ "$POD_COUNT" -gt 0 ]; then
        log "Found $POD_COUNT pod(s), $READY_COUNT running"
        kubectl get pods -n "$APP_NAMESPACE" -l app="$APP_NAME" -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.containerStatuses[0].ready,IMAGE:.spec.containers[0].image,AGE:.metadata.creationTimestamp
    else
        fail "No pods found"
    fi
else
    fail "No pods found for app=$APP_NAME"
fi
echo ""

# 3. Check Deployment image and port
echo "3. Checking Deployment configuration..."
if kubectl get deployment "$APP_NAME" -n "$APP_NAMESPACE" &>/dev/null; then
    DEPLOYED_IMAGE=$(kubectl get deployment "$APP_NAME" -n "$APP_NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].image}')
    DEPLOYED_PORT=$(kubectl get deployment "$APP_NAME" -n "$APP_NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}')
    
    echo "  Image: $DEPLOYED_IMAGE"
    echo "  Container Port: $DEPLOYED_PORT"
    [ "$DEPLOYED_PORT" = "3000" ] && log "Port is correctly set to 3000" || warn "Port is $DEPLOYED_PORT (expected 3000)"
else
    fail "Deployment '$APP_NAME' not found"
fi
echo ""

# 4. Check Service configuration
echo "4. Checking Service configuration..."
if kubectl get svc "$APP_NAME" -n "$APP_NAMESPACE" &>/dev/null; then
    SERVICE_PORT=$(kubectl get svc "$APP_NAME" -n "$APP_NAMESPACE" -o jsonpath='{.spec.ports[?(@.name=="http")].port}')
    TARGET_PORT=$(kubectl get svc "$APP_NAME" -n "$APP_NAMESPACE" -o jsonpath='{.spec.ports[?(@.name=="http")].targetPort}')
    
    echo "  Service Port: $SERVICE_PORT"
    echo "  Target Port: $TARGET_PORT"
    if [ "$TARGET_PORT" = "3000" ]; then
        log "Service correctly targets port 3000"
    else
        warn "Service targets port $TARGET_PORT (expected 3000)"
        echo "  → Service needs to be updated to target port 3000"
    fi
else
    fail "Service '$APP_NAME' not found"
fi
echo ""

# 5. Check Ingress configuration
echo "5. Checking Ingress configuration..."
if kubectl get ingress "${APP_NAME}-ingress" -n "$APP_NAMESPACE" &>/dev/null; then
    INGRESS_HOST=$(kubectl get ingress "${APP_NAME}-ingress" -n "$APP_NAMESPACE" -o jsonpath='{.spec.rules[0].host}')
    INGRESS_SERVICE=$(kubectl get ingress "${APP_NAME}-ingress" -n "$APP_NAMESPACE" -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')
    INGRESS_PORT=$(kubectl get ingress "${APP_NAME}-ingress" -n "$APP_NAMESPACE" -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}')
    
    log "Ingress found: $INGRESS_HOST"
    echo "  Service: $INGRESS_SERVICE"
    echo "  Port: $INGRESS_PORT"
    [ "$INGRESS_PORT" = "80" ] && log "Ingress correctly routes to service port 80" || warn "Ingress routes to port $INGRESS_PORT"
else
    fail "Ingress '${APP_NAME}-ingress' not found"
fi
echo ""

# 6. Check recent pod logs
echo "6. Checking recent pod logs (last 5 lines)..."
if POD_NAME=$(kubectl get pods -n "$APP_NAMESPACE" -l app="$APP_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); then
    if [ -n "$POD_NAME" ]; then
        echo "  Pod: $POD_NAME"
        echo "  ---"
        kubectl logs -n "$APP_NAMESPACE" "$POD_NAME" --tail=5 2>/dev/null || warn "Could not retrieve logs"
    else
        warn "No pods available for log check"
    fi
else
    warn "Could not find pod for log check"
fi
echo ""

# 7. Summary and recommendations
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "To check ArgoCD UI: https://argocd.eks.tomakady.com"
echo "To check application: https://game.eks.tomakady.com"
echo ""
echo "If Service targetPort is incorrect:"
echo "  1. Ensure app/app-hub.yaml has targetPort: 3000"
echo "  2. Commit and push: git add app/app-hub.yaml && git commit -m 'Update port' && git push"
echo "  3. Wait 1-3 minutes for ArgoCD to sync"
echo "  4. Run this script again to verify"
echo ""
echo "=========================================="