terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34.0"
    }
  }

  backend "s3" {
    bucket         = "eks-tfstate-tomakady" # created by bootstrap/ at repo root (separate from this stack)
    key            = "eks-2048/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "eks-tfstate-tomakady-lock"
  }
}

provider "aws" {
  region = local.region
}

# Route53 data source
data "aws_route53_zone" "eks" {
  zone_id = "Z0132741EJ46AY0VX6OS"
}