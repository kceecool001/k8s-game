# Backend config: S3 + DynamoDB are separate from main infrastructure.
# This config uses local state only; it never uses the bucket it creates.
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.region
}
