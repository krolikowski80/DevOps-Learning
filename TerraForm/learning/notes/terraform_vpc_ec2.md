# Terraform Multi-AZ VPC + EC2 - Kompletne Notatki Projektu

## 🎯 Przegląd Projektu

**Cel:** Zbudowanie production-ready multi-AZ VPC z instancjami EC2 używając Infrastructure as Code
**Czas trwania:** ~4 godziny intensywnej sesji
**Rezultat:** Działająca architektura 3-warstwowa (publiczny web + prywatne app/db) z remote state

## 🏗️ Finalna Architektura

```
┌─────────────────────────────────────────────────────────────────┐
│                    VPC: 10.0.0.0/16                            │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐ │
│  │ Public Subnet    │  │ Private Subnet   │  │ Private Subnet  │ │
│  │ 10.0.1.0/24      │  │ 10.0.10.0/24     │  │ 10.0.20.0/24    │ │
│  │ AZ: eu-central-1a│  │ AZ: eu-central-1b│  │ AZ: eu-central-1c│ │
│  │                  │  │                  │  │                 │ │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │  │ ┌─────────────┐ │ │
│  │ │ Public EC2   │ │  │ │ Private EC2  │ │  │ │ Private EC2 │ │ │
│  │ │ (Web/Bastion)│ │  │ │ (App Server) │ │  │ │ (Database)  │ │ │
│  │ │ Public IP ✅  │ │  │ │ Private IP   │ │  │ │ Private IP  │ │ │
│  │ └──────────────┘ │  │ └──────────────┘ │  │ └─────────────┘ │ │
│  └─────────┬────────┘  └─────────┬────────┘  └─────────┬───────┘ │
│            │                     │                     │         │
│    ┌───────▼───────┐     ┌───────▼─────────────────────▼───────┐ │
│    │ Internet      │     │ NAT Gateway                        │ │
│    │ Gateway       │     │ (dostęp do internetu dla private)  │ │
│    └───────────────┘     └─────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Struktura Projektu

```
learning/
├── terraform-state/              # Bootstrap - infrastruktura dla shared state
│   ├── main.tf                   # S3 bucket + DynamoDB table
│   ├── variables.tf               # Region, bucket suffix, environment
│   ├── outputs.tf                # Nazwa bucket, nazwa tabeli, template backend
│   ├── terraform.tfvars           # environment="shared", region="eu-central-1"
│   └── provider.tf                # AWS provider bez remote backend
├── envs/dev/                     # Środowisko deweloperskie
│   ├── main.tf                   # Wywołania modułów VPC + EC2
│   ├── variables.tf               # Zmienne specyficzne dla środowiska
│   ├── terraform.tfvars           # Konkretne wartości dla dev
│   ├── outputs.tf                # Outputy infrastruktury
│   ├── provider.tf                # AWS provider z domyślnymi tagami
│   └── backend.tf                 # Konfiguracja remote state
└── modules/                      # Reużywalne moduły infrastruktury
    ├── terraform-state-bucket/   # S3 + DynamoDB dla remote state
    │   ├── main.tf               # Bucket z versioning, lifecycle, security
    │   ├── variables.tf          # Environment, region, bucket suffix
    │   └── outputs.tf            # Szczegóły bucket dla konfiguracji backend
    ├── vpc/                      # Infrastruktura sieciowa
    │   ├── main.tf               # VPC, subnety, IGW, NAT, routing
    │   ├── variables.tf          # Parametry konfiguracji sieci
    │   └── outputs.tf            # VPC ID, ID subnetów dla modułu EC2
    └── ec2/                      # Infrastruktura obliczeniowa
        ├── main.tf               # Instancje EC2, security groups, pary kluczy
        ├── variables.tf          # Konfiguracja instancji, inputy sieciowe
        └── outputs.tf            # IP instancji, ID dla połączenia
