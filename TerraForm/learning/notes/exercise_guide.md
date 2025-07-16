# Wieczorne Ćwiczenia DevOps - Kompletny Przewodnik

## 🎯 Cel: Production-Ready Infrastructure Enhancements

### ⏰ Szacowany czas: 90 minut
### 🏆 Poziom: Intermediate
### 📍 Punkt startowy: Działające EC2 instances z poprzednich ćwiczeń

---

## 📚 **DOKUMENTACJA I LINKI**

### 🔗 **Terraform Documentation:**
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [aws_lb (Load Balancer)](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb)
- [aws_lb_target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group)
- [aws_lb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener)
- [aws_cloudwatch_metric_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm)
- [aws_sns_topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic)

### 🔗 **AWS Documentation:**
- [Application Load Balancer Guide](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [CloudWatch User Guide](https://docs.aws.amazon.com/cloudwatch/)
- [EBS Snapshots](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-snapshots.html)
- [VPC Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/security-groups.html)

### 🔗 **Pomocne Tutorials:**
- [Terraform ALB Example](https://developer.hashicorp.com/terraform/tutorials/aws-get-started)
- [AWS CloudWatch Metrics](https://aws.amazon.com/cloudwatch/getting-started/)

---

## 🏗️ **ZADANIE 1: Application Load Balancer (30 min)**

### 📋 Co stworzyć:
```
environments/dev/load-balancer/
├── backend.tf
├── provider.tf  
├── variables.tf
├── main.tf
├── outputs.tf
└── terraform.tfvars
```

### 🎯 **Krok po kroku:**

#### **1.1 Setup podstawowy (5 min)**
```bash
cd ~/local_repo/DevOps-Learning/TerraForm/learning/environments/dev/
mkdir load-balancer
cd load-balancer
```

#### **1.2 Backend configuration**
```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-tk-dev-20250709222448939700000001"
    key            = "dev-load-balancer/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock-dev"
  }
}
```

#### **1.3 Main resources (20 min)**
Potrzebujesz stworzyć:
- `aws_lb` - Application Load Balancer
- `aws_lb_target_group` - Target group dla EC2
- `aws_lb_target_group_attachment` - Podłączenie EC2 do target group
- `aws_lb_listener` - Listener na port 80

#### **1.4 Variables do przemyślenia:**
- VPC ID (data source)
- Subnet IDs (public subnets)
- EC2 Instance IDs (data source)
- Security Group ID

#### **1.5 Test (5 min)**
```bash
terraform init
terraform plan
terraform apply
```

### 💡 **Wskazówki:**
- Użyj data sources żeby znaleźć istniejące zasoby
- Load balancer musi być w public subnets
- Target group healthcheck na port 80
- Security group dla ALB: inbound 80,443 outbound all

---

## 📊 **ZADANIE 2: CloudWatch Monitoring (20 min)**

### 📋 Co stworzyć:
```
environments/dev/monitoring/
├── backend.tf
├── provider.tf
├── variables.tf  
├── main.tf
├── outputs.tf
└── terraform.tfvars
```

### 🎯 **Resources do stworzenia:**

#### **2.1 SNS Topic & Subscription**
```hcl
resource "aws_sns_topic" "alerts" {
  name = "ec2-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "twój-email@example.com"  # ZMIEŃ!
}
```

#### **2.2 CloudWatch Alarms**
Stwórz alarmy dla:
- **CPU Utilization** > 80%
- **StatusCheckFailed** dla każdej instancji
- **NetworkIn** > threshold (opcjonalne)

#### **2.3 CloudWatch Dashboard (bonus)**
```hcl
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "EC2-Monitoring"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", "i-instance-id"]
          ]
          region = "eu-west-1"
          title  = "EC2 CPU Utilization"
        }
      }
    ]
  })
}
```

### 💡 **Wskazówki:**
- Użyj data source żeby znaleźć EC2 instance IDs
- SNS subscription wymaga potwierdzenia email
- Period dla alarmów: 300 seconds (5 min)
- Evaluation periods: 2

---

## 💾 **ZADANIE 3: EBS Backup Strategy (15 min)**

### 📋 Co stworzyć:
```
environments/dev/backup/
├── backend.tf
├── provider.tf
├── variables.tf
├── main.tf  
├── outputs.tf
└── terraform.tfvars
```

### 🎯 **Resources do stworzenia:**

#### **3.1 Backup Vault**
```hcl
resource "aws_backup_vault" "ec2_backup" {
  name        = "ec2-backup-vault"
  kms_key_arn = aws_kms_key.backup.arn
}
```

#### **3.2 Backup Plan**
```hcl
resource "aws_backup_plan" "ec2_backup" {
  name = "ec2-daily-backup"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.ec2_backup.name
    schedule          = "cron(0 2 * * ? *)"  # 2 AM daily

    lifecycle {
      delete_after = 7  # 7 days retention
    }
  }
}
```

#### **3.3 IAM Role & Selection**
Potrzebujesz:
- IAM role dla AWS Backup
- Backup selection (które resources)
- Resource assignment

### 💡 **Wskazówki:**
- KMS key dla encryption
- Tag-based selection: Environment=dev
- Cross-region backup (opcjonalne)

---

## 🔒 **ZADANIE 4: Security Hardening (25 min)**

### 📋 Co poprawić:

#### **4.1 Sprawdź swoje publiczne IP**
```bash
curl -s https://ipinfo.io/ip
```

#### **4.2 Zaktualizuj Security Group**
W module `ec2_firewall` lub jako nowy moduł:
```hcl
# Zamiast 0.0.0.0/0 dla SSH
source_ip_ranges = ["twoje-ip/32"]
```

#### **4.3 Dodaj HTTPS Support (bonus)**
- SSL Certificate (ACM)
- HTTPS listener na ALB
- HTTP → HTTPS redirect

#### **4.4 Network ACLs (opcjonalne)**
Dodatkowa warstwa security na poziomie subnet.

### 💡 **Wskazówki:**
- Zostaw HTTP/HTTPS jako 0.0.0.0/0 (publiczny dostęp)
- SSH tylko z twojego IP
- Rozważ VPN endpoint dla team access

---

## 🧪 **TESTING & VALIDATION**

### ✅ **Checklist po zakończeniu:**

#### **Load Balancer:**
- [ ] ALB ma publiczny DNS name
- [ ] Health checks są healthy
- [ ] Ruch rozdzielany między instancje
- [ ] `curl http://alb-dns-name` działa

#### **Monitoring:**
- [ ] Email confirmation otrzymany
- [ ] Alarmy w "OK" state
- [ ] Dashboard pokazuje metryki
- [ ] Test alarm (CPU spike)

#### **Backup:**
- [ ] Backup plan aktywny
- [ ] Resource selection configured
- [ ] Permissions correct
- [ ] First backup scheduled

#### **Security:**
- [ ] SSH tylko z twojego IP
- [ ] Security groups updated
- [ ] HTTP/HTTPS public access works
- [ ] No public access on unnecessary ports

---

## 🎯 **BONUS CHALLENGES**

### 🚀 **Jeśli skończysz wcześniej:**

#### **Auto Scaling Group**
- Launch template based on current EC2
- Auto scaling policies
- CloudWatch triggers

#### **Route 53 DNS**
- Hosted zone
- Alias record do ALB
- Health checks

#### **WAF (Web Application Firewall)**
- Basic rules
- Rate limiting
- Geographic restrictions

#### **VPC Endpoints**
- S3 endpoint
- ECR endpoint (for future containers)

---

## 🆘 **TROUBLESHOOTING GUIDE**

### ❌ **Common Issues:**

#### **Load Balancer target unhealthy:**
```bash
# Check security groups
# Verify health check path exists
# Check EC2 instance status
```

#### **CloudWatch permissions:**
```bash
# Verify IAM roles
# Check metric namespace
# Confirm instance IDs
```

#### **Backup failures:**
```bash
# Check IAM permissions
# Verify resource tags
# Review backup vault policies
```

#### **Terraform errors:**
```bash
# terraform refresh
# Check AWS credentials
# Verify remote state access
```

---

## 📋 **HOMEWORK SUBMISSION**

### 📤 **Co przygotować na jutro:**

1. **Screenshots:**
   - ALB Console z healthy targets
   - CloudWatch Dashboard
   - Backup plan status
   - Security group rules

2. **Terraform Output:**
   - `terraform output` z każdego modułu
   - Architecture diagram (opcjonalne)

3. **Test Results:**
   - ALB load balancing test
   - Alarm notification email
   - SSH access test (restricted)

4. **Challenges Faced:**
   - Co było najtrudniejsze?
   - Które błędy wyłapałeś?
   - Jak rozwiązywałeś problemy?

---

## 🎉 **SUCCESS METRICS**

Po ukończeniu będziesz miał:
- ✅ **Production-grade load balancing**
- ✅ **Comprehensive monitoring**  
- ✅ **Automated backup strategy**
- ✅ **Security best practices**
- ✅ **Multi-module Terraform architecture**

### 🚀 **Next Level Unlocked:** Production Infrastructure Engineer!

---

**Good luck! 💪 To będzie świetne ćwiczenie consolidating wszystkiego co się nauczyłeś!**

**Questions? Jutro analizujemy wyniki! 🎯**