# Zadanie na Powtórzenie: Rebuild from Scratch 🔄

> **Cel:** Sprawdzenie zrozumienia przez odtworzenie infrastruktury od zera

## 🎯 Misja: Clone Production Environment

**Scenariusz:** Musisz utworzyć **identyczne środowisko staging** dla swojej infrastruktury dev. Wszystko od podstaw, bez kopiowania istniejących plików.

## 📋 **ZADANIE GŁÓWNE**

### 🚀 **Etap 1: Staging VPC (20 min)**

#### **1.1 Struktura do stworzenia:**
```
environments/staging/
├── backend.tf
├── provider.tf
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

#### **1.2 Wymagania VPC:**
- **Nazwa:** `staging-vpc`
- **CIDR:** `10.1.0.0/16` (różny od dev!)
- **Public subnets:** 
  - `staging-public-subnet-01` → `10.1.10.0/24` → `eu-west-1a`
  - `staging-public-subnet-02` → `10.1.11.0/24` → `eu-west-1b`
- **Private subnet:**
  - `staging-private-subnet-01` → `10.1.20.0/24` → `eu-west-1a`

#### **1.3 Remote State:**
- **S3 key:** `staging-vpc/terraform.tfstate`
- **Ten sam bucket** co dev (współdzielony)
- **Ten sam DynamoDB table**

### 🖥️ **Etap 2: Staging EC2 (30 min)**

#### **2.1 Struktura:**
```
environments/staging/ec2/
├── backend.tf
├── provider.tf
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

#### **2.2 Wymagania EC2:**
- **Module:** Użyj istniejący `modules/ec2_firewall`
- **Instances:**
  - `staging-web-server-01` → `eu-west-1a` → IP host: 15
  - `staging-web-server-02` → `eu-west-1b` → IP host: 16
- **Instance type:** `t3.nano` (tańsze od micro!)
- **Security Group:** `staging-servers-allow`

#### **2.3 Remote State:**
- **S3 key:** `staging-ec2/terraform.tfstate`

---

## 🧩 **WYZWANIA DODATKOWE**

### 🎯 **Challenge 1: Multi-Region (HARD)**
Stwórz **identyczne środowisko** w `eu-central-1`:
- Nowe AMI ID dla eu-central-1
- Nowe availability zones (1a, 1b)
- Osobny remote state

### 🎯 **Challenge 2: Cost Optimization**
- Użyj `t3.nano` zamiast `t3.micro`
- Tylko 1 instancja zamiast 2
- Scheduled start/stop (opcjonalnie)

### 🎯 **Challenge 3: Security Enhancement**
- SSH tylko z twojego IP (zamiast 0.0.0.0/0)
- Osobny Security Group dla staging
- Różne SSH key name

---

## 📝 **INSTRUKCJE KROK PO KROK**

### ⚙️ **Setup Git Branch**
```bash
git checkout main
git pull origin main
git checkout -b feature/staging-environment
```

### 🏗️ **Etap 1: Staging VPC**

#### **Krok 1: Folder structure**
```bash
cd ~/local_repo/DevOps-Learning/TerraForm/learning
mkdir -p environments/staging
cd environments/staging
```

#### **Krok 2: Backend configuration**
```bash
# Stwórz backend.tf
# PAMIĘTAJ: staging-vpc jako key!
```

#### **Krok 3: Provider setup**
```bash
# Stwórz provider.tf
# Region: eu-west-1
# AWS provider ~> 5.0
```

#### **Krok 4: Main resources**
```bash
# Stwórz main.tf z wywołaniem modułu VPC
# PAMIĘTAJ: Użyj modules/vpc (nie kopiuj kodu!)
```

#### **Krok 5: Variables & Values**
```bash
# Stwórz variables.tf (podobne do dev)
# Stwórz terraform.tfvars z wartościami staging
```

#### **Krok 6: Deploy VPC**
```bash
terraform init
terraform plan
terraform apply
```

### 🖥️ **Etap 2: Staging EC2**

#### **Krok 1: Folder setup**
```bash
mkdir ec2
cd ec2
```

#### **Krok 2: Konfiguracja plików**
```bash
# backend.tf → staging-ec2 jako key
# provider.tf → identical do VPC
# main.tf → module ec2_firewall call
# variables.tf → wszystkie potrzebne zmienne
# terraform.tfvars → staging values
```

