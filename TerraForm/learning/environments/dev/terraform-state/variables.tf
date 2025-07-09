variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev" # <- default dla dev folder!
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1" # <- default dla dev w eu-west-1
}

variable "bucket_name_suffix" {
  description = "A suffix to append to the bucket name to ensure uniqueness."
  type        = string
  default     = "tk"
}
