# ==============================================================================
# TERRAFORM STATE BUCKET - BOOTSTRAP INFRASTRUCTURE
# ==============================================================================
# Tworzy shared infrastructure dla remote state wszystkich environments
# Ten kod będzie użyty tylko raz - potem wszystkie env będą używać tego bucket

## Provider configuration - używamy tego samego regionu co state bucket
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


## State bucket module - używamy własny module do tworzenia S3 + DynamoDB
## Shared bucket dla wszystkich environments z różnymi keys
module "terraform_state_bucket" {
  source = "../modules/terraform-state-bucket"

  environment        = var.environment
  region             = var.region
  bucket_name_suffix = var.bucket_name_suffix
}

# Dokumentacja S3 backend: https://www.terraform.io/language/settings/backends/s3
