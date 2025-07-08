# Terraform VPC Module - Notatki Techniczno-Praktyczne

---

## 🏗️ Architektura Modułowa - Podział Odpowiedzialności

### Moduł vs Środowisko - Kluczowe Rozróżnienie

**Moduł = Szablon Infrastruktury**
```
modules/vpc/
├── main.tf       # Definicje zasobów + logika
├── variables.tf  # Kontrakt interfejsu wejściowego
└── outputs.tf    # Interfejs wartości zwracanych
```
- **Zawiera:** Implementację techniczną (jak zbudować VPC)
- **Nie zawiera:** Konkretnych wartości (wartości dla konkretnego środowiska)
- **Odpowiedzialność:** Wzorce infrastruktury nadające się do ponownego użycia

**Środowisko = Instancja Konfiguracji**
```
environments/dev/
├── main.tf           # Wywołanie modułu z parametrami
├── variables.tf      # Definicje zmiennych środowiska
├── terraform.tfvars  # Rzeczywiste wartości dla tego środowiska
└── provider.tf       # Konfiguracja providera AWS
```
- **Zawiera:** Wymagania biznesowe (co ma być zbudowane)
- **Nie zawiera:** Szczegółów implementacji (jak to zbudować)
- **Odpowiedzialność:** Konfiguracja specyficzna dla środowiska

### Architektura Przepływu Danych
```
terraform.tfvars → variables.tf → main.tf → moduł → Zasoby AWS
```

**1. Warstwa Wartości** - konkretne wartości środowiska  
**2. Warstwa Interfejsu** - definicje i walidacja typów  
**3. Warstwa Orkiestracji** - wywołanie modułu z parametrami  
**4. Warstwa Implementacji** - faktyczne tworzenie zasobów AWS  

---

## 🔄 Wzorzec Ewolucji - Redukcja Długu Technicznego

### Antywzorzec: Prymitywne Tablice
```hcl
# Problematyczne podejście - silne sprzężenie
subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
aws_availability_zones = ["eu-west-1a", "eu-west-1b"]

# Problemy:
# - Zależności długości tablic (sprzężenie przez indeks)
# - Relacje niejawne (oparte na pozycji)
# - Błędy runtime (indeks poza zakresem)
# - Słaba łatwość utrzymania (piekło równoległych tablic)
```

**Scenariusz Błędu Runtime:**
```hcl
subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]  # długość: 3
availability_zones = ["eu-west-1a", "eu-west-1b"]             # długość: 2

# for_each tworzy klucze: 0, 1, 2
# availability_zones[2] = IndexError → terraform apply kończy się niepowodzeniem
```

### Wzorzec Profesjonalny: Obiekty Strukturalne
```hcl
# Podejście enterprise - jawna konfiguracja
public_subnets = {
  "dev-public-01" = {
    cidr                    = "10.0.1.0/24"
    availability_zone       = "eu-west-1a"
    map_public_ip_on_launch = true
  },
  "dev-public-02" = {
    cidr                    = "10.0.2.0/24"  
    availability_zone       = "eu-west-1b"
    map_public_ip_on_launch = true
  }
}

# Korzyści:
# ✅ Samodzielne obiekty - brak zewnętrznych zależności
# ✅ Walidacja bezpieczna typowo - wykrywanie błędów w czasie kompilacji
# ✅ Samodokumentujący - semantyczna konwencja nazewnictwa
# ✅ Skalowalny - łatwe dodawanie/usuwanie zasobów
# ✅ Łatwy w utrzymaniu - jasne relacje obiektów
```

---

## 🔧 Zaawansowane Wzorce Terraform

### 1. Implementacja Bezpieczeństwa Typów
```hcl
variable "public_subnets" {
  description = "Mapa publicznych podsieci z pełną konfiguracją"
  type = map(object({
    cidr                    = string
    availability_zone       = string
    map_public_ip_on_launch = bool
  }))
  
  validation {
    condition = can([for k, v in var.public_subnets : cidrhost(v.cidr, 0)])
    error_message = "Wszystkie bloki CIDR muszą być w poprawnej notacji IPv4 CIDR."
  }
}
```

**Korzyści Bezpieczeństwa Typów:**
- **Walidacja w czasie kompilacji** - błędy wychwycone przed apply
- **Wsparcie IDE** - autocompletowanie i sprawdzanie składni
- **Dokumentacja** - struktura służy jako specyfikacja
- **Bezpieczeństwo refaktoryzacji** - zmiany łamiące wykrywane wcześnie

