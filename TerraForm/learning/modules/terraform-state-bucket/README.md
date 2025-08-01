# Moduł Terraform State Bucket

## Co to robi

Ten moduł tworzy infrastrukturę dla zdalnego przechowywania stanu Terraform w AWS. Rozwiązuje fundamentalny problem współpracy zespołowej - gdy więcej niż jedna osoba pracuje z Terraform, lokalny plik `terraform.tfstate` powoduje konflikty i ryzyko utraty danych.

Moduł automatycznie konfiguruje:

- **S3 bucket** - bezpieczne przechowywanie plików stanu z wersjonowaniem
- **DynamoDB table** - blokowanie stanu podczas operacji (state locking)
- **Security** - zabezpieczenia dostępu i szyfrowanie

## Architektura

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Developer 1   │    │   Developer 2    │    │   Developer 3   │
│                 │    │                  │    │                 │
│ terraform apply │    │ terraform plan   │    │ terraform init  │
└─────────┬───────┘    └─────────┬────────┘    └─────────┬───────┘
          │                      │                       │
          ▼                      ▼                       ▼
    ┌─────────────────────────────────────────────────────────────┐
    │                    AWS Cloud                               │
    │                                                           │
    │  ┌─────────────────┐              ┌─────────────────────┐  │
    │  │   S3 Bucket     │              │   DynamoDB Table    │  │
    │  │                 │              │                     │  │
    │  │ terraform.state │◄────────────►│   State Locking     │  │
    │  │ (versioned)     │              │   (prevents conflicts)│  │
    │  └─────────────────┘              └─────────────────────┘  │
    └─────────────────────────────────────────────────────────────┘
```

## Jak używać

### 1. Bootstrap Process (pierwsze użycie)

Gdy tworzysz nowy projekt, musisz najpierw stworzyć infrastrukturę dla remote state:

```bash
# Stwórz folder dla bootstrap
mkdir -p environments/dev/terraform-state
cd environments/dev/terraform-state
```

### 2. Konfiguracja środowiska

**main.tf:**

```hcl
provider "aws" {
  region = var.region
}

module "terraform_state_bucket" {
  source = "../../../modules/terraform-state-bucket"
  
  environment        = var.environment
  region            = var.region
  bucket_name_suffix = var.bucket_name_suffix
}
```

**variables.tf:**

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "bucket_name_suffix" {
  description = "Unique suffix for bucket name"
  type        = string
  default     = "tk"
}
```

**outputs.tf:**

```hcl
output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = module.terraform_state_bucket.bucket_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.terraform_state_bucket.dynamodb_table_name
}

output "region" {
  description = "AWS region where resources are created"
  value       = module.terraform_state_bucket.region
}
```

### 3. Deployment bootstrap

```bash
# Inicjalizacja z lokalnym stanem
terraform init

# Sprawdzenie planu
terraform plan

# Deployment (tworzy bucket i table)
terraform apply
```

### 4. Migracja do remote state

Po udanym deployment, skonfiguruj backend:

**backend.tf:**

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-tk-dev-20250709222448939700000001"  # z outputs
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock-dev"  # z outputs
  }
}
```

Następnie migruj stan:

```bash
terraform init
# Terraform zapyta: "Do you want to copy existing state to the new backend?"
# Odpowiedz: yes
```

## Przykład użycia

```hcl
module "terraform_state_bucket" {
  source = "../../modules/terraform-state-bucket"
  
