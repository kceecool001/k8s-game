# Production-grade K8s deployment

## Diagram

*[Add architecture diagram here]*

## Overview

This project is a scalable, production-grade deployment of the 2048 game application on an EKS cluster. The deployment is spread across three AZs for high-availability and uses the EKS Managed Node Group service, allowing for streamlined scalability. Infrastructure deployments are automated using Terraform, and the application is containerised using Docker and deployed to a private container registry on AWS (ECR).

## Architecture

*[Add architecture diagram here]*

## Key features

- **External-dns**: Automatically updates DNS records in Route 53.
- **Cert-manager**: Provides DNS validation and digital certificates, as well as certificate management.
- **Helmfile**: Orchestrates K8s deployments across multiple Helm charts.
- **Prometheus/Grafana**: Fetches vital cluster logs/metrics and visualises them in readable dashboards.
- **Open ID Connect (OIDC)**: Use of JSON web tokens over access keys lifts the risks & responsibilities of key management and also enforces just-in-time permissions.

## Directory StructureThe K8s Project (AWS Edition) - aka EKS

https://github.com/CoderCo-Learning/eks-assignment-v1


This project focuses on deploying a secure application on a Production-grade Kubernetes cluster using Amazon EKS. 

It includes end-to-end infrastructure provisioning using AWS, Kubernetes, Terraform, CI/CD pipelines, ArgoCD, Helm, ExternalDNS and CertManager.

Task/Assignment 📝
Create your own repository and complete the task there. You may create an app in your repo and copy over any provided files as needed or build everything from scratch—your choice.

The Goal:
You will deploy a cloud-native application on Amazon EKS using best practices for infrastructure provisioning, CI/CD automation, and security. You’ll also set up GitOps automation with ArgoCD and dynamic DNS updates.

When complete, the application should be accessible via HTTPS at:
https://eks.<your-domain> or https://eks.labs.<your-domain>

Deliverables:

Infrastructure as code using Terraform modules for EKS and related AWS services.

CI/CD pipelines automating security scans, Docker image builds, and application deployments to EKS.

Dynamic DNS and SSL/TLS certificate management for secure endpoints.

Monitoring of EKS and application health with dashboards using Prometheus and Grafana.

GitOps-driven automated deployments via ArgoCD.

Project Tasks 🔧
AWS Infrastructure Setup (Terraform)

Create an EKS cluster, VPC, IAM roles, and security groups using Terraform.

Use reusable Terraform modules for infrastructure components. Ensure proper state management is in place.

Configure networking with private subnets for the EKS cluster and public subnets for load balancing.

Define IAM roles for the Kubernetes worker nodes and ensure security groups limit access to only required resources.

NGINX Ingress Controller

Deploy and configure the NGINX Ingress Controller on the EKS cluster using Helm charts or Kubernetes manifests.

Configure the controller to route incoming traffic to the correct Kubernetes services.

Set up rules for HTTPS using TLS certificates managed by CertManager (see task below).

CertManager (SSL/TLS Management)

Install and configure CertManager on the cluster.

Set up Let’s Encrypt or a custom CA to generate SSL certificates automatically for the application.

Integrate the certificates with the NGINX Ingress Controller for secure HTTPS connections.

Dynamic DNS Updates (ExternalDNS)

Deploy ExternalDNS on the EKS cluster to automate DNS record management.

Configure ExternalDNS to dynamically update DNS records in Route 53 based on changes in Kubernetes ingress resources.

Ensure the DNS updates reflect the public endpoint of the application when services or ingresses change.

CI/CD Pipelines: Automate Everything 🚀

Pipeline 1: Terraform

Automate Terraform deployments for provisioning EKS and related AWS resources.

Integrate state management using a remote backend (e.g., S3 + DynamoDB).

Include error handling and proper validation of Terraform code before deployments.

Pipeline 2: Docker, Security, and Kubernetes

Scan the Terraform code using Checkov to catch misconfigurations and ensure compliance with security best practices.

Build and push the Docker image of your application to Amazon ECR using the pipeline.

Use Trivy to scan the Docker image for vulnerabilities.

Deploy the application to EKS using Kubernetes manifests or Helm charts.

GitOps with ArgoCD

Set up ArgoCD to automate the deployment of Kubernetes manifests from your Git repository to the EKS cluster.

Ensure the deployment is triggered automatically when changes are pushed to the repo.

Create a GitOps workflow where the cluster state is reconciled with the desired state defined in the Git repository.

Monitoring and Observability

Deploy Prometheus to collect metrics from the Kubernetes cluster, including pods, nodes, namespaces, and services.

Set up Grafana to visualize the metrics and create custom dashboards.

Include dashboards showing high CPU/memory usage, pod health, node statuses, and Ingress traffic.

Architecture Documentation

Create a clear, well-documented architecture diagram using Lucidchart, draw.io, or Mermaid.

The diagram should show:

AWS infrastructure (VPC, EKS, subnets, security groups, IAM roles)

Traffic flow through the NGINX Ingress Controller

Dynamic DNS setup using ExternalDNS

Certificate management with CertManager

ArgoCD GitOps flow

Monitoring components (Prometheus and Grafana)

Useful Links 🔗
Terraform Docs

EKS Documentation

ArgoCD Docs

Checkov Security Scanning