#### **Krok 3: AMI lookup**
```bash
# Znajdź najnowsze Ubuntu AMI dla eu-west-1
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images[*].[ImageId,CreationDate]' \
  --output table | head -5
```

#### **Krok 4: Deploy EC2**
```bash
terraform init
terraform plan
terraform apply
```

---

## ✅ **CHECKLIST SUKCESU**

### 🏗️ **VPC Verification:**
- [ ] VPC `staging-vpc` istnieje w AWS
- [ ] 3 subnets z poprawnymi CIDR
- [ ] Internet Gateway podłączony
- [ ] Route tables skonfigurowane
- [ ] Remote state w S3 bucket

### 🖥️ **EC2 Verification:**
- [ ] 2 instancje w różnych AZ
- [ ] Security group z regułami SSH/HTTP/HTTPS
- [ ] SSH key pair utworzony
- [ ] Instancje mają publiczne IP
- [ ] SSH access działa

### 🧪 **Functional Testing:**
```bash
# Test SSH access
ssh -i ~/.ssh/id_rsa_AWS ubuntu@<staging-ip-1>
ssh -i ~/.ssh/id_rsa_AWS ubuntu@<staging-ip-2>

# Test networking
ping 8.8.8.8
curl -I http://google.com

# Check internal communication
ping <private-ip-other-instance>
```

---

## 🎯 **KRYTERIA OCENY**

### 📊 **Podstawowe (muszą być):**
- ✅ **Działające środowisko staging** - VPC + EC2
- ✅ **Proper isolation** - różne CIDR, nazwy, remote state
- ✅ **Modular approach** - użycie istniejących modułów
- ✅ **Git workflow** - feature branch + clean commits

### 🚀 **Zaawansowane (bonus points):**
- ✅ **Cost optimization** - t3.nano instead of t3.micro
- ✅ **Security enhancement** - restricted SSH access
- ✅ **Multi-region deployment** - dodatkowa lokalizacja
- ✅ **Documentation** - README dla staging environment

---

## 🕐 **TIMELINE SUGEROWANY**

### **Faza 1: Planning (10 min)**
- Przegląd istniejącej struktury dev
- Zaplanowanie różnic dla staging
- Setup git branch

### **Faza 2: VPC Deployment (20 min)**
- Konfiguracja plików
- Terraform init/plan/apply
- Verification w AWS Console

### **Faza 3: EC2 Deployment (30 min)**
- Module configuration
- AMI lookup i values setup
- Deployment + testing

### **Faza 4: Testing & Documentation (15 min)**
- SSH access verification
- Network connectivity tests
- Commit + dokumentacja

### **Total: ~75 minut**

---

## 🆘 **WSKAZÓWKI JEŚLI UTKNIESZ**

### ❌ **Problem: Terraform not finding module**
```bash
# Solution: Check relative path
source = "../../modules/vpc"  # From staging/ to modules/
```

### ❌ **Problem: Data source not finding VPC**
```bash
# Solution: Check naming convention
values = ["staging-vpc"]  # Not dev-vpc!
```

### ❌ **Problem: IP conflicts with dev**
```bash
# Solution: Different CIDR ranges
dev: 10.0.0.0/16
staging: 10.1.0.0/16
```

### ❌ **Problem: SSH key conflicts**
```bash
# Solution: Different key_name in terraform.tfvars
key_name = "tomasz-staging-tf"  # Not tomasz-tf
```

---

## 🏆 **SUCCESS CRITERIA**

Po ukończeniu będziesz miał:
- ✅ **Kompletne środowisko staging** działające równolegle do dev
- ✅ **Isolated infrastructure** - zero conflicts między środowiskami
- ✅ **Proven module reusability** - ten sam kod, różne konfiguracje
- ✅ **Professional workflow** - feature branch + proper commits
- ✅ **Hands-on confidence** - możesz odtworzyć infrastrukturę od zera

### 🎯 **Główna nauka:**
**"Jeśli potrafisz to odbudować, to znaczy że to naprawdę rozumiesz!"**

---

## 📤 **DELIVERABLES**

### 🔄 **Na koniec przygotuj:**
1. **Git commits** z czystą historią
2. **Screenshots** staging environment w AWS Console
3. **Terraform outputs** z obydwu environments (dev + staging)
4. **Brief summary** - co było łatwe, co trudne, czego się nauczyłeś

---

**🚀 Ready? Let's rebuild and solidify your Terraform skills!**

**Remember: To nie jest o tym żeby zrobić szybko - to o tym żeby zrozumieć każdy krok! 💪**