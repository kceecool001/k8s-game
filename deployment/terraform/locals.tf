locals {
  # Used as VPC name and as prefix for subnet names (e.g. project-vpc-public-eu-west-2a).
  name    = "eks-game"
  domain  = "eks.tomakady.com"
  region  = "eu-west-2"
  cluster = "eks-2048"

  tags = {
    Environment = "prod"
    Project     = "EKS"
    Owner       = "tomakady"
  }
}