```
├── .github
│   └── workflows
│       ├── deploy.yaml
│       ├── docker-build.yaml
│       ├── terraform-apply.yaml
│       └── terraform-destroy.yaml
├── bootstrap
│   ├── backend.tf
│   ├── main.tf
│   └── ... (S3 + DynamoDB for Terraform state; separate from main stack)
├── deployment
│   ├── helmfile.yaml
│   ├── apps
│   │   └── game.yaml
│   ├── argo-cd
│   │   └── apps-argo.yaml
│   ├── cert-mgr
│   │   └── issuer.yaml
│   ├── helm-values
│   │   ├── argocd.yaml
│   │   ├── cert-manager.yaml
│   │   ├── external-dns.yaml
│   │   ├── grafana.yaml
│   │   ├── nginx-ingress.yaml
│   │   └── prometheus.yaml
│   ├── scripts
│   │   ├── deploy.sh
│   │   ├── destroy.sh
│   │   └── ...
│   └── terraform
│       ├── eks.tf
│       ├── vpc.tf
│       ├── pod-identities.tf
│       ├── providers.tf
│       ├── outputs.tf
│       └── locals.tf
└── src
    └── Dockerfile
```

## Docker

*[Add Docker diagram here]*

- **Multistage builds**: Separates the application build from the final image, cutting image sizes by reducing build dependencies in the final image.
- **Image tagging**: Uses semantic versioning tags (`latest`) to enable reliable image management and deployment.
- **Nginx-based serving**: Uses `nginx:alpine` as the base image to efficiently serve static files, configured to listen on port 3000.
- **Trivy scans**: Scan images for any CVEs before they're pushed to ECR, ensuring security vulnerabilities are caught early in the pipeline.

## Terraform

*[Add Terraform diagram here]*

- **Community modules**: Implementation of DRY principles, using ready-made, reusable Terraform modules (EKS, VPC, Pod Identity).
- **Checkov**: Security scanning in CI pipelines enforces security best-practices in Terraform configurations, hardening infrastructure.
- **S3 backend**: Terraform state is stored in an S3 bucket with encryption enabled, enabling state locking and team collaboration.
- **VPC endpoints**: Private connectivity to AWS services (S3, ECR, STS, CloudWatch Logs) without requiring internet gateways, enhancing security and reducing data transfer costs.

## GitOps Workflow

*[Add GitOps diagram here]*

- **CI Pipelines**: Manual workflow triggers (`workflow_dispatch`) provide controlled execution of builds and deployments, preventing unintentional workflow runs. OIDC authentication solves the risks associated with long-lived access keys.
- **GitHub Secrets**: Sensitive data such as image tags and IAM role ARNs are stored as secrets rather than hardcoded as plaintext.
- **ArgoCD**: ArgoCD server monitors the repository for any changes to the application manifests in `deployment/apps/` and automatically deploys them, syncing the cluster with the desired state.
- **Deploy to EKS**: The Docker pipeline builds and pushes the application image to ECR. ArgoCD syncs the application from Git, so deployment to EKS happens when manifests (or image references) in `deployment/apps/` are pushed to the repo.

## ArgoCD

*[Add ArgoCD diagram here]*

ArgoCD monitors the `deployment/apps/` directory and automatically syncs any changes to Kubernetes manifests. The application is configured to use the game deployment, service, and ingress resources, ensuring the 2048 game is always in the desired state. Deployment to EKS is triggered automatically when changes are pushed to the repo.

Access ArgoCD at: `https://argocd.eks.tomakady.com`

## Observability

### Prometheus

*[Add Prometheus diagram here]*

Prometheus: Node exporter sits inside each K8s node and grabs all internal metrics, such as CPU usage, memory and available storage space.

Access Prometheus at: `https://prometheus.eks.tomakady.com`

### Grafana

*[Add Grafana diagram here]*

Grafana: Grabs the data fetched by Prometheus and makes it more readable through dashboards and visualisations. Prometheus' URL needs to be configured as a data source for Grafana to see it.

Access Grafana at: `https://grafana.eks.tomakady.com`

## Run Locally

Copy the contents of `src/` into your local machine. Then run:

```bash
python -m http.server 3000
```

Or use Docker:

```bash
cd src
docker build -t 2048-game .
docker run -p 3000:3000 2048-game
```

Access the game at: `http://localhost:3000`

## Deployment

Quick start (run from repo root after bootstrap and cluster access are set up):

```bash
cd deployment
./scripts/deploy.sh
./scripts/connect-github-repo.sh
./scripts/get-argocd-password.sh
./scripts/apply-argocd-app.sh
```

## What I learnt

- **PVs & PVCs**: Services such as Prometheus node-exporter and alertmanager require persistent storage to store logs, metrics and alerts. When deployed through K8s, this is provided through a persistent volume. To access this, pods need to make a persistent volume claim. Without either, neither service can run, causing the release to fail.

- **ClusterIssuer management**: Cluster-scoped resources like ClusterIssuers need to be applied separately from namespace-scoped resources. We use Helmfile hooks to apply the ClusterIssuer after cert-manager is deployed, ensuring proper ordering and dependency management.

- **Pod Identity**: EKS Pod Identity provides a simpler way for pods to assume IAM roles compared to IRSA, allowing services like cert-manager and external-dns to interact with AWS services (Route53) without storing long-lived credentials.

- **Helmfile hooks**: Using `postsync` hooks in Helmfile allows us to execute commands (like applying ClusterIssuer) after a Helm release is successfully deployed, maintaining the dependency order while keeping infrastructure as code.

- **ExternalDNS and Cert-Manager integration**: The combination of ExternalDNS (which creates Route53 records) and Cert-Manager (which uses DNS-01 challenges for certificate validation) requires careful configuration of hosted zone permissions and DNS zone selectors to work together seamlessly.

