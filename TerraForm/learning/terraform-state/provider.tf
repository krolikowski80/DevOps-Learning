# ==============================================================================
# PROVIDER CONFIGURATION - BOOTSTRAP
# ==============================================================================
# Minimal provider config dla bootstrap - bez default_tags bo to shared resource

terraform {
  # Local state dla bootstrap - chicken-and-egg problem
  # Nie możemy użyć remote state do tworzenia remote state bucket!
}

provider "aws" {
  region = var.region

  # Minimal tags dla shared infrastructure  
  default_tags {
    tags = {
      Purpose   = "terraform-state-bucket"
      ManagedBy = "terraform"
      Owner     = "tomasz"
    }
  }
}
