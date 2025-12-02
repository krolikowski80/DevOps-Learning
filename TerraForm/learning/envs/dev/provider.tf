# ==============================================================================
# PROVIDER CONFIGURATION - AWS
# ==============================================================================

## Konfiguracja AWS provider - definiuję konkretną wersję bo chcę reproducible builds.
## Provider odpowiada za komunikację z AWS API. Region biorę z zmiennej żeby móc łatwo
## zmienić deployment location bez modyfikacji kodu.
terraform {
  required_version = ">= 1.5.0" # Wymagana wersja Terraform
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Kompatybilne z 5.x, ale nie 6.x - chcę uniknąć breaking changes
    }
  }
}

## Główny AWS provider - wszystkie zasoby będą tworzone w tym regionie.
## Używam shared credentials lub IAM role, nie hardcoduję access keys w kodzie.
provider "aws" {
  region = var.aws_region

  ## Domyślne tagi aplikowane na wszystkie zasoby - ułatwia cost tracking,
  ## resource management i compliance. Każdy zasób będzie automatycznie tagowany.
  default_tags {
    tags = {
      Environment = var.environment      # Używam zmiennej, żeby łatwo zmieniać środowisko (dev, staging, prod)
      Project     = "terraform-learning" # Nazwa projektu, do którego należą zasoby
      ManagedBy   = "terraform"          # Informacja, że zasoby są zarządzane przez Terraform
      Owner       = "tomasz"             # Właściciel zasobów, może być użyteczne w większych zespołach
    }
  }
}

# Dokumentacja AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
