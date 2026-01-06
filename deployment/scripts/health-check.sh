#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ARGOCD_HOST="${ARGOCD_HOST:-argocd.eks.tomakady.com}"
ERRORS=0
WARNINGS=0

log() { echo -e "${GREEN}✓${NC} $1"; }
warn() {
	echo -e "${YELLOW}⚠${NC} $1"
	((WARNINGS++))
}
fail() {
	echo -e "${RED}✗${NC} $1"
	((ERRORS++))
}

echo "========================================="
echo "Health Check - $(date)"
echo "========================================="

# Cluster connectivity
echo -e "\n1. Cluster connectivity..."
kubectl cluster-info &>/dev/null && log "Cluster accessible" || {
	fail "Cannot connect to cluster"
	exit 1
}

# Pod status
echo -e "\n2. Critical pods status..."
for ns in nginx-ingress cert-manager external-dns argo-cd; do
	if ! kubectl get namespace "$ns" &>/dev/null; then
		warn "$ns: Namespace not found"
		continue
	fi

	total=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l | tr -d ' ')
	not_ready=$(kubectl get pods -n "$ns" --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')

	[[ $total -eq 0 ]] && warn "$ns: No pods found" && continue
	[[ $not_ready -eq 0 ]] && log "$ns: All pods running ($total)" || warn "$ns: $not_ready/$total pods not ready"
done

# Certificate status
echo -e "\n3. Certificate status..."
if kubectl get certificate -n argo-cd argocd-server-tls &>/dev/null; then
	ready=$(kubectl get certificate -n argo-cd argocd-server-tls -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "")
	expiry=$(kubectl get certificate -n argo-cd argocd-server-tls -o jsonpath='{.status.notAfter}' 2>/dev/null || echo "")

	if [[ $ready == "True" && -n $expiry ]]; then
		if expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null); then
			days_left=$(((expiry_epoch - $(date +%s)) / 86400))
			[[ $days_left -gt 30 ]] && log "Certificate valid until $expiry ($days_left days remaining)" || warn "Certificate expires in $days_left days ($expiry)"
		else
			log "Certificate ready (expires: $expiry)"
		fi
	else
		fail "Certificate not ready"
	fi
else
	warn "Certificate not found"
fi

# DNS resolution
echo -e "\n4. DNS resolution..."
ip=""
if command -v nslookup &>/dev/null; then
	nslookup_output=$(nslookup "$ARGOCD_HOST" 2>&1 || echo "")
	if [[ -n $nslookup_output ]]; then
		ip=$(echo "$nslookup_output" | grep -A10 "Name:" | grep -E "^Address:|^[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | head -n1 || echo "")
	fi
	[[ -n $ip ]] && log "$ARGOCD_HOST resolves to $ip" || warn "DNS resolution failed"
elif command -v dig &>/dev/null; then
	ip=$(dig +short "$ARGOCD_HOST" 2>/dev/null | head -n1 || echo "")
	[[ -n $ip ]] && log "$ARGOCD_HOST → $ip" || warn "DNS resolution failed"
else
	warn "No DNS tools available"
fi

# HTTPS test
echo -e "\n5. HTTPS endpoint..."
if command -v curl &>/dev/null; then
	code=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 5 "https://$ARGOCD_HOST" 2>/dev/null || echo "000")
	case $code in
	200 | 302 | 307) log "HTTPS endpoint responding (HTTP $code)" ;;
	000) fail "Endpoint unreachable" ;;
	*) warn "HTTPS endpoint returned HTTP $code" ;;
	esac
else
	warn "curl not available"
fi

# LoadBalancer status
echo -e "\n6. Ingress LoadBalancer..."
if kubectl get ingress -n argo-cd argocd-server &>/dev/null; then
	lb=$(kubectl get ingress -n argo-cd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
	[[ -n $lb ]] && log "LoadBalancer hostname: $lb" || warn "LoadBalancer not assigned"
else
	fail "Ingress not found"
fi

# Summary
echo -e "\n========================================="
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
	echo -e "${GREEN}All systems operational${NC}"
	exit 0
elif [[ $ERRORS -eq 0 ]]; then
	echo -e "${YELLOW}System operational with $WARNINGS warning(s)${NC}"
	exit 0
else
	echo -e "${RED}System has $ERRORS error(s) and $WARNINGS warning(s)${NC}"
	exit 1
fi
