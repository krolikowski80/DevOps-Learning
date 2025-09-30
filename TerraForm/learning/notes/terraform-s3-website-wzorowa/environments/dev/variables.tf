# =============================================================================
# Dev Environment Variables - Zmienne specyficzne dla środowiska DEV
# =============================================================================
#
# Ten plik definiuje zmienne używane w środowisku deweloperskim.
# Każde środowisko (dev, staging, prod) może mieć inne wartości tych zmiennych.
#
# RÓŻNICA między tym plikiem a modules/s3-static-website/variables.tf:
# - Plik w module: definiuje JAKIE parametry moduł akceptuje
# - Plik w environment: definiuje KONKRETNE wartości dla tego środowiska
#
# Przepływ danych:
# terraform.tfvars -> variables.tf (tutaj) -> main.tf -> moduł
# =============================================================================

# -----------------------------------------------------------------------------
# aws_region - Region AWS gdzie tworzyć zasoby
# -----------------------------------------------------------------------------
#
# AWS ma datacentry na całym świecie podzielone na regiony.
# Każdy region to fizyczna lokalizacja (np. eu-west-1 = Irlandia).
#
# Wybór regionu zależy od:
# - Gdzie są Twoi użytkownicy (mniejsze opóźnienia)
# - Wymagania prawne (RODO - dane w UE)
# - Ceny (różnią się między regionami)
#
# Popularne regiony:
# - eu-west-1: Irlandia (Europa)
# - eu-central-1: Frankfurt (Europa)
# - us-east-1: Virginia (USA) - często najtańszy
# - ap-southeast-1: Singapur (Azja)
#
variable "aws_region" {
  description = "Region AWS gdzie będą tworzone zasoby. Wybierz region blisko Twoich użytkowników."
  type        = string
  default     = "eu-west-1" # Irlandia - dobry wybór dla Europy

  # Możesz zmienić na inny region jeśli potrzebujesz.
  # Pamiętaj: zmiana regionu = odtworzenie wszystkich zasobów!
}

# -----------------------------------------------------------------------------
# bucket_name - Nazwa bucketa dla środowiska dev
# -----------------------------------------------------------------------------
#
# To jest nazwa bucketa specyficzna dla środowiska deweloperskiego.
#
# WAŻNE:
# - Musi być GLOBALNIE unikalna w całym AWS (miliony użytkowników!)
# - Dobra praktyka: dodaj swój identyfikator (np. nazwę firmy)
# - Format: nazwa-projektu-środowisko-losowe-znaki
#
# Przykłady:
# - moja-firma-website-dev-x7k2p
# - jan-kowalski-portfolio-dev
# - acme-landing-page-dev-2024
#
variable "bucket_name" {
  description = "Nazwa bucketa S3 dla środowiska deweloperskiego. MUSI być globalnie unikalna!"
  type        = string

  # ZMIEŃ TĘ WARTOŚĆ! Ta domyślna może być już zajęta.
  # Dodaj swoje inicjały lub losowe znaki na końcu.
  default = "my-website-dev-changeme"

  # Przykład lepszej nazwy:
  # default = "tomasz-website-dev-7x2k"
}

# -----------------------------------------------------------------------------
# environment - Oznaczenie środowiska
# -----------------------------------------------------------------------------
#
# Ta zmienna oznacza typ środowiska.
# Używana do:
# - Tagowania zasobów (łatwiejsze zarządzanie)
# - Różnicowania konfiguracji (dev vs prod)
# - Filtrowania kosztów w AWS Cost Explorer
#
variable "environment" {
  description = "Nazwa środowiska. Dla tego katalogu zawsze 'dev'."
  type        = string
  default     = "dev"

  # Nie zmieniaj tej wartości! Dla środowiska dev zawsze "dev".
  # Środowiska prod i staging mają swoje własne katalogi.
}

