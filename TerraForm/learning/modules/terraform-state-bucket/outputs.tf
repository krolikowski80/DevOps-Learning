# ==============================================================================
# TERRAFORM STATE BUCKET MODULE - OUTPUT VALUES
# ==============================================================================
# Te outputs będą używane przez environments do konfiguracji backend.tf

## Bucket name - dokładna nazwa utworzonego bucket (z random suffix)
## Potrzebne do backend configuration w każdym environment
output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.terraform_state.bucket
}

## DynamoDB table name - nazwa tabeli do state locking
## Potrzebne do backend configuration dla concurrent access protection
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

## Region - gdzie został utworzony bucket
## Potrzebne do backend config - region musi się zgadzać
output "region" {
  description = "AWS region where the bucket was created"
  value       = var.region
}

## Bucket ARN - dla advanced IAM policies jeśli potrzebne
output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

## Complete backend template - ready to copy-paste
## Saves time when setting up new environments
output "backend_template" {
  description = "Complete backend configuration template"
  value = {
    bucket         = aws_s3_bucket.terraform_state.bucket
    region         = var.region
    dynamodb_table = aws_dynamodb_table.terraform_locks.name
    key_template   = "ENVIRONMENT/infrastructure.tfstate" # replace ENVIRONMENT
  }
}
