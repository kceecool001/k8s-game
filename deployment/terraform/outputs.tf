# Outputs
output "cluster_name" {
  value = module.eks.cluster_name
}

output "region" {
  value = local.region
}

output "external_dns_role_arn" {
  description = "IAM role ARN for external-dns"
  value       = module.external_dns_pod_identity.iam_role_arn
}

output "cert_manager_role_arn" {
  description = "IAM role ARN for cert-manager"
  value       = module.cert_manager_pod_identity.iam_role_arn
}

output "eks_zone_id" {
  value       = data.aws_route53_zone.eks.zone_id
  description = "Hosted zone ID for eks.tomakady.com"
}

output "eks_zone_name_servers" {
  value       = data.aws_route53_zone.eks.name_servers
  description = "Name servers for eks subdomain delegation"
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

