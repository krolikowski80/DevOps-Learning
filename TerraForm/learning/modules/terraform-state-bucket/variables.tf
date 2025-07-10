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

variable "lifecycle_expiration_days" {
  description = "Number of days after which the Terraform state files will expire."
  type        = number
  default     = 90
}

variable "block_public_acls" {
  description = "Whether to block public ACLs on the S3 bucket."
  type        = bool
  default     = true
  
}

variable "ignore_public_acls" {
  description = "Whether to ignore public ACLs on the S3 bucket."
  type        = bool
  default     = true 
}

variable "block_public_policy" {
  description = "Whether to block public policies on the S3 bucket."
  type        = bool
  default     = true  
  
}
 variable "restrict_public_buckets" {
  description = "Whether to restrict public buckets."
  type        = bool
  default     = true  
   
 }