```

## 🔧 Kluczowe Decyzje Techniczne

### **1. Architektura Remote State (Podejście Enterprise)**
- **Jeden S3 bucket** dla wszystkich środowisk: `terraform-state-tk-20250723200542692400000001`
- **Różne klucze** per środowisko: `dev/`, `staging/`, `prod/`
- **Wspólna tabela DynamoDB:** `terraform-state-lock-shared` dla blokowania stanu
- **Dlaczego:** Opłacalne, scentralizowane zarządzanie, ta sama izolacja bezpieczeństwa

### **2. Design Sieci**
- **VPC CIDR:** `10.0.0.0/16` (~65k adresów IP)
- **Deployment Multi-AZ:** Wysoka dostępność przez 3 strefy
- **Strategia subnetów:**
  - Public: `10.0.1.0/24` (warstwa web, load balancery, NAT Gateway)
  - Private: `10.0.10.0/24`, `10.0.20.0/24` (warstwa app, warstwa bazy danych)
- **NAT Gateway:** Jedna instancja dla optymalizacji kosztów w dev ($45/miesiąc)

### **3. Wzorce Designu Modułów**
- **for_each zamiast count:** Eksplicytne mapowanie subnetów eliminuje błędy indeksów
- **Zmienne oparte na mapach:** `public_subnets = { "web" = { cidr, az } }`
- **Dynamiczne outputy:** Umożliwiają elastyczne wykorzystanie infrastruktury
- **Konsekwentne nazewnictwo:** `projekt-środowisko-zasób-cel`

### **4. Implementacja Bezpieczeństwa**
- **Wzorzec bastion host:** Dostęp SSH do instancji prywatnych tylko przez publiczną
- **Izolacja security group:** Public (SSH+HTTP z internetu), Private (SSH tylko z public)
- **Brak zakodowanych poświadczeń:** Używa AWS credentials provider chain
- **Bezpieczeństwo S3 bucket:** Zablokowany dostęp publiczny, włączone versioning

## 💡 Krytyczne Nauki

### **Rozwój Modułu VPC**
```hcl
# ❌ Źle: Podejście oparte na count podatne na błędy
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  availability_zone = var.availability_zones[count.index]  # Może się nie udać!
}

# ✅ Dobrze: for_each z eksplicytnym mapowaniem
resource "aws_subnet" "public" {
  for_each = var.public_subnets
  cidr_block = each.value.cidr_block
  availability_zone = each.value.availability_zone
}
```

### **Proces Bootstrap Remote State**
1. **Stwórz state bucket** z lokalnym stanem (problem kury i jajka)
2. **Deploy bucket + DynamoDB** używając terraform-state-bucket module
3. **Konfiguruj backend.tf** w środowiskach ze szczegółami bucket
4. **Migruj lokalny stan** do S3 z `terraform init`
5. **Usuń lokalne pliki state** po udanej migracji

### **Uniknięte Typowe Pułapki**
- **Duplikacja provider:** Nie definiuj AWS provider w main.tf i provider.tf
- **Konflikty nazw:** Używaj prefiksów/sufiksów aby uniknąć kolizji nazw zasobów
- **Problemy ścieżek:** Zawsze weryfikuj że ścieżki źródłowe modułów są poprawne
- **Niezgodności zmiennych:** Upewnij się że zmienne modułu pasują do argumentów wywołujących

## 🚀 Rezultaty Deploymentu

### **Utworzona Infrastruktura**
```bash
# Moduł VPC (15 zasobów)
- 1x VPC (10.0.0.0/16)
- 3x Subnety (1 public, 2 private)
- 1x Internet Gateway
- 1x NAT Gateway + Elastic IP
- 3x Route Tables + Skojarzenia

# Moduł EC2 (6 zasobów)  
- 3x Instancje EC2 (t3.micro)
- 2x Security Groups
- 1x Para Kluczy

# Infrastruktura State (5 zasobów)
- 1x S3 Bucket (z wersjami, zabezpieczony)
- 1x Tabela DynamoDB (blokowanie stanu)
- 3x Konfiguracje S3 (lifecycle, versioning, public access block)
```

### **Komendy Weryfikacji**
```bash
# Sprawdź stan infrastruktury
terraform state list

