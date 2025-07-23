# ==============================================================================
# TERRAFORM STATE BUCKET - OUTPUTS
# ==============================================================================
# Te outputs będą używane do konfiguracji backend.tf w environments

## Bucket name - potrzebne do backend configuration w dev/staging/prod
output "bucket_name" {
  description = "Name of the created S3 bucket for terraform state"
  value       = module.terraform_state_bucket.bucket_name
}

## DynamoDB table name - potrzebne do state locking w backend config
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = module.terraform_state_bucket.dynamodb_table_name
}

## Region - gdzie jest bucket, potrzebne do backend config
output "region" {
  description = "AWS region where state bucket is located"
  value       = module.terraform_state_bucket.region
}

## Complete backend config - ready to copy-paste do environments
output "backend_config" {
  description = "Complete backend configuration template"
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${module.terraform_state_bucket.bucket_name}"
        key            = "ENVIRONMENT/infrastructure.tfstate"  # replace ENVIRONMENT
        region         = "${module.terraform_state_bucket.region}"
        dynamodb_table = "${module.terraform_state_bucket.dynamodb_table_name}"
      }
    }
  EOT
}

