output "bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = var.create_s3_bucket ? aws_s3_bucket.state[0].id : var.bucket_name
}

output "lock_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.lock.name
}

output "backend_config_note" {
  description = "Reminder for main Terraform backend"
  value       = "deployment/terraform should use bucket = \"${var.bucket_name}\" and dynamodb_table = \"${var.lock_table_name}\""
}