### 2. Wzorzec for_each z Mapami
```hcl
resource "aws_subnet" "public_subnet" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.map_public_ip_on_launch
  
  tags = {
    Name = each.key  # Używa klucza mapy jako identyfikatora zasobu
    Type = "public"
    Environment = var.name
  }
}
```

**Zalety for_each nad count:**
- **Stabilne adresy zasobów** - zasoby kluczowane znaczącymi nazwami
- **Selektywne aktualizacje** - zmiany wpływają tylko na zmodyfikowane zasoby  
- **Brak przesunięć indeksów** - usunięcie środkowego elementu nie przekłada numerów innych
- **Jasne relacje** - jawne mapowanie między konfiguracją a zasobami

### 3. Wzorce Kolekcjonowania Wyjść
```hcl
# Składowanie list dla ID zasobów
output "public_subnet_ids" {
  description = "Lista ID publicznych podsieci"
  value = [for subnet in aws_subnet.public_subnet : subnet.id]
}

# Składowanie map dla mapowania CIDR
output "subnet_cidr_mapping" {
  description = "Mapa nazw podsieci do bloków CIDR"
  value = {
    for k, v in aws_subnet.public_subnet : k => v.cidr_block
  }
}

# Wyjście warunkowe oparte na istnieniu zasobu
output "internet_gateway_id" {
  description = "ID Internet Gateway jeśli utworzone"
  value = length(var.public_subnets) > 0 ? aws_internet_gateway.igw[0].id : null
}
```

---

## 🌐 Strategia Infrastruktury Wielośrodowiskowej

### Wzorce Izolacji Środowisk

**Izolacja Fizyczna:**
```hcl
# dev: eu-west-1, 10.0.0.0/16
# prod: eu-central-1, 10.1.0.0/16
# staging: us-east-1, 10.2.0.0/16
```

**Izolacja Stanu:**
- **Oddzielne pliki stanu** - każde środowisko ma własny .tfstate
- **Różne backendy** - możliwe różne buckety S3 per środowisko
- **Kontrola dostępu** - różne uprawnienia IAM per środowisko

**Izolacja Konfiguracji:**
```hcl
# environments/dev/terraform.tfvars
name = "dev"
cidr_block = "10.0.0.0/16"
public_subnets = {
  "dev-public-01" = { cidr = "10.0.1.0/24", ... }
}

# environments/prod/terraform.tfvars  
name = "prod"
cidr_block = "10.1.0.0/16"
public_subnets = {
  "prod-public-01" = { cidr = "10.1.1.0/24", ... }
  "prod-public-02" = { cidr = "10.1.2.0/24", ... }
  "prod-public-03" = { cidr = "10.1.3.0/24", ... }  # Więcej podsieci dla HA
}
```

### Implementacja Ponownego Użycia Modułu

**Pojedyncze Źródło Prawdy:**
```hcl
# modules/vpc/main.tf - jeden moduł dla wszystkich środowisk
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "${var.name}-vpc"
    Description = var.description
    Environment = var.name
  }
}
```

**Wywołanie Specyficzne dla Środowiska:**
```hcl
# environments/*/main.tf - różne parametry, ten sam moduł
module "vpc" {
  source = "../../modules/vpc"
  
  name            = var.name
  description     = var.description
  cidr_block      = var.cidr_block
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}
```

---

## 🔍 Głębokie Zanurzenie w Sieciach AWS

### Komponenty Architektury VPC

**Wirtualna Chmura Prywatna (VPC):**
```hcl
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block        # Przestrzeń adresów IP (10.0.0.0/16)
  enable_dns_support   = true                 # Rozwiązywanie DNS Amazon
  enable_dns_hostnames = true                 # Nazwy hostów DNS dla instancji
  instance_tenancy     = "default"            # Sprzęt współdzielony (vs dedykowany)
}
```

**Strategia Projektowania Podsieci:**
- **Podsieci Publiczne:** Bezpośrednie routing internetowy przez Internet Gateway
- **Podsieci Prywatne:** Brak bezpośredniego dostępu do internetu (tylko wewnętrzny lub NAT Gateway)
- **Wdrożenie Multi-AZ:** Wysoka dostępność w różnych strefach dostępności

**Internet Gateway:**
```hcl
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  # Zapewnia łączność internetową dla podsieci publicznych
  # Bezstanowy - kieruje ruch dwukierunkowo
  # Brak ograniczeń przepustowości ani ryzyka dostępności
}
```

