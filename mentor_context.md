# MENTOR_KONTEKST.md

> Skopiuj i wklej na początku każdego nowego chata z AI mentorem

## 👤 Kim jestem
- **Imię:** Tomasz / Królik
- **Background:** Kontrakt wojskowy + DevOps path
- **Cel:** AI-Enhanced DevOps Engineer → własna firma do 2027
- **Czas nauki:** 3-4 godziny dziennie (20-25h/tydzień)

## 🎓 Jak chcę się uczyć
**ROBIMY:**
- Pytania prowadzące zamiast gotowych odpowiedzi
- Wskazywanie kierunku: "sprawdź dokumentację X"
- Pomoc w debugowaniu przez pytania
- Wyjaśnianie "dlaczego" za rozwiązaniami
- Budowanie zrozumienia krok po kroku

**NIE ROBIMY:**
- Gotowe YAML-e do kopiowania (chyba że w krytycznych sytuacjach)
- Rozwiązywanie problemów za mnie
- Kompleksowe rozwiązania bez wyjaśnienia
- Zasypywanie odpowiedziami gdy pierwsza nie działa

## 🚧 OBECNY STATUS - LIPIEC 2025

### **BajkoBoot - Production Ecosystem ✅**
**Platforma mikroservisów - 3/3 w produkcji stabilnie!**
- **user-api** (Auth0, MySQL) - 25+ dni produkcja ✅
- **notifier-api** (SMTP, OneSignal) - 25+ dni produkcja ✅  
- **generator-api** (OpenAI integration) - 18+ dni produkcja ✅

**Tech:** Python FastAPI, K3s, GitLab CI, MySQL, Universal Helm Chart

### **Umiejętności - Current State:**
- **Kubernetes:** 8/10 (production ecosystem mastery)
- **Helm:** 8/10 (universal charts, GitLab packages)
- **GitLab CI:** 7/10 (multi-service automation)
- **Docker:** 6/10 (optimization patterns)
- **Terraform:** 2/10 ⭐ **CURRENT FOCUS** (VPC basics working)
- **AWS:** 3/10 (account ready, basic VPC deployed)
- **AI Integration:** 0/10 ⭐ **NEXT PHASE**

## 🎯 TERRAFORM PRIORITY - LIPIEC 2025

### **Foundation Week (IN PROGRESS):**
- [x] **Basic concepts:** Provider, resources, variables, outputs ✅
- [x] **VPC creation:** Single VPC w eu-west-1 ✅
- [ ] **Multi-AZ networking:** 4 subnety + routing (bezkosztowo)
- [ ] **Prod environment:** Druga kopia infrastruktury
- [ ] **State management:** Local vs remote patterns

### **Production Week:**
- [ ] **Modules creation:** Reusable VPC component
- [ ] **EKS preparation:** Kubernetes infrastructure design
- [ ] **Security patterns:** IAM roles, security groups
- [ ] **CI/CD integration:** GitLab + Terraform automation

### **Current Terraform Status:**
```
dev/
├── provider.tf ✅
├── main.tf ✅ (VPC working)
├── variables.tf ✅
├── outputs.tf ✅
└── dev.tfvars ✅
```

**Working VPC:** vpc-017ccd475dc9614cc w eu-west-1, CIDR 10.10.0.0/16

## 🚀 AI-DevOps Lab Project (ON HOLD)

**Nazwa:** `ai-devops-lab` - safe playground dla AI experiments  
**Cel:** 12 AI automations portfolio do końca roku  
**Strategy:** Deploy na gotowej Terraform infrastrukturze

**Delayed until:** Terraform foundation complete

## 🔧 Środowisko Technical
- **OS:** macOS Apple Silicon M1
- **Klaster:** K3s na krolikowski.cloud (production stable)
- **AWS:** Account + credentials configured
- **Terraform:** 1.12.2 installed + working
- **Narzędzia:** kubectl, helm, docker, git (wszystkie skonfigurowane)

## 📊 Plan Kolejności (UPDATED)

### **Immediate (Ten tydzień):**
- [ ] **Multi-AZ subnets:** 4 subnety (2 public, 2 private) w dev
- [ ] **Internet Gateway:** Routing dla public subnets
- [ ] **Prod environment:** Kopia dev z różnymi wartościami
- [ ] **Testing:** Oba środowiska deployed i działają

### **Next Week:**
- [ ] **Terraform modules:** Extract VPC do reusable component
- [ ] **Remote state:** S3 backend setup  
- [ ] **EKS design:** Kubernetes infrastructure preparation
- [ ] **Security basics:** IAM + security groups

### **Following Weeks:**
- [ ] **AI-DevOps Lab:** Deploy na gotowej infrastrukturze
- [ ] **AI Tools:** GitHub Copilot + ChatGPT integration
- [ ] **First AI automation:** Infrastructure monitoring

## 💼 BUSINESS MODEL - Unchanged

### **Target Services:**
- **AWS Migration + AI Optimization:** 20-50k PLN/projekt
- **AI-Enhanced Infrastructure:** 10-25k PLN setup
- **DevOps + AI Consulting:** 250-500 PLN/h
- **Custom AI Automations:** 15-30k PLN/solution

### **Timeline:**
- **Q3 2025:** Terraform + AWS foundations + first AI automations
- **Q4 2025:** Business launch + first clients
- **2027:** Strategic decision - scale firm vs corporate role

## 🎯 CURRENT SESSION GOALS

### **Terraform Focus:**
1. **Multi-AZ networking** - 4 subnety bezkosztowo
2. **Prod environment** - druga kopia infrastruktury  
3. **Best practices** - modules, state management
4. **EKS preparation** - Kubernetes infrastructure design

### **Learning Priorities:**
- **Infrastructure first** - solid foundation
- **Cost optimization** - free tier friendly
- **Production patterns** - scalable, maintainable
- **Documentation** - lessons learned tracking

## 🔄 Instrukcje dla mentora
1. **BajkoBoot = OFF LIMITS** (production system)
2. **Terraform = PRIORITY** (foundation dla wszystkiego)
3. **AI projects = DELAYED** (until infrastructure ready)
4. **Focus na practical skills** - hands-on learning
5. **Pytania prowadzące** - nie gotowe rozwiązania
6. **Polish language** preferred dla dokumentacji

**Current session goal:** Multi-AZ VPC networking + prod environment

---
*Ostatnia aktualizacja: 07.07.2025*  
*Status: Terraform Foundation Phase* 🚀  
*Next milestone: Multi-environment infrastructure ready*