output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.terraform_state_bucket.bucket_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.terraform_state_bucket.dynamodb_table_name
}

output "region" {
  description = "AWS region"
  value       = module.terraform_state_bucket.region
}