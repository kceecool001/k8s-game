# Terraform backend (S3 + DynamoDB)

**Separate from main infrastructure.** This directory only creates the S3 bucket and DynamoDB table used by `deployment/terraform` for remote state and locking. It uses **local state** and does not depend on the main stack.

- **bootstrap/** (repo root) → backend resources only (bucket + lock table).
- **deployment/terraform** → EKS, VPC, IAM, etc.; state stored in the bucket above.

## When to run

Run **once** per AWS account/region before first use of `deployment/terraform`.

## Usage

```bash
cd bootstrap
terraform init
terraform apply
```

## Options

- **Existing bucket:** If the S3 bucket already exists:

  ```bash
  terraform apply -var="create_s3_bucket=false"
  ```

- **Custom names:** Override `bucket_name` and `lock_table_name`; keep the same values in `deployment/terraform/providers.tf` backend block.

## After bootstrap

From `deployment/terraform` run `terraform init` (or `terraform init -reconfigure`). The main stack never manages the bucket or table; it only uses them via the backend config. Run bootstrap from the **project root** (e.g. `cd bootstrap`).
