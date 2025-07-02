# Terraform - Praktyczne Notatki - Tomasz Królik

## 🎯 Terraform Core Concepts

### Podstawowa Architektura
```
main.tf         # Resources definition
variables.tf    # Input variables  
outputs.tf      # Output values
provider.tf     # Provider configuration
terraform.tfvars # Variable values (environment-specific)
```

### Provider vs Resource vs Variable
- **Provider:** "Jak się łączyć?" (AWS, region, credentials)
- **Resource:** "Co tworzyć?" (VPC, EC2, RDS)
- **Variable:** "Jakie wartości?" (CIDR, nazwa, region)

## 🔧 Podstawowe Patterns - PROVEN

### 1. Variable Definition Pattern
```hcl
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  # no default = required value
}

variable "vpc_name" {
  description = "Name tag for VPC"
  type        = string
  default     = "my-vpc"  # optional with default
}
```

### 2. Provider Configuration
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  # profile = var.aws_profile  # optional dla multiple accounts
}
```

### 3. Resource Creation Pattern
```hcl
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  
  # Always tag resources!
  tags = {
    Name        = var.vpc_name
    Environment = var.environment
    Project     = var.project_name
  }
}
```

### 4. Output Pattern
```hcl
output "vpc_id" {
  description = "ID of created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of VPC"  
  value       = aws_vpc.main.cidr_block
}
```

## 🏗️ Environment Separation - WORKING PATTERN

### Directory Structure
```
infrastructure/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── provider.tf
│   │   └── dev.tfvars
│   └── prod/
│       ├── main.tf  
│       ├── variables.tf
│       ├── outputs.tf
│       ├── provider.tf
│       └── prod.tfvars
```

### Environment-Specific Values
```hcl
# dev.tfvars
aws_region = "eu-west-1"
cidr_block = "10.10.0.0/16"
vpc_name   = "dev-vpc"

# prod.tfvars  
aws_region = "eu-central-1"
cidr_block = "10.20.0.0/16"
vpc_name   = "prod-vpc"
```

## 🚨 Common Pitfalls & Solutions - LEARNED HARD WAY

### Problem 1: Provider w złym miejscu
**❌ Błąd:** Provider.tf w parent directory
**✅ Rozwiązanie:** Provider.tf w każdym environment directory

### Problem 2: Hardcoded values
**❌ Błąd:** `Name = "dev-vpc"` w main.tf
**✅ Rozwiązanie:** `Name = var.vpc_name` + wartość w .tfvars

### Problem 3: Missing variable file
**❌ Błąd:** `terraform apply` (używa defaults/fails)
**✅ Rozwiązanie:** `terraform apply -var-file=dev.tfvars`

### Problem 4: Region confusion
**❌ Problem:** State shows different region than expected
**✅ Debug:** `terraform console -var-file=dev.tfvars` → `var.aws_region`

## 🔄 Terraform Workflow - DAILY COMMANDS

### Development Cycle
```bash
# 1. Initialize (first time only)
terraform init

# 2. Validate syntax
terraform validate

# 3. Format code  
terraform fmt

# 4. Plan changes
terraform plan -var-file=dev.tfvars

# 5. Apply changes
terraform apply -var-file=dev.tfvars

# 6. Show current state
terraform show

# 7. Destroy when done
terraform destroy -var-file=dev.tfvars
```

### Debugging Commands
```bash
# Check variable values
terraform console -var-file=dev.tfvars
> var.aws_region
> var.vpc_name

# Refresh state from AWS
terraform refresh -var-file=dev.tfvars

# List all resources
terraform state list

# Show specific resource
terraform state show aws_vpc.main
```

## 🌐 Networking Patterns - UPCOMING

### VPC + Subnets Pattern
```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.environment}-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-${count.index + 1}"
    Type = "Public"
  }
}

# Private Subnet  
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.environment}-private-${count.index + 1}" 
    Type = "Private"
  }
}
```

### Variables for Multi-AZ
```hcl
variable "availability_zones" {
  description = "List of AZs to use"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"  
  type        = list(string)
  default     = ["10.10.2.0/24", "10.10.4.0/24"]
}
```

## 🔍 State Management - IMPORTANT

### Local State (current)
- **Plik:** `terraform.tfstate` w local directory
- **Problem:** Nie można współpracować w zespole
- **Rozwiązanie:** Remote state backend

### Remote State (future)
```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "dev/terraform.tfstate"  
    region = "eu-west-1"
  }
}
```

## 💡 Best Practices - FROM EXPERIENCE

### 1. Always Use Variables
- **NIE:** Hardcoded values w main.tf
- **TAK:** Variables + environment-specific .tfvars

### 2. Consistent Naming
```hcl
# Pattern: {environment}-{service}-{type}
Name = "${var.environment}-${var.service_name}-vpc"
```

### 3. Proper Tagging
```hcl
tags = {
  Name        = var.resource_name
  Environment = var.environment  
  Project     = var.project_name
  ManagedBy   = "terraform"
  Owner       = var.owner
}
```

### 4. Resource Dependencies
```hcl
# Implicit dependency (preferred)
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id  # Terraform knows to create VPC first
}

# Explicit dependency (rare cases)
resource "aws_instance" "app" {
  depends_on = [aws_security_group.app]
}
```

## 🎯 Terraform vs Other Tools

### Terraform vs CloudFormation
- **Terraform:** Multi-cloud, better syntax, active community
- **CloudFormation:** AWS-only, integrated, sometimes faster

### Terraform vs Kubernetes
- **Terraform:** Infrastructure layer (VPC, EC2, RDS)
- **Kubernetes:** Application layer (Pods, Services, Deployments)
- **Integration:** Terraform creates EKS → Kubernetes uses it

### Terraform vs Helm
- **Terraform:** Infrastructure as Code
- **Helm:** Application configuration management
- **Flow:** Terraform → EKS → Helm → Applications

## 📚 Learning Resources & Next Steps

### Immediate Goals (This Week)
- [ ] **Multi-AZ VPC** - dev + prod environments
- [ ] **Subnets + routing** - public/private separation
- [ ] **Module creation** - reusable VPC component
- [ ] **Remote state** - S3 backend setup

### Medium Term (Next Month)
- [ ] **EKS cluster** - Kubernetes infrastructure
- [ ] **Security hardening** - IAM, security groups
- [ ] **CI/CD integration** - GitLab + Terraform
- [ ] **Cost optimization** - resource scheduling

### Advanced Topics (Future)
- [ ] **Dynamic blocks** - conditional resource creation
- [ ] **Data sources** - query existing AWS resources
- [ ] **Terraform Cloud** - collaboration + governance
- [ ] **Custom providers** - extend Terraform functionality

---

## 🔄 Integration z BajkoBoot

### Migration Strategy
1. **Phase 1:** Recreate K3s infrastructure w Terraform
2. **Phase 2:** Migrate to AWS EKS using Terraform
3. **Phase 3:** Use same Helm charts on EKS
4. **Phase 4:** CI/CD automation - GitLab → Terraform → Helm

### Infrastructure Parity
```hcl
# Current: K3s on krolikowski.cloud
# Future: EKS cluster with:
# - Same namespace structure
# - Same Helm charts  
# - Same GitLab CI/CD
# - Better observability + scaling
```

---

**Kluczowa lekcja:** Terraform to jak Helm dla infrastructure - separacja templates od values! 🎯

*Notatki będą rozbudowywane wraz z postępem nauki.*