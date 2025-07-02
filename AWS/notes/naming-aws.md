
# 📘 Reguły nazewnictwa zasobów sieciowych i infrastrukturalnych w AWS

Poniżej znajduje się standard nazewnictwa zasobów w chmurze AWS dla projektu `projectname`.

---

## ✳️ Zasady ogólne

- **Prefix projektu**: `projectname` – identyfikator projektu.
- **Komponent**: `security`, `network`, `core` itp.
- **Środowisko**: `dev`, `test`, `prod`, `staging`.
- **Typ zasobu**: `vpc`, `subnet`, `fw`, `igw`, `rt`, `ec2`, `s3`, `sg` itp.
- **Szczegóły**: numer, rola, port, kierunek, reguła (np. `tcp-80`, `allow`).
- **Separatory**: myślniki `-`.

---

## 📦 Przykłady nazw zasobów

| **Usługa**           | **Przykład nazwy**                                           |
|----------------------|--------------------------------------------------------------|
| VPC                  | `projectname-security-prod-vpc-01`                             |
| Podsieć (Subnet)     | `projectname-security-prod-subnet-01`                          |
| Firewall Rule        | `projectname-security-prod-fw-internal-tcp-80-allow-rule`      |
| Route Table          | `projectname-network-prod-rt-public-01`                        |
| Internet Gateway     | `projectname-network-prod-igw-01`                              |
| NAT Gateway          | `projectname-network-prod-natgw-01`                            |
| EC2 Instance         | `projectname-core-prod-ec2-webserver-01`                       |
| Security Group       | `projectname-core-prod-sg-app-tier`                            |
| IAM Role             | `projectname-core-prod-iam-role-ec2-access`                    |
| S3 Bucket            | `projectname-data-prod-s3-logs-bucket`                         |
| RDS Instance         | `projectname-db-prod-rds-postgres-01`                          |
| Load Balancer (ALB)  | `projectname-network-prod-alb-public`                          |
| Lambda Function      | `projectname-func-prod-lambda-user-processor`                  |
| EKS Cluster          | `projectname-k8s-prod-eks-main`                                |

---

## ✅ Praktyczne wskazówki

- **Unikaj** wielkich liter i spacji.
- **Utrzymuj spójność** między środowiskami (`prod`, `test`, `dev`).
- **Używaj nazw opisowych**, ale nie zbyt długich.
- **Sufiks numeryczny** (`-01`) może być używany do skalowania.

---

