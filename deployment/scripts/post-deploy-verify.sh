#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ZONE_ID="${ZONE_ID:-Z0132741EJ46AY0VX6OS}"
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
echo "Post-Deployment Verification"
echo "========================================="

# 1. Cluster connectivity
echo -e "\n1. Cluster connectivity..."
kubectl cluster-info &>/dev/null && log "kubectl connected" || {
	fail "Cannot connect to cluster"
	exit 1
}

# 2. Helm releases
echo -e "\n2. Helm releases..."
for release in nginx-ingress cert-manager external-dns argocd; do
	status=$(helm list -A 2>/dev/null | grep "^$release" | awk '{print $8}' | head -n1 || echo "")
	[[ $status == "deployed" ]] && log "Helm release '$release' deployed" || fail "Helm release '$release' not found or not deployed"
done

# 3. Pod Identity
echo -e "\n3. Pod Identity..."
external_dns_pod=$(kubectl get pods -n external-dns -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
[[ -n $external_dns_pod ]] && log "ExternalDNS pod: $external_dns_pod" || fail "ExternalDNS pod not found"

cert_mgr_pod=$(kubectl get pods -n cert-manager -l app.kubernetes.io/name=cert-manager -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
[[ -n $cert_mgr_pod ]] && log "Cert-manager pod: $cert_mgr_pod" || fail "Cert-manager pod not found"

# 4. ClusterIssuer
echo -e "\n4. ClusterIssuer..."
if kubectl get clusterissuer issuer &>/dev/null; then
	log "ClusterIssuer 'issuer' exists"
	conditions=$(kubectl get clusterissuer issuer -o jsonpath='{.status.conditions[*].status}' 2>/dev/null || echo "")
	[[ -z $conditions || $conditions =~ True ]] && log "ClusterIssuer ready" || warn "ClusterIssuer conditions: $conditions"
else
	fail "ClusterIssuer 'issuer' not found"
fi

# 5. Certificates
echo -e "\n5. Certificates..."
if kubectl get certificate -n argo-cd argocd-server-tls &>/dev/null; then
	ready=$(kubectl get certificate -n argo-cd argocd-server-tls -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "")
	expiry=$(kubectl get certificate -n argo-cd argocd-server-tls -o jsonpath='{.status.notAfter}' 2>/dev/null || echo "")
	[[ $ready == "True" ]] && log "Certificate 'argocd-server-tls' ready (expires: $expiry)" || fail "Certificate not ready (status: $ready)"
else
	warn "Certificate 'argocd-server-tls' not found"
fi

# 6. Ingress TLS
echo -e "\n6. Ingress TLS..."
if kubectl get ingress -n argo-cd argocd-server &>/dev/null; then
	log "Ingress 'argocd-server' exists"

	tls_hosts=$(kubectl get ingress -n argo-cd argocd-server -o jsonpath='{.spec.tls[0].hosts[*]}' 2>/dev/null || echo "")
	tls_secret=$(kubectl get ingress -n argo-cd argocd-server -o jsonpath='{.spec.tls[0].secretName}' 2>/dev/null || echo "")

	[[ -n $tls_hosts ]] && log "TLS configured for: $tls_hosts" || fail "TLS not configured"
	[[ -n $tls_secret ]] && kubectl get secret -n argo-cd "$tls_secret" &>/dev/null && log "TLS secret '$tls_secret' exists" || fail "TLS secret missing"

	lb=$(kubectl get ingress -n argo-cd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
	[[ -n $lb ]] && log "LoadBalancer: $lb" || warn "LoadBalancer not assigned"
else
	fail "Ingress 'argocd-server' not found"
fi

# 7. NGINX controller
echo -e "\n7. NGINX ingress controller..."
if kubectl get svc -n nginx-ingress nginx-ingress-controller &>/dev/null; then
	log "NGINX controller service exists"

	https_target=$(kubectl get svc -n nginx-ingress nginx-ingress-controller -o jsonpath='{.spec.ports[?(@.name=="https")].targetPort}' 2>/dev/null || echo "")
	[[ $https_target == "443" ]] && log "HTTPS port → 443" || fail "HTTPS port → $https_target (expected 443)"

	backend=$(kubectl get svc -n nginx-ingress nginx-ingress-controller -o jsonpath='{.metadata.annotations.service\.beta\.kubernetes\.io/aws-load-balancer-backend-protocol}' 2>/dev/null || echo "")
	[[ $backend == "tcp" ]] && log "NLB backend: TCP" || warn "NLB backend: $backend"
else
	fail "NGINX controller service not found"
fi

# 8. Route53 DNS records
echo -e "\n8. Route53 DNS records..."
if dns_records=$(aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" --query "ResourceRecordSets[?Name=='${ARGOCD_HOST}.']" --output json 2>/dev/null); then
	if echo "$dns_records" | jq -e '. | length > 0' &>/dev/null; then
		log "DNS records found for $ARGOCD_HOST"
		echo "$dns_records" | jq -r '.[] | "   \(.Type): \(.Name)"' 2>/dev/null || true
	else
		warn "No DNS records in Route53"
	fi
else
	warn "Cannot query Route53"
fi

# 9. DNS resolution
echo -e "\n9. DNS resolution..."
ip=""
if command -v nslookup &>/dev/null; then
	nslookup_output=$(nslookup "$ARGOCD_HOST" 2>&1 || echo "")
	if [[ $nslookup_output =~ Name:|Addresses?: ]]; then
		ip=$(echo "$nslookup_output" | grep "Addresses:" | awk '{print $2}' | head -n1 | tr -d '[:space:]')
		[[ ! $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && ip=$(echo "$nslookup_output" | grep -A10 "Name:" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | head -n1)
	fi
	[[ -n $ip && $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && log "DNS resolves to: $ip" || warn "DNS resolution failed"
elif command -v dig &>/dev/null; then
	ip=$(dig +short "$ARGOCD_HOST" 2>/dev/null | head -n1 || echo "")
	[[ -n $ip ]] && log "DNS resolves to: $ip" || warn "DNS resolution failed"
else
	warn "No DNS tools available"
fi

# 10. HTTPS connectivity
echo -e "\n10. HTTPS connectivity..."
if command -v curl &>/dev/null; then
	code=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 10 "https://$ARGOCD_HOST" 2>/dev/null || echo "000")

	case $code in
	200 | 302 | 307)
		log "HTTPS connection successful (HTTP $code)"
		response=$(curl -s --max-time 10 "https://$ARGOCD_HOST" 2>/dev/null || echo "")
		[[ $response =~ argocd|argo ]] && log "ArgoCD content detected" || warn "ArgoCD content not detected"
		;;
	000) fail "HTTPS connection failed" ;;
	*) warn "HTTPS returned HTTP $code" ;;
	esac

	ssl=$(echo | openssl s_client -connect "$ARGOCD_HOST:443" -servername "$ARGOCD_HOST" 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null || echo "")
	[[ -n $ssl ]] && {
		log "SSL certificate valid"
		echo "$ssl" | sed 's/^/   /'
	} || warn "Cannot verify SSL certificate"
else
	warn "curl not available"
fi

# Summary
echo -e "\n========================================="
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
	echo -e "${GREEN}All checks passed${NC}"
	exit 0
elif [[ $ERRORS -eq 0 ]]; then
	echo -e "${YELLOW}Completed with $WARNINGS warning(s)${NC}"
	exit 0
else
	echo -e "${RED}Failed: $ERRORS error(s), $WARNINGS warning(s)${NC}"
	exit 1
fi
