# Outputs
output "cluster_name" {
  value = module.eks.cluster_name
}

output "region" {
  value = local.region
}

#output "eks_zone_id" {
# value       = data.aws_route53_zone.eks.zone_id
#description = "Hosted zone ID for eks.tomakady.com"
#}

#output "eks_zone_name_servers" {
##  value       = data.aws_route53_zone.eks.name_servers
# description = "Name servers for eks subdomain delegation"
#}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions (Deploy workflow; set as ADMIN_ARN)"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_ecr_role_arn" {
  description = "IAM role ARN for GitHub Actions Push to ECR workflow; set as ECR_ARN"
  value       = aws_iam_role.github_actions_ecr.arn
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.game.repository_url
  description = "ECR repository URL to use in Kubernetes manifests and GitHub Actions"
}