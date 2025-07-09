variable "region" {
  description = "The AWS region where the S3 bucket will be created."
  type        = string
}

variable "environment" {
  description = "The environment for which the S3 bucket is being created (e.g., dev, staging, prod)."
  type        = string
}

variable "bucket_name_suffix" {
  description = "The name of the S3 bucket to be created."
  type        = string
}

variable "table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-lock"
}
