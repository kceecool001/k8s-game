variable "region" {
  description = "AWS region for state bucket and lock table"
  type        = string
  default     = "eu-central-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "eks-tfstate-kceetf"
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "eks-tfstate-kceetf-lock"
}

variable "create_s3_bucket" {
  description = "Create the S3 bucket. Set to false if the bucket already exists (e.g. created manually)."
  type        = bool
  default     = true
}
