# =============================================================================
# Dev Environment - Główny plik konfiguracyjny
# =============================================================================
#
# To jest plik który UŻYWA modułu s3-static-website.
# Moduł to jak funkcja - ten plik "wywołuje" tę funkcję z konkretnymi parametrami.
#
# Struktura projektu:
# - modules/s3-static-website/  <- DEFINICJA modułu (co i jak robić)
# - environments/dev/           <- UŻYCIE modułu (wywołanie z parametrami)
#
# Dzięki temu możesz mieć wiele środowisk (dev, staging, prod)
# używających tego samego modułu z różnymi parametrami.
# =============================================================================

# -----------------------------------------------------------------------------
# Module Call - Wywołanie modułu S3 static website
# -----------------------------------------------------------------------------
#
# "module" to słowo kluczowe Terraform do używania modułów.
# Moduł to zbiór zasobów zapakowany w reużywalną "funkcję".
#
# Analogia:
# - Moduł = funkcja w programowaniu
# - source = gdzie jest kod funkcji
# - zmienne = parametry funkcji
# - outputs = wartość zwracana przez funkcję
#
module "s3_website" {
  # source: Ścieżka do kodu modułu (względna lub z rejestru)
  # ../../ = wyjdź z environments/dev/ do głównego katalogu
  source = "../../modules/s3-static-website"

  # Parametry przekazywane do modułu (jak argumenty funkcji):

  # bucket_name: Unikalna nazwa bucketa S3
  # Bierzemy ją ze zmiennej var.bucket_name (zdefiniowanej w variables.tf)
  bucket_name = var.bucket_name

  # environment: Oznaczenie środowiska (dev, staging, prod)
  # Używane w tagach do organizacji zasobów
  environment = var.environment

  # tags: Dodatkowe etykiety dla wszystkich zasobów
  # Pomagają w organizacji i rozliczaniu kosztów w AWS
  tags = var.tags
}

# =============================================================================
# Jak to działa krok po kroku:
# =============================================================================
#
# 1. Terraform czyta ten plik (environments/dev/main.tf)
# 2. Widzi wywołanie modułu "s3_website"
# 3. Idzie do ścieżki source (../../modules/s3-static-website)
# 4. Czyta pliki modułu (main.tf, variables.tf, outputs.tf)
# 5. Podstawia wartości zmiennych (bucket_name, environment, tags)
# 6. Wykonuje wszystkie zasoby zdefiniowane w module
# 7. Zwraca outputs z modułu (można je użyć przez module.s3_website.output_name)
#
# =============================================================================

# -----------------------------------------------------------------------------
# Outputs - Przekazanie wartości z modułu na zewnątrz
# -----------------------------------------------------------------------------
#
# Moduł zwraca wartości (outputs), ale są one dostępne tylko wewnętrznie.
# Żeby użytkownik je zobaczył, musimy je "przepuścić" na zewnątrz.
#
# Format: module.nazwa_modułu.nazwa_output
#

# URL strony WWW - najważniejsza informacja!
output "website_url" {
  description = "URL strony WWW. Skopiuj ten adres do przeglądarki aby zobaczyć stronę."
  value       = module.s3_website.website_url
}

# Nazwa bucketa - przydatne do zarządzania przez AWS CLI
output "bucket_name" {
  description = "Nazwa utworzonego bucketa S3."
  value       = module.s3_website.bucket_name
}

# ARN bucketa - przydatne do konfiguracji uprawnień i innych zasobów
output "bucket_arn" {
  description = "ARN (unikalny identyfikator) bucketa S3."
  value       = module.s3_website.bucket_arn
}

# Endpoint bez protokołu - przydatne do konfiguracji DNS
output "website_endpoint" {
  description = "Endpoint S3 website bez protokołu HTTP (do użycia w DNS)."
  value       = module.s3_website.website_endpoint
}

# =============================================================================
# Jak użyć tego kodu:
# =============================================================================
#
# 1. Przejdź do tego katalogu:
#    cd environments/dev
#
# 2. Zainicjalizuj Terraform (pobiera providery i moduły):
#    terraform init
#
# 3. Zobacz co zostanie utworzone (dry-run):
#    terraform plan
#
# 4. Utwórz zasoby:
#    terraform apply
#
# 5. Zobacz outputs (w tym URL strony):
#    terraform output
#    terraform output website_url
#
# 6. Usuń wszystko (gdy już nie potrzebujesz):
#    terraform destroy
#
# =============================================================================

# =============================================================================
# Najlepsze praktyki:
# =============================================================================
#
# ✅ DOBRZE:
# - Jeden moduł, wiele środowisk (dev, staging, prod)
# - Każde środowisko w osobnym katalogu
# - Zmienne w terraform.tfvars (nie w kodzie)
# - Stan lokalny dla dev, zdalny dla prod
# - Tagi do organizacji i rozliczania
#
# ❌ ŹLE:
# - Kopiowanie kodu zamiast używania modułów
# - Hard-kodowanie wartości zamiast zmiennych
# - Brak tagów i opisów
# - Mieszanie środowisk w jednym miejscu
#
# =============================================================================