**Tabele Routingu i Powiązania:**
```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"                    # Trasa domyślna (cały ruch)
    gateway_id = aws_internet_gateway.igw.id    # Przez Internet Gateway
  }
  
  # Trasa lokalna automatycznie utworzona dla CIDR VPC
}

resource "aws_route_table_association" "public_association" {
  for_each       = var.public_subnets
  subnet_id      = aws_subnet.public_subnet[each.key].id
  route_table_id = aws_route_table.public.id
  # Kojarzy podsieć z tabelą routingu = definiuje routing ruchu
}
```

---

## 🚨 Wyeliminowane Antywzorce

### 1. Piekło Indeksów Tablic
**Problem:**
```hcl
# Kruche - tablice muszą pozostać zsynchronizowane
resource "aws_subnet" "main" {
  count             = length(var.subnet_cidrs)
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]  # Ryzyko błędu runtime
  # Jeśli tablice mają różne długości → indeks poza zakresem
}
```

**Rozwiązanie:**
```hcl
# Solidne - samodzielne obiekty
resource "aws_subnet" "public_subnet" {
  for_each          = var.public_subnets
  cidr_block        = each.value.cidr           # Jawny dostęp do właściwości
  availability_zone = each.value.availability_zone  # Brak zależności od indeksów
}
```

### 2. Antywzorzec Duplikacji Zmiennych
**Problem:**
```hcl
# Potrójny ciężar utrzymania:
# 1. environments/dev/variables.tf
# 2. environments/dev/terraform.tfvars  
# 3. modules/vpc/variables.tf
# Te same definicje zmiennych w wielu miejscach = koszmar utrzymania
```

**Rozwiązanie:**
```hcl
# Czysty przepływ danych:
# terraform.tfvars → variables.tf → wywołanie modułu
# Każda warstwa ma pojedynczą odpowiedzialność
```

### 3. Antywzorzec Zakodowanych Wartości
**Problem:**
```hcl
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"  # Zakodowane - brak elastyczności
  tags = {
    Name = "dev-vpc"          # Specyficzne dla środowiska zakodowane
  }
}
```

**Rozwiązanie:**
```hcl
resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block  # Sparametryzowane - nadające się do ponownego użycia
  tags = {
    Name = "${var.name}-vpc"   # Dynamiczne - działa dla każdego środowiska
  }
}
```

---

## 💡 Zaawansowane Wzorce Konfiguracji

### 1. Warunkowe Tworzenie Zasobów
```hcl
# Utwórz Internet Gateway tylko jeśli istnieją podsieci publiczne
resource "aws_internet_gateway" "igw" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id
}

# Odwołanie z warunkowym indeksowaniem
resource "aws_route_table" "public" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }
}
```

### 2. Bloki Dynamiczne dla Złożonych Obiektów
```hcl
resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  
  # Blok dynamiczny dla opcjonalnych drugorzędnych bloków CIDR
  dynamic "secondary_cidr_blocks" {
    for_each = var.secondary_cidrs
    content {
      cidr_block = secondary_cidr_blocks.value
    }
  }
}
```

### 3. Wartości Lokalne dla Właściwości Obliczanych
```hcl
locals {
  # Oblicz wszystkie używane strefy dostępności
  all_azs = distinct(concat(
    [for subnet in var.public_subnets : subnet.availability_zone],
    [for subnet in var.private_subnets : subnet.availability_zone]
  ))
  
  # Generuj wspólne tagi
  common_tags = {
    Environment = var.name
    Project     = "vpc-infrastructure"
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "public_subnet" {
  for_each          = var.public_subnets
  # ... konfiguracja zasobu ...
  
  tags = merge(local.common_tags, {
    Name = each.key
    Type = "public"
  })
}
```

---

## 🎯 Profesjonalne Najlepsze Praktyki

### 1. Konwencje Nazewnictwa Zmiennych
```hcl
# Dobre: Opisowe i spójne
variable "public_subnets" { ... }    # Jasny zakres i cel
variable "enable_nat_gateway" { ... } # Konwencja prefiksu boolean

# Złe: Niejednoznaczne lub niespójne  
variable "subnets" { ... }           # Który typ podsieci?
variable "nat" { ... }               # Niejasne co to kontroluje
```

