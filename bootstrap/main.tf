# Backend-only: S3 bucket and DynamoDB table for Terraform state.
# Not part of the main EKS/VPC Terraform; run once per account/region.

resource "aws_s3_bucket" "state" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = var.bucket_name

  tags = {
    Purpose = "Terraform state"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.state[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.state[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.state[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Purpose = "Terraform state lock"
  }
}
