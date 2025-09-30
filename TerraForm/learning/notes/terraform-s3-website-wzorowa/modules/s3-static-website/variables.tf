# =============================================================================
# Module Input Variables - Parametry wejściowe modułu
# =============================================================================
#
# Variables (zmienne) to parametry, które możesz przekazać do modułu.
# Dzięki nim moduł jest elastyczny i można go używać w różnych sytuacjach.
#
# Każda zmienna ma:
# - description: Opis co robi (ważne dla dokumentacji!)
# - type: Typ danych (string, number, bool, list, map, etc.)
# - default: Wartość domyślna (opcjonalna)
# - validation: Reguły walidacji (opcjonalne)
#
# Bez "default" = zmienna jest WYMAGANA (musisz ją podać)
# Z "default" = zmienna jest OPCJONALNA (możesz ją podać lub użyć domyślnej)
# =============================================================================

# -----------------------------------------------------------------------------
# bucket_name - Nazwa bucketa S3
# -----------------------------------------------------------------------------
#
# Najważniejsza zmienna - określa jak będzie się nazywał bucket.
#
# WAŻNE: Nazwa musi być:
# - Unikalna w całym AWS (globalnie!)
# - Tylko małe litery, cyfry, myślniki
# - 3-63 znaki długości
# - Nie może zaczynać/kończyć się myślnikiem
#
variable "bucket_name" {
  description = "Nazwa bucketa S3 dla statycznej strony WWW. Musi być globalnie unikalna w AWS."
  type        = string

  # Walidacja - sprawdza czy nazwa spełnia wymagania AWS
  validation {
    # Regex sprawdza format nazwy:
    # ^[a-z0-9] = zaczyna się małą literą lub cyfrą
    # [a-z0-9-]* = w środku małe litery, cyfry lub myślniki
    # [a-z0-9]$ = kończy się małą literą lub cyfrą
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Nazwa bucketa może zawierać tylko małe litery, cyfry i myślniki. Nie może zaczynać ani kończyć się myślnikiem."
  }

  validation {
    # Sprawdza długość nazwy (3-63 znaki)
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Nazwa bucketa musi mieć od 3 do 63 znaków."
  }
}

# -----------------------------------------------------------------------------
# environment - Nazwa środowiska
# -----------------------------------------------------------------------------
#
# Pozwala oznaczyć do jakiego środowiska należy zasób.
# Typowe wartości: dev, staging, prod
#
# Używane w tagach do identyfikacji i zarządzania zasobami.
#
variable "environment" {
  description = "Nazwa środowiska (np. dev, staging, prod). Używana w tagach do organizacji zasobów."
  type        = string
  default     = "dev" # Domyślnie środowisko deweloperskie

  # Walidacja - ogranicza do znanych środowisk
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment musi być jedną z wartości: dev, staging, prod."
  }
}

# -----------------------------------------------------------------------------
# tags - Dodatkowe tagi dla zasobów
# -----------------------------------------------------------------------------
#
# Tagi to etykiety klucz-wartość przypisane do zasobów AWS.
# Służą do:
# - Organizacji zasobów (np. "Project" = "MyWebsite")
# - Rozliczania kosztów (np. "CostCenter" = "Marketing")
# - Automatyzacji (np. "Backup" = "Daily")
#
# map(string) oznacza: słownik gdzie klucze i wartości to stringi
# Przykład: { Project = "MyApp", Owner = "DevTeam" }
#
variable "tags" {
  description = "Mapa tagów do przypisania do wszystkich zasobów. Używaj do organizacji i rozliczania."
  type        = map(string)
  default     = {} # Pusty słownik = brak dodatkowych tagów

  # Przykład użycia:
  # tags = {
  #   Project     = "CompanyWebsite"
  #   CostCenter  = "Marketing"
  #   ManagedBy   = "Terraform"
  # }
}

# =============================================================================
# Jak używać zmiennych w module:
# =============================================================================
#
# W kodzie odwołujesz się do zmiennych przez: var.nazwa_zmiennej
# Przykład: var.bucket_name, var.environment, var.tags
#
# Wartości można przekazać na 3 sposoby:
#
# 1. W pliku wywołującym moduł (environments/dev/main.tf):
#    module "website" {
#      source      = "../../modules/s3-static-website"
#      bucket_name = "my-unique-bucket-name"
#      environment = "dev"
#    }
#
# 2. Przez zmienne Terraform (terraform.tfvars):
#    bucket_name = "my-unique-bucket-name"
#
# 3. Przez zmienne środowiskowe:
#    export TF_VAR_bucket_name="my-unique-bucket-name"
#
# =============================================================================