### 2. Standardy Nazewnictwa Zasobów
```hcl
# Wzorzec: {środowisko}-{komponent}-{identyfikator}
resource "aws_subnet" "public_subnet" {
  tags = {
    Name = "${var.name}-public-${substr(each.value.availability_zone, -1, 1)}"
    # Rezultat: dev-public-a, dev-public-b, prod-public-a, etc.
  }
}
```

### 3. Dokumentacja w Kodzie
```hcl
variable "public_subnets" {
  description = <<-EOT
    Mapa podsieci publicznych do utworzenia. Każda podsieć wymaga:
    - cidr: Blok CIDR dla podsieci (musi być w obrębie CIDR VPC)
    - availability_zone: Strefa dostępności AWS gdzie podsieć zostanie utworzona
    - map_public_ip_on_launch: Czy instancje otrzymują publiczne IP automatycznie
    
    Przykład:
    {
      "web-public-1a" = {
        cidr                    = "10.0.1.0/24"
        availability_zone       = "us-west-2a"
        map_public_ip_on_launch = true
      }
    }
  EOT
  
  type = map(object({
    cidr                    = string
    availability_zone       = string
    map_public_ip_on_launch = bool
  }))
}
```

### 4. Organizacja Wyjść
```hcl
# Oddzielne wyjścia według przedmiotu
output "vpc_info" {
  description = "Informacje identyfikacyjne i sieciowe VPC"
  value = {
    vpc_id         = aws_vpc.vpc.id
    vpc_cidr       = aws_vpc.vpc.cidr_block
    vpc_arn        = aws_vpc.vpc.arn
  }
}

output "public_networking" {
  description = "Informacje sieciowe podsieci publicznych"
  value = {
    subnet_ids = [for subnet in aws_subnet.public_subnet : subnet.id]
    route_table_id = length(aws_route_table.public) > 0 ? aws_route_table.public[0].id : null
    internet_gateway_id = length(aws_internet_gateway.igw) > 0 ? aws_internet_gateway.igw[0].id : null
  }
}
```

---

## 🚀 Architektura Następnego Poziomu

### Strategia Kompozycji Modułów
```hcl
# Obecnie: Monolityczny moduł VPC
module "vpc" {
  source = "./modules/vpc"
  # Cała sieć w jednym module
}

# Przyszłość: Architektura skomponowana
module "vpc_core" {
  source = "./modules/vpc-core"  # VPC + podstawowe podsieci
}

module "vpc_security" {
  source = "./modules/vpc-security"  # Grupy bezpieczeństwa + NACL
  vpc_id = module.vpc_core.vpc_id
}

module "vpc_endpoints" {
  source = "./modules/vpc-endpoints"  # Endpointy VPC dla usług AWS
  vpc_id = module.vpc_core.vpc_id
  private_subnet_ids = module.vpc_core.private_subnet_ids
}
```

### Integracja Zdalnego Stanu
```hcl
# Przyszłość: Udostępnianie stanu między modułami
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "company-terraform-state"
    key    = "vpc/${var.environment}/terraform.tfstate"
    region = "eu-west-1"
  }
}

# Użyj VPC z różnej konfiguracji Terraform
resource "aws_instance" "app" {
  subnet_id = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  # ...
}
```

---

## 🏆 Podsumowanie

### Architektura Infrastruktury:
- ✅ **Projekt modułowy** - separacja szablonu vs konfiguracji
- ✅ **Konfiguracja bezpieczna typowo** - walidacja w czasie kompilacji
- ✅ **Wsparcie wielośrodowiskowe** - izolacja dev/prod z ponownym użyciem
- ✅ **Profesjonalna sieć** - architektura podsieci publicznych/prywatnych

### Inżynieria Terraform:
- ✅ **Zaawansowane struktury danych** - map(object()) nad prymitywnymi tablicami
- ✅ **Dynamiczne tworzenie zasobów** - wzorce for_each ze znaczącymi kluczami
- ✅ **Logika warunkowa** - zasoby tworzone na podstawie konfiguracji
- ✅ **Kolekcjonowanie wyjść** - składanie list/map dla agregacji danych

### Praktyki DevOps:
- ✅ **Zasada DRY** - pojedynczy moduł, wiele środowisk
- ✅ **Infrastruktura jako Kod** - wdrożenia kontrolowane wersją, powtarzalne
- ✅ **Zarządzanie konfiguracją** - wartości specyficzne dla środowiska zewnętrzne
- ✅ **Zapobieganie błędom** - wzorce projektowe eliminujące częste błędy
