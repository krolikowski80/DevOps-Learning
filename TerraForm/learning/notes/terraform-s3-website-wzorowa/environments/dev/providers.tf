# =============================================================================
# Terraform & Provider Configuration - Konfiguracja Terraform i providerów
# =============================================================================
#
# Ten plik konfiguruje:
# 1. Wersję Terraform (CLI)
# 2. Providerów (pluginy do komunikacji z AWS, Azure, GCP, etc.)
# 3. Backend (gdzie przechowywać state - tutaj lokalnie)
#
# WAŻNE KONCEPTY:
#
# Terraform = narzędzie CLI (sam program)
# Provider = plugin do zarządzania zasobami w konkretnej chmurze
# Backend = gdzie przechowywać plik stanu (terraform.tfstate)
#
# Analogia:
# - Terraform = przeglądarka (Chrome, Firefox)
# - Provider = dodatek do przeglądarki (AdBlock, Translator)
# - Backend = gdzie zapisujesz zakładki (lokalnie vs synchronizacja)
# =============================================================================

# -----------------------------------------------------------------------------
# Terraform Block - Konfiguracja samego Terraform
# -----------------------------------------------------------------------------
#
# Ten blok określa wymagania dla projektu:
# - Jakiej wersji Terraform użyć
# - Jakich providerów potrzebujemy i w jakiej wersji
#
terraform {
  # required_version: Minimalna wersja Terraform CLI
  # ">= 1.0" oznacza: wersja 1.0 lub nowsza
  #
  # Dlaczego to ważne:
  # - Starsze wersje mogą nie mieć potrzebnych funkcji
  # - Nowsze wersje mogą wprowadzać breaking changes
  # - Zespół wie jakiej wersji używać
  #
  required_version = ">= 1.0"

  # required_providers: Lista providerów (pluginów) których potrzebujemy
  #
  # Provider = plugin który wie jak zarządzać konkretnymi zasobami.
  # Dla AWS: tworzy buckety S3, EC2, RDS, etc.
  # Dla Azure: tworzy VM, Storage, etc.
  #
  required_providers {
    # Provider AWS - do zarządzania zasobami Amazon Web Services
    aws = {
      # source: Skąd pobrać provider (rejestr Terraform)
      # Format: namespace/provider-name
      # hashicorp/aws = oficjalny provider od HashiCorp
      source = "hashicorp/aws"

      # version: Która wersja providera
      # "~> 5.0" oznacza: >= 5.0.0 i < 6.0.0
      #
      # Notacja wersji:
      # ~> 5.0  = >= 5.0.0, < 6.0.0 (bezpieczne update'y minor)
      # ~> 5.1  = >= 5.1.0, < 5.2.0 (tylko patche)
      # >= 5.0  = 5.0 lub nowsze (niebezpieczne!)
      # = 5.0.0 = dokładnie 5.0.0 (zbyt restrykcyjne)
      #
      # ZALECANE: używaj ~> dla stabilności
      version = "~> 5.0"
    }

    # Provider Random - do generowania losowych wartości
    # (obecnie nieużywany, ale gotowy gdybyśmy potrzebowali)
    #
    # Przykłady użycia random:
    # - Losowe hasła
    # - Losowe sufiksy do nazw
    # - Losowe porty
    #
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  # Backend Configuration - gdzie przechowywać stan (state)
  #
  # OBECNIE: Używamy domyślnego backendu "local"
  # Stan jest zapisywany w pliku terraform.tfstate w tym katalogu.
  #
  # Dla produkcji rozważ zdalny backend:
  # backend "s3" {
  #   bucket = "my-terraform-state"
  #   key    = "s3-website/dev/terraform.tfstate"
  #   region = "eu-west-1"
  # }
  #
  # Zalety zdalnego backendu:
  # - Współdzielony stan między członkami zespołu
  # - Blokada stanu (locking) - zapobiega konfliktom
  # - Backup i wersjonowanie
  # - Bezpieczeństwo (nie commitujemy state do git)
}

# -----------------------------------------------------------------------------
# AWS Provider Configuration - Konfiguracja providera AWS
# -----------------------------------------------------------------------------
#
# Provider "aws" to plugin który komunikuje się z AWS API.
# Ten blok konfiguruje jak provider ma działać.
#
provider "aws" {
  # region: W którym regionie AWS tworzyć zasoby
  # Bierzemy wartość ze zmiennej var.aws_region (zdefiniowanej w variables.tf)
  region = var.aws_region

  # Dodatkowe opcje które możesz ustawić (obecnie nieużywane):
  #
  # profile = "default"  # Profil AWS CLI (jeśli używasz wielu kont)
  # shared_credentials_file = "~/.aws/credentials"  # Gdzie są credentiale
  #
  # access_key = "..."  # ❌ NIE rób tego! Nigdy nie commituj kluczy do git!
  # secret_key = "..."  # ❌ NIE rób tego! Użyj AWS CLI lub zmiennych środowiskowych
  #
  # default_tags {      # Tagi automatycznie dodawane do wszystkich zasobów
  #   tags = {
  #     ManagedBy = "Terraform"
  #     Team      = "DevOps"
  #   }
  # }
}

# =============================================================================
# Jak Terraform używa providerów:
# =============================================================================
#
# 1. terraform init
#    - Czyta ten plik (providers.tf)
#    - Pobiera potrzebne providery z rejestru (registry.terraform.io)
#    - Zapisuje je w katalogu .terraform/
#    - Tworzy plik .terraform.lock.hcl (plik blokady wersji)
#
# 2. terraform plan/apply
#    - Używa zainstalowanych providerów do komunikacji z AWS
#    - Provider AWS tłumaczy kod Terraform na wywołania AWS API
#    - Przykład: aws_s3_bucket -> CreateBucket API call
#
# 3. terraform destroy
#    - Provider AWS usuwa zasoby przez AWS API
#    - Przykład: aws_s3_bucket -> DeleteBucket API call
#
# =============================================================================

# =============================================================================
# Uwierzytelnianie w AWS:
# =============================================================================
#
# Provider AWS potrzebuje credentials (kluczy dostępu) do AWS.
# Terraform sprawdza credentials w tej kolejności:
#
# 1. Zmienne środowiskowe:
#    export AWS_ACCESS_KEY_ID="..."
#    export AWS_SECRET_ACCESS_KEY="..."
#    export AWS_SESSION_TOKEN="..."  # Jeśli używasz MFA
#
# 2. Plik credentials (~/.aws/credentials):
#    [default]
#    aws_access_key_id = ...
#    aws_secret_access_key = ...
#
# 3. IAM Role (jeśli uruchamiasz na EC2/ECS/Lambda):
#    Automatycznie używa IAM role przypisanej do instancji
#
# 4. Environment variables provided by AWS SSO
#
# ZALECANE:
# - Lokalnie: Użyj "aws configure" (tworzy ~/.aws/credentials)
# - CI/CD: Użyj zmiennych środowiskowych lub IAM roles
# - NIGDY nie commituj kluczy do git!
#
# =============================================================================

# =============================================================================
# Dobre praktyki:
# =============================================================================
#
# ✅ DOBRZE:
# - Określ required_version dla Terraform
# - Użyj ~> dla wersji providerów (bezpieczne update'y)
# - Jeden providers.tf per środowisko (dev, staging, prod)
# - Używaj najnowszych stabilnych wersji providerów
# - Dokumentuj niestandardowe konfiguracje
#
# ❌ ŹLE:
# - Brak required_version (każdy może użyć innej wersji)
# - Brak version dla providerów (niestabilne buildy)
# - Hard-kodowanie credentials w kodzie
# - Używanie bardzo starych wersji providerów
# - Commitowanie .terraform/ lub .terraform.lock.hcl (opcjonalne)
#
# =============================================================================

# =============================================================================
# Komendy do zarządzania providerami:
# =============================================================================
#
# terraform init              # Pobierz/zaktualizuj providery
# terraform init -upgrade     # Zaktualizuj providery do najnowszych (zgodnych z ~>)
# terraform providers         # Pokaż zainstalowane providery
# terraform providers lock    # Utwórz lock file dla wielu platform
# terraform providers schema  # Pokaż schemat providera (debugowanie)
#
# =============================================================================