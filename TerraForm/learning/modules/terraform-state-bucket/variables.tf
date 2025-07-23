# ==============================================================================
# TERRAFORM STATE BUCKET MODULE - INPUT VARIABLES
# ==============================================================================
# Interface definition dla state bucket module - przyjmuje parametry od caller'a

## Environment identifier - używane w naming i tagging
variable "environment" {
  description = "Environment name for state bucket"
  type        = string
}

## Region gdzie będzie bucket - ważne dla backend configuration
variable "region" {
  description = "AWS region where S3 bucket will be created"
  type        = string
}

## Unikalny suffix dla bucket name - S3 bucket names są globally unique
variable "bucket_name_suffix" {
  description = "Unique suffix to append to bucket name"
  type        = string
}

## Nazwa DynamoDB table dla state locking - można customize
variable "table_name" {
  description = "Name of DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-lock"
}

## Lifecycle policy - po ilu dniach usuwać stare wersje state
variable "lifecycle_expiration_days" {
  description = "Number of days after which old state versions expire"
  type        = number
  default     = 90
}
