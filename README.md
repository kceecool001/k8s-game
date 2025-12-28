# EKS Lab - Kubernetes Cluster with ArgoCD

This repository contains Terraform configurations and Helmfile specifications for deploying an EKS cluster with ArgoCD, NGINX Ingress, Cert-Manager, and ExternalDNS.

## Architecture

- **Terraform**: Manages AWS infrastructure (VPC, EKS, IAM, Pod Identities)
- **Helmfile**: Manages Kubernetes applications (Helm charts)
- **External-DNS**: Automatically manages Route53 DNS records based on ingress annotations
- **Cert-Manager**: Automatically issues TLS certificates via Let's Encrypt
- **ArgoCD**: GitOps continuous delivery tool

## Prerequisites

Before deploying, ensure you have:

- AWS CLI installed and configured
- Terraform >= 1.0
- Helmfile installed
- kubectl installed
- helm installed
- Access to AWS account with appropriate permissions
- Route53 hosted zone for your subdomain

## Quick Start

### Full Deployment Workflow

Deploy everything in the correct order:

```bash
cd deployment

# Step 1: Deploy infrastructure and applications
# This runs terraform apply + helmfile sync automatically
./scripts/deploy.sh

# Step 2: Connect GitHub repository (required for private repos)
# This creates a Kubernetes secret with your GitHub PAT
./scripts/connect-github-repo.sh

# Step 3: Get ArgoCD admin password
./scripts/get-argocd-password.sh

# Step 4: Deploy ArgoCD Applications
./scripts/apply-argocd-app.sh
```

**What gets deployed:**

1. **Infrastructure (Terraform)**:
   - VPC with public/private subnets
   - EKS cluster with managed node groups
   - VPC endpoints for cost optimization
   - IAM roles and Pod Identity associations for cert-manager and external-dns

2. **Applications (Helmfile)**:
   - NGINX Ingress Controller
   - Cert-Manager (with CRDs)
   - External-DNS
   - ArgoCD
   - Prometheus
   - Grafana

3. **ArgoCD Setup**:
   - GitHub repository connection (for private repos)
   - ArgoCD Application resources

**Note**: Route53 DNS records are automatically created by External-DNS when you deploy ingresses via Helmfile.

### Access ArgoCD

After deployment:

- URL: `https://argocd.labs.tomakady.com`
- Username: `admin`
- Password: Use `./scripts/get-argocd-password.sh` to retrieve it

## Project Structure

```
.
├── deployment/
│   ├── terraform/                 # Terraform infrastructure
│   │   ├── vpc.tf                # VPC and networking
│   │   ├── eks.tf                # EKS cluster configuration
│   │   ├── pod-identities.tf     # IAM roles and Pod Identity associations
│   │   ├── providers.tf         # Terraform providers and backend
│   │   └── locals.tf             # Local variables and configuration
│   ├── helmfile.yaml             # Helmfile specification for all Helm releases
│   ├── helm-values/              # Helm chart values
│   │   ├── argocd.yaml
│   │   ├── cert-manager.yaml
│   │   ├── external-dns.yaml
│   │   ├── nginx-ingress.yaml
│   │   ├── prometheus.yaml
│   │   └── grafana.yaml
│   ├── argo-cd/                  # ArgoCD Application manifests
│   │   └── apps-argo.yaml
│   └── scripts/
│       └── apply-argocd-app.sh   # Script to apply ArgoCD Applications
```

## How It Works

### Infrastructure (Terraform)

Terraform manages only AWS infrastructure:
- **vpc.tf**: VPC, subnets, security groups, VPC endpoints
- **eks.tf**: EKS cluster, node groups, security group rules
- **pod-identities.tf**: IAM policies, roles, and Pod Identity associations for cert-manager and external-dns
- **providers.tf**: Terraform backend, providers, and data sources
- **locals.tf**: Shared variables and configuration

### Applications (Helmfile)

Helmfile manages all Kubernetes applications:
- Deploys Helm charts in the correct order
- Manages chart versions and values
- Creates namespaces automatically
- Handles dependencies between charts

### DNS Management (External-DNS)

External-DNS automatically:
- Watches for ingress resources with `external-dns.alpha.kubernetes.io/hostname` annotation
- Creates/updates Route53 A and AAAA records pointing to the LoadBalancer
- No manual scripts needed - it's fully automated!

### Certificate Management (Cert-Manager)

Cert-Manager automatically:
- Issues TLS certificates via Let's Encrypt
- Uses DNS01 challenge with Route53 (via Pod Identity)
- Creates TLS secrets for ingresses
- Renews certificates automatically