# -----------------------------------------------------------------------------
# tags - Wspólne tagi dla wszystkich zasobów
# -----------------------------------------------------------------------------
#
# Tagi to "etykiety" przypisane do zasobów AWS.
# Pomagają w organizacji i zarządzaniu setkami zasobów.
#
# Dlaczego tagi są ważne:
# - Wiesz kto jest właścicielem zasobu
# - Możesz śledzić koszty per projekt/zespół
# - Automatyzacja: "usuń wszystko z tagiem Environment=dev"
# - Compliance: wymagane przez niektóre firmy
#
# Dobre praktyki tagowania:
# - Zawsze używaj: Environment, Project, ManagedBy
# - Opcjonalnie: Owner, CostCenter, Team
# - Używaj spójnych nazw (CamelCase lub snake_case)
#
variable "tags" {
  description = "Mapa tagów wspólnych dla wszystkich zasobów w środowisku dev."
  type        = map(string)

  # Domyślne tagi dla środowiska deweloperskiego
  default = {
    Environment = "dev"                       # Typ środowiska
    Project     = "S3-Static-Website"         # Nazwa projektu
    ManagedBy   = "Terraform"                 # Jak zarządzane (ręcznie vs IaC)
    Purpose     = "Learning"                  # Cel zasobu
    Owner       = "DevTeam"                   # Kto jest odpowiedzialny
    CostCenter  = "Development"               # Do rozliczania kosztów
    CreatedBy   = "Terraform-S3-Website-Lab"  # Przez co utworzone
  }

  # Możesz nadpisać/dodać tagi w terraform.tfvars:
  # tags = {
  #   Environment = "dev"
  #   Project     = "MyAwesomeWebsite"
  #   Owner       = "Jan Kowalski"
  # }
}

# =============================================================================
# Jak używać zmiennych:
# =============================================================================
#
# 1. Wartości domyślne (default):
#    Są używane jeśli nie podasz innych wartości.
#    Dobre dla wartości które rzadko się zmieniają.
#
# 2. Plik terraform.tfvars (ZALECANE dla dev):
#    Utwórz plik terraform.tfvars w tym samym katalogu:
#
#    bucket_name = "moja-unikalna-nazwa-123"
#    aws_region  = "eu-central-1"
#    tags = {
#      Owner = "Ja"
#      Project = "MojProjekt"
#    }
#
# 3. Zmienne środowiskowe:
#    export TF_VAR_bucket_name="moja-nazwa"
#    terraform apply
#
# 4. Flaga -var podczas apply:
#    terraform apply -var="bucket_name=moja-nazwa"
#
# 5. Interaktywnie:
#    Jeśli zmienna nie ma default i nie podasz wartości,
#    Terraform zapyta Cię o nią podczas "terraform plan/apply"
#
# =============================================================================

# =============================================================================
# Hierarchia zmiennych (która wartość wygrywa):
# =============================================================================
#
# Terraform stosuje następującą kolejność (od najważniejszej):
#
# 1. -var lub -var-file podczas apply (najwyższy priorytet)
# 2. Zmienne środowiskowe TF_VAR_*
# 3. terraform.tfvars lub terraform.tfvars.json
# 4. *.auto.tfvars (w kolejności alfabetycznej)
# 5. default w definicji zmiennej (najniższy priorytet)
#
# Przykład:
# - default w variables.tf: "my-website-dev"
# - terraform.tfvars: "better-name-dev"
# - Wynik: użyje "better-name-dev" (tfvars > default)
#
# =============================================================================

# =============================================================================
# Dobre praktyki dla zmiennych:
# =============================================================================
#
# ✅ DOBRZE:
# - Używaj opisowych nazw zmiennych
# - Zawsze dodawaj description
# - Określ type (string, number, bool, list, map)
# - Używaj validation gdzie to możliwe
# - Dokumentuj wartości domyślne
# - Trzymaj wrażliwe dane w secrets (nie w kodzie!)
#
# ❌ ŹLE:
# - Zmienne bez description
# - Brak type (Terraform zgaduje)
# - Hard-kodowanie wartości w zasobach
# - Commity terraform.tfvars z secretami do git
# - Zbyt ogólne nazwy (np. "name", "value")
#
# =============================================================================