# Zobacz outputy
terraform output

# Testuj łączność (po deploymencie)
ssh -i ~/.ssh/id_rsa_AWS ubuntu@<public_ip>  # Instancja publiczna
ssh -J ubuntu@<public_ip> ubuntu@<private_ip>  # Prywatna przez bastion
```

## 💰 Analiza Kosztów

### **Miesięczne Koszty Operacyjne**
- **NAT Gateway:** ~$45/miesiąc (największy składnik kosztów)
- **Instancje EC2:** 3x t3.micro = ~$15/miesiąc (jeśli działają 24/7)
- **Storage S3:** ~$1/miesiąc (pliki terraform state)
- **DynamoDB:** <$1/miesiąc (płatność za żądanie dla blokowania stanu)
- **Transfer Danych:** Zmienny w zależności od użytkowania
- **Razem:** ~$60-70/miesiąc dla środowiska dev

### **Strategie Optymalizacji Kosztów**
```hcl
# Środowisko dev - oszczędności kosztów
enable_nat_gateway = false        # Wyłącz NAT aby zaoszczędzić $45/miesiąc
single_nat_gateway = true         # Jeden NAT vs per-AZ dla dev
instance_type = "t3.micro"        # Najmniejsza instancja zdolna do produkcji

# Środowisko produkcyjne - wysoka dostępność
enable_nat_gateway = true
single_nat_gateway = false        # NAT per AZ dla redundancji
instance_type = "t3.small"        # Odpowiednio zwymiarowany dla obciążenia produkcyjnego
```

## 🔍 Przewodnik Rozwiązywania Problemów

### **Typowe Problemy i Rozwiązania**

#### **1. Błędy Ścieżek Modułów**
```bash
Error: Unreadable module directory
```
**Rozwiązanie:** Zweryfikuj ścieżki źródłowe modułów: `ls -la ../modules/nazwa-modułu/`

#### **2. Problemy z Blokowaniem Stanu**
```bash
Error: Error acquiring the state lock
```
**Rozwiązanie:** 
```bash
terraform force-unlock <lock-id>
# Lub sprawdź tabelę DynamoDB dla zablokowanych locks
```

#### **3. Problemy z Kluczami SSH**
```bash
Error: file function call failed
```
**Rozwiązanie:** Zweryfikuj że klucz SSH istnieje: `ls -la ~/.ssh/id_rsa_AWS.pub`

#### **4. Niezgodności Zmiennych**
```bash
Error: Missing required argument
```
**Rozwiązanie:** Upewnij się że wszystkie zmienne modułu są przekazane ze środowiska

### **Komendy Debugowania**
```bash
# Renderowanie szablonów
terraform plan -out=plan.out
terraform show plan.out

# Inspekcja stanu  
terraform state show <zasób>
terraform state list | grep <filtr>

# Debugowanie provider
export TF_LOG=DEBUG
terraform apply

# Walidacja modułu
terraform validate
terraform fmt -recursive
```

## 🔄 Możliwości Rozszerzenia

### **Natychmiastowe Następne Kroki**
1. **Dodaj outputy** do `envs/dev/outputs.tf` dla IP EC2
2. **Deploy i testuj** łączność między instancjami
3. **Zainstaluj aplikacje** na instancjach EC2 dla testów funkcjonalnych
4. **Implementuj monitoring** z CloudWatch lub zewnętrznymi narzędziami

### **Zaawansowane Funkcje do Dodania**
```hcl
# Load Balancer
module "alb" {
  source = "../../modules/alb"
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  target_instance_ids = [module.ec2.public_instance_id]
}

# Baza Danych
module "rds" {
  source = "../../modules/rds"
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_ids = [module.ec2.private_security_group_id]
}

