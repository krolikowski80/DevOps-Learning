# ==============================================================================
# MAIN INFRASTRUCTURE - DEV ENVIRONMENT
# ==============================================================================
# Single file approach dla dev - wszystkie komponenty w jednym miejscu.
# W prod będzie component separation (vpc/, ec2/, database/ folders).

## VPC Module - tworzy podstawową infrastrukturę sieciową
## Używam własnego module zamiast oficjalnego terraform-aws-modules/vpc bo:
## 1. Mam pełną kontrolę nad kodem
## 2. Uczę się jak działa VPC od środka
## 3. Mogę dostosować do konkretnych wymagań
module "vpc" {
  source = "../../modules/vpc"

  # Network configuration
  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  # NAT Gateway configuration - kontrola kosztów vs HA
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  # Tagging strategy
  project_name = "terraform-learning"
}

## EC2 Module - tworzy 3 instances (1 public + 2 private)
module "ec2" {
  source = "../../modules/ec2"

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  environment        = var.environment
  public_key_path    = var.public_key_path
  project_name       = "terraform-learning"
}

# Dokumentacja VPC: https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html