  environment        = "prod"
  region            = "eu-central-1"
  bucket_name_suffix = "company"
  table_name        = "terraform-locks"  # opcjonalne
}
```

Utworzy:

- S3 bucket: `terraform-state-company-prod-{random-suffix}`
- DynamoDB table: `terraform-locks-prod`
- Region: `eu-central-1`

## Zmienne

|Nazwa                      |Opis                                 |Typ     |Default                 |Required|
|---------------------------|-------------------------------------|--------|------------------------|--------|
|`environment`              |Nazwa środowiska (dev, staging, prod)|`string`|-                       |**TAK** |
|`region`                   |Region AWS gdzie będą tworzone zasoby|`string`|-                       |**TAK** |
|`bucket_name_suffix`       |Unikalny sufiks dla nazwy bucket     |`string`|-                       |**TAK** |
|`table_name`               |Nazwa tabeli DynamoDB                |`string`|`"terraform-state-lock"`|NIE     |
|`lifecycle_expiration_days`|Dni po których usunąć stare wersje   |`number`|`90`                    |NIE     |
|`block_public_acls`        |Blokowanie publicznych ACL           |`bool`  |`true`                  |NIE     |
|`ignore_public_acls`       |Ignorowanie publicznych ACL          |`bool`  |`true`                  |NIE     |
|`block_public_policy`      |Blokowanie publicznych policy        |`bool`  |`true`                  |NIE     |
|`restrict_public_buckets`  |Ograniczanie dostępu publicznego     |`bool`  |`true`                  |NIE     |

## Outputs

|Nazwa                |Opis                                     |
|---------------------|-----------------------------------------|
|`bucket_name`        |Pełna nazwa utworzonego S3 bucket        |
|`dynamodb_table_name`|Nazwa tabeli DynamoDB                    |
|`region`             |Region AWS gdzie zostały utworzone zasoby|

## Ważne uwagi

### Lifecycle Management

- **30 dni** - pliki state przechodzą do GLACIER storage (tańsze)
- **90 dni** - stare wersje są automatycznie usuwane
- **Versioning** - pełna historia zmian z możliwością rollback
- **Cost optimization** - automatyczne przejścia między klasami storage

### Security

- **Bucket jest prywatny** - wszystkie public access blocked
- **Public access protection** - 4-poziomowa ochrona przed publicznym dostępem
- **Versioning włączone** - można przywrócić poprzednie wersje stanu
- **State locking** - zapobiega konfliktom podczas równoczesnej pracy
- **Access logging** - audit trail wszystkich operacji na bucket

### Infrastructure Features

- **Log bucket** - osobny bucket dla access logs i audit trail
- **Multi-tier storage** - STANDARD → GLACIER → DELETE workflow
- **Encryption** - server-side encryption dla wszystkich obiektów
- **Cross-region ready** - moduł działa w dowolnym regionie AWS

### Naming Convention

- **S3 bucket:** `terraform-state-{suffix}-{environment}-{random}`
- **DynamoDB table:** `{table_name}-{environment}`
- Nazwy są globnie unikalne dzięki random suffix

### Koszty

- **S3:** ~$0.023/GB/miesiąc (stan Terraform to zwykle KB)
- **DynamoDB:** Pay-per-request - praktycznie darmowe dla małych zespołów
- **Łączny koszt:** <$1/miesiąc dla typowego projektu

### Backup i Recovery

- **S3 versioning** - automatyczne backupy każdej zmiany stanu
- **GLACIER transition** - 30-dniowe archiwizowanie dla cost optimization
- **Lifecycle policy** - automatyczne czyszczenie po 90 dniach
- **Access logging** - pełny audit trail operacji
- **Cross-region replication** - można skonfigurować dla krytycznych projektów
- **Point-in-time recovery** - restore do dowolnej wersji w historii

## Bootstrap proces

1. **Chicken-and-egg problem:** Żeby mieć remote state, musisz najpierw stworzyć bucket, ale żeby stworzyć bucket przez Terraform, potrzebujesz state.
1. **Rozwiązanie:** Dwuetapowy proces:
- **Etap 1:** Stwórz bucket z lokalnym stanem
- **Etap 2:** Skonfiguruj backend i migruj stan do bucket
1. **Po migracji:** Lokalny `terraform.tfstate` nie jest już używany

## Troubleshooting

### Problem: “bucket name already exists”

S3 bucket names są globalne. Zmień `bucket_name_suffix` na unikalny lub użyj `bucket_prefix` dla automatycznego suffixu.

### Problem: “access denied”

Sprawdź AWS credentials: `aws sts get-caller-identity`

### Problem: “state locked”

Ktoś inny używa Terraform. Poczekaj lub sprawdź DynamoDB table for locks.

### Problem: “backend configuration changed”

Po zmianie backend.tf uruchom ponownie `terraform init`

### Problem: “lifecycle configuration errors”

Upewnij się że używasz najnowszego AWS providera (6.x) i masz `filter {}` w lifecycle rules.

### Problem: “log bucket creation failed”

Log bucket też musi mieć unikalną nazwę globalnie. Dodaj suffix do `log-state-${var.environment}`.

-----

**Utworzono:** 10.07.2025  
**Autor:** Tomasz Królik  
**Wersja modułu:** 2.0 (Enhanced)  
**Terraform:** >= 1.0  
**AWS Provider:** >= 6.0  
**Features:** Remote State + Lifecycle + Security + Logging