# Auto Scaling
module "asg" {
  source = "../../modules/asg"
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  ami_id = module.ec2.ami_id
}
```

### **Checklist Gotowości Produkcyjnej**
- [ ] **Multi-AZ NAT Gateways** dla wysokiej dostępności
- [ ] **Application Load Balancer** dla dystrybucji ruchu  
- [ ] **Auto Scaling Groups** dla elastyczności
- [ ] **RDS Multi-AZ** dla niezawodności bazy danych
- [ ] **Monitoring CloudWatch** i alerting
- [ ] **VPC Flow Logs** dla monitoringu sieci
- [ ] **AWS Config** dla monitoringu compliance
- [ ] **Strategie backup** dla zasobów stateful

## 📚 Zastosowane Najlepsze Praktyki

### **Infrastructure as Code**
- ✅ **Kontrola wersji** - cały kod w Git
- ✅ **Design modularny** - reużywalne komponenty
- ✅ **Separacja środowisk** - izolacja dev/staging/prod
- ✅ **Dokumentacja** - kompleksowe komentarze i pliki README
- ✅ **Konsekwentne nazewnictwo** - przewidywalne nazwy zasobów

### **Bezpieczeństwo**
- ✅ **Dostęp najmniejszych uprawnień** - security groups z minimalnym niezbędnym dostępem
- ✅ **Prywatne zasoby** - bazy danych i aplikacje w prywatnych subnetach
- ✅ **Wzorzec bastion host** - kontrolowany dostęp do prywatnych zasobów
- ✅ **Zaszyfrowany stan** - S3 bucket z szyfrowaniem po stronie serwera
- ✅ **Brak zakodowanych sekretów** - używanie AWS credential provider chain

### **Doskonałość Operacyjna**
- ✅ **Remote state** - włączona współpraca zespołowa
- ✅ **Blokowanie stanu** - zapobiega równoczesnym modyfikacjom
- ✅ **Strategia tagowania** - śledzenie kosztów i zarządzanie zasobami
- ✅ **Zarządzanie cyklem życia** - automatyczne czyszczenie starych wersji stanu
- ✅ **Obsługa błędów** - walidacja i zarządzanie zależnościami

## 🎯 Metryki Sukcesu

### **Osiągnięcia Techniczne**
- [x] **Architektura Multi-AZ** - design wysokiej dostępności
- [x] **Bezpieczny design sieci** - właściwa izolacja i kontrole dostępu  
- [x] **Automatyzacja infrastruktury** - infrastruktura w pełni zdefiniowana kodem
- [x] **Zarządzanie remote state** - gotowe do współpracy zespołowej
- [x] **Architektura modularna** - reużywalny i łatwy w utrzymaniu kod

### **Rezultaty Nauki**
- [x] **Rozwój modułów Terraform** - od zera do produkcji
- [x] **Mistrzostwo sieci AWS** - VPC, subnety, routing, NAT
- [x] **Najlepsze praktyki bezpieczeństwa** - implementacja obrony w głąb
- [x] **Zarządzanie stanem** - setup i migracja remote backend
- [x] **Umiejętności rozwiązywania problemów** - debugowanie złożonych problemów infrastruktury

### **Umiejętności Zawodowe**
- [x] **Dokumentacja** - kompleksowa dokumentacja projektu
- [x] **Organizacja kodu** - czysta, utrzymywalna struktura
- [x] **Rozwiązywanie problemów** - systematyczne podejście do złożonych wyzwań
- [x] **Najlepsze praktyki** - implementacje standardów branżowych
- [x] **Świadomość kosztów** - zrozumienie implikacji cenowych AWS

---

**Zakończenie Projektu:** Multi-AZ VPC z instancjami EC2 deploy pomyślnie  
**Czas trwania:** ~4 godziny od koncepcji do deploymentu  
**Status:** Fundament gotowy do produkcji dla deploymentu aplikacji  
**Następna Faza:** Deployment aplikacji i setup monitoringu

*Utworzono: 23 lipca 2025*  
*Autor: Tomasz Królik*  
*Sesja: Implementacja Terraform Multi-AZ VPC + EC2*