# ==============================================================================
# REMOTE STATE BACKEND CONFIGURATION
# ==============================================================================
# Używamy shared S3 bucket dla wszystkich środowisk, różne keys dla izolacji
# Enterprise approach: jeden bucket, różne "foldery" per environment

terraform {
  backend "s3" {
    bucket               = "terraform-state-tk-20250723200542692400000001" # z terraform-state outputs
    key                  = "dev/infrastructure.tfstate"                    # dev environment state
    region               = "eu-central-1"                                  # gdzie jest bucket
    dynamodb_table       = "terraform-state-lock-shared"                   # shared locking table
    workspace_key_prefix = "workspaces"
  }
}

# Dokumentacja S3 backend: https://www.terraform.io/language/settings/backends/s3
