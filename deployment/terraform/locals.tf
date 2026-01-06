locals {
  name    = "project-vpc"
  domain  = "eks.tomakady.com"
  region  = "eu-west-2"
  cluster = "eks-2048"

  tags = {
    Environment = "prod"
    Project     = "EKS"
    Owner       = "tomakady"
  }
}