locals {
  # Used as VPC name and as prefix for subnet names (e.g. project-vpc-public-eu-west-2a).
  name = "eks-game"
  #domain  = "eks.tomakady.com"
  region      = "eu-central-1"
  cluster     = "eks-2048"
  github_org  = "kceecool001"
  github_repo = "k8s-game"

  tags = {
    Environment = "prod"
    Project     = "EKS"
    Owner       = "kceedev"
  }
}