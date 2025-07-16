# DevOps Learning Journey 🚀

> Praktyczna nauka Terraform, AWS i Kubernetes przez budowanie prawdziwej infrastruktury

## 🎯 O projekcie

Repo do nauki DevOps przez praktyczne wdrażanie. Budujemy production-ready systemy z Infrastructure as Code, orkiestracją kontenerów i automatyzacją w chmurze.

## 🏗️ Obecna architektura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      VPC        │    │   EC2 Cluster   │    │   Monitoring    │
│   Multi-AZ      │────│  Load Balanced  │────│   CloudWatch    │
│  10.0.0.0/16    │    │   2x t3.micro   │    │   + Alerting    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## ⚡ Szybki start

```bash
# Sklonuj i przejdź do projektu
git clone <repo-url>
cd DevOps-Learning/TerraForm/learning

# Wdróż infrastrukturę VPC
cd environments/dev
terraform init && terraform apply

# Wdróż instancje EC2
cd ec2
terraform init && terraform apply
```

## 📁 Struktura projektu

```
TerraForm/learning/
├── modules/
│   ├── vpc/              # Moduł VPC do reużycia
│   ├── ec2_firewall/     # EC2 + Security Groups
│   └── terraform-state-bucket/  # Remote state setup
├── environments/
│   └── dev/
│       ├── vpc/          # Deployment VPC
│       ├── ec2/          # Deployment EC2
│       └── terraform-state/  # Bootstrap
└── AWS/cli-commands/
    └── aws_cli_cheatsheet.md
```

## 🛠️ Stack technologiczny

| Komponent | Technologia | Status |
|-----------|------------|--------|
| **IaC** | Terraform 1.12.2 | ✅ Produkcja |
| **Chmura** | AWS (eu-west-1) | ✅ Produkcja |
| **Compute** | EC2 Multi-AZ | ✅ Produkcja |
| **Sieć** | VPC + Security Groups | ✅ Produkcja |
| **Stan** | S3 + DynamoDB | ✅ Produkcja |
| **Monitoring** | CloudWatch | 🚧 W toku |
| **Kontenery** | Kubernetes | 📋 Planowane |

## 🚀 Wdrożona infrastruktura

### ✅ Production Ready
- **Sieć VPC:** Multi-AZ z publicznymi/prywatnymi podsieciami
- **Instancje EC2:** 2x t3.micro w różnych strefach dostępności
- **Bezpieczeństwo:** Zarządzanie kluczami SSH + reguły firewall
- **Wysoka dostępność:** Load balancing między AZ-a/b
- **Remote State:** Backend S3 z blokowaniem stanu

### 🎯 Obecne możliwości
- Dostęp SSH do instancji
- Obsługa ruchu HTTP/HTTPS
- Automatyczne provisioning z user_data
- Wersjonowanie infrastruktury
- Gotowe do pracy zespołowej

## 📊 Metryki i monitoring

```bash
# Sprawdź status deployment
terraform output

# Monitoruj koszty AWS
aws ce get-cost-and-usage --time-period Start=2025-07-01,End=2025-07-17 --granularity MONTHLY --metrics BlendedCost

# Test dostępu SSH
ssh -i ~/.ssh/id_rsa_AWS ubuntu@<public-ip>
```

## 🎓 Postęp nauki

### Ukończone ✅
- [x] Podstawy Terraform i moduły
- [x] Architektura sieci AWS VPC
- [x] Automatyzacja deployment EC2
- [x] Najlepsze praktyki Infrastructure as Code
- [x] Zarządzanie remote state
- [x] Wzorce multi-environment

### W toku 🚧
- [ ] Konfiguracja Application Load Balancer
- [ ] Monitoring i alerty CloudWatch
- [ ] Strategie automatycznego backupu
- [ ] Wzmocnienie bezpieczeństwa

### Następna faza 📋
- [ ] Deployment klastra Kubernetes
- [ ] Integracja pipeline CI/CD
- [ ] Orkiestracja kontenerów
- [ ] Workflow GitOps

## 🛡️ Bezpieczeństwo i najlepsze praktyki

- **🔐 Klucze SSH:** Zarządzane przez Terraform, w gitignore
- **🏷️ Tagowanie:** Spójna strategia tagowania zasobów
- **🔒 Sieć:** Security groups z najmniejszymi uprawnieniami
- **💾 Stan:** Szyfrowany backend S3 z blokowaniem
- **📝 Dokumentacja:** Dokumentacja Infrastructure as Code

## 🔧 Wymagania

```bash
# Wymagane narzędzia
terraform >= 1.12.2
aws-cli >= 2.x
kubectl >= 1.33.x
helm >= 3.18.x

# Skonfigurowane credentials AWS
aws configure
aws sts get-caller-identity
```

## 📚 Zasoby i dokumentacja

- **[AWS CLI Ściągawka](AWS/cli-commands/aws_cli_cheatsheet.md)** - Kompletna ściąga CLI
- **[Terraform Docs](https://developer.hashicorp.com/terraform)** - Oficjalna dokumentacja
- **[AWS Architecture](https://aws.amazon.com/architecture/)** - Przewodnik najlepszych praktyk

## 🎯 Cele projektu

- **Opanować Infrastructure as Code** z Terraform
- **Wdrażać production-grade** architektury AWS
- **Implementować najlepsze praktyki DevOps** dla automatyzacji
- **Budować skalowalne, bezpieczne** rozwiązania chmurowe
- **Dokumentować naukę** na przyszłość

## 📈 Timeline projektu

**Czerwiec 2025:** ✅ Podstawy VPC + EC2  
**Lipiec 2025:** 🚧 Load balancing + monitoring  
**Sierpień 2025:** 📋 Kubernetes + containers  
**Wrzesień-Grudzień 2025:** 📋 Advanced DevOps + certyfikacje

---

**⭐ Gwiazdka jeśli pomoże Ci w Twojej drodze DevOps!**