## Configuration

### Domain Configuration

Update `deployment/terraform/locals.tf`:

```hcl
locals {
  domain = "labs.tomakady.com"  # Change this
  region = "eu-west-2"
  # ...
}
```

### Helm Chart Versions

Update `deployment/helmfile.yaml` to change chart versions:

```yaml
releases:
  - name: argocd
    chart: argocd/argo-cd
    version: "9.0.5"  # Change version here
```

### Cert-Manager Email

Update `deployment/helm-values/cert-manager.yaml` or create a ClusterIssuer manually.

## Common Commands

```bash
# Get cluster kubeconfig
aws eks update-kubeconfig --name eks-lab --region eu-west-2

# Check Helm releases
helm list -A

# Check Helmfile status
cd deployment
helmfile list

# Sync specific release
helmfile sync -l name=argocd

# Check certificate status
kubectl get certificate -A

# Check ingress status
kubectl get ingress -A

# Check External-DNS logs
kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns

# Check Route53 records (should be automatic)
aws route53 list-resource-record-sets --hosted-zone-id Z0314813274VWO3I28JJY

# Get ArgoCD admin password (recommended)
cd deployment
./scripts/get-argocd-password.sh

# Or manually
kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Connect GitHub repository (for private repos)
cd deployment
./scripts/connect-github-repo.sh

# Apply ArgoCD Application
cd deployment
./scripts/apply-argocd-app.sh
```

## Deployment Workflow

### First Time Deployment

```bash
cd deployment

# 1. Deploy infrastructure and applications
./scripts/deploy.sh

# 2. Connect GitHub repository (if private)
./scripts/connect-github-repo.sh

# 3. Get ArgoCD password
./scripts/get-argocd-password.sh

# 4. Deploy ArgoCD Applications
./scripts/apply-argocd-app.sh
```

### Updates

```bash
# Update infrastructure
cd deployment/terraform
terraform apply

# Update applications
cd deployment
helmfile sync
```

## Troubleshooting

### DNS Not Resolving

**Problem**: Domain doesn't resolve after creating ingress

**Solutions**:
1. Check External-DNS pod is running: `kubectl get pods -n external-dns`
2. Check External-DNS logs: `kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns`
3. Verify ingress has annotation: `kubectl get ingress -A -o yaml | grep external-dns`
4. Check Route53 records: `aws route53 list-resource-record-sets --hosted-zone-id Z0314813274VWO3I28JJY`
5. Wait a few minutes - External-DNS syncs every 1 minute by default

### Certificate Not Issued

**Problem**: Certificate stuck in "Pending" or not ready

**Solutions**:
1. Check ClusterIssuer exists: `kubectl get clusterissuer`
2. Check cert-manager pods: `kubectl get pods -n cert-manager`
3. Check certificate request: `kubectl describe certificaterequest -A`
4. Verify Pod Identity: `kubectl get pods -n cert-manager -o yaml | grep -i identity`
5. Check cert-manager logs: `kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager`

### Helmfile Sync Fails

**Problem**: Helmfile sync errors or timeouts

**Solutions**:
1. Check Helmfile syntax: `helmfile lint`
2. Check Helm repositories: `helm repo list`
3. Update Helm repositories: `helmfile repos`
4. Check specific release: `helmfile sync -l name=argocd`
5. Increase timeout in `helmfile.yaml`: `timeout: 600`

### Pod Identity Issues

**Problem**: Pods can't assume IAM roles

**Solutions**:
1. Verify Pod Identity addon: `aws eks describe-addon --cluster-name eks-lab --addon-name eks-pod-identity-agent`
2. Check Pod Identity associations: `kubectl get pods -n cert-manager -o yaml | grep -i identity`
3. Verify IAM roles exist: `terraform output -json` (in terraform directory)
4. Check service account annotations: `kubectl get sa -n cert-manager cert-manager -o yaml`

## Cost Optimization

This setup includes VPC endpoints to reduce EKS API call costs:
- ECR API and DKR (container registry)
- STS (security token service)
- CloudWatch Logs
- S3 (gateway endpoint)

## Security Notes

- Pod Identity is used for IAM access (more secure than IRSA)
- TLS certificates are automatically managed by Cert-Manager
- All ingress traffic is forced to HTTPS
- VPC endpoints keep traffic within AWS network

## Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Cert-Manager Documentation](https://cert-manager.io/docs/)
- [ExternalDNS Documentation](https://github.com/kubernetes-sigs/external-dns)
- [Helmfile Documentation](https://helmfile.readthedocs.io/)
